using System;
using System.Collections.Generic;
using System.Text;
using System.Threading.Tasks;
using Microsoft.Azure.ServiceBus;
using Microsoft.Azure.ServiceBus.Core;
using Microsoft.Azure.WebJobs;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json.Linq;
using Newtonsoft.Json;
using System.Net.Http;
using ProcessManager.Libraries;
using ProcessManager.Classes;
using StackExchange.Redis;

namespace BackendQueueProcessor
{
    public static class BackendQueueProcessor
    {
        private const string BACKEND_STATUS_FAILED = "failed";
        private static string URL = "backendqueueprocessor";
        private static string LOGGING_SERVICE_NAME = "BackendQueueProcessor";
        private static string LOGGING_SERVICE_VERSION = "1.0";
        private static string QUEUE_RETRY_DELAY_MS_VARIABLE_NAME = "QUEUE_RETRY_DELAY_MS";


        [FunctionName("BackendQueueProcessor")]
        public static async Task ServiceBusQueueProcessorAsync(
            [ServiceBusTrigger("%SERVICE_BUS_QUEUE%")] Message message, MessageReceiver messageReceiver, ILogger logger)
        {
            var timestamp = DateTime.UtcNow;
            var queueName = Environment.GetEnvironmentVariable("SERVICE_BUS_QUEUE", EnvironmentVariableTarget.Process);
            logger.LogTrace($@"[{message.UserProperties[@"TaskId"]}]: Message received at {timestamp}: {JObject.FromObject(message)}");

            AppInsightsLogger appInsightsLogger = new AppInsightsLogger(logger, LOGGING_SERVICE_NAME + ": " + queueName, LOGGING_SERVICE_VERSION);

            var enqueuedTime = message.ScheduledEnqueueTimeUtc;
            var elapsedTimeMs = (timestamp - enqueuedTime).TotalMilliseconds;

            var taskId = message.UserProperties["TaskId"].ToString();
            var backendUri = message.UserProperties["Uri"].ToString();
            var messageBody = Encoding.UTF8.GetString(message.Body);

            try
            {
                appInsightsLogger.LogInformation($"Sending request to {backendUri} for taskId {taskId} from queue {queueName}. Queued for {elapsedTimeMs/60} seconds.", backendUri, taskId);

                var client = new HttpClient();
                client.DefaultRequestHeaders.Add("taskId", taskId);
                
                var httpContent = new StringContent(messageBody, Encoding.UTF8, "application/json");
                var res = await client.PostAsync(backendUri, httpContent);

                if (res.StatusCode == (System.Net.HttpStatusCode)429) // Special return value indicating that the service is busy.
                {
                    var retryDelay = int.Parse(Environment.GetEnvironmentVariable(QUEUE_RETRY_DELAY_MS_VARIABLE_NAME, EnvironmentVariableTarget.Process));
                    appInsightsLogger.LogInformation($"Service is busy. Will try again in {retryDelay/1000} seconds.", backendUri, taskId);
                    await UpdateTaskStatus(taskId, backendUri, messageBody, $"Awaiting service availability. Queued for {elapsedTimeMs/60} seconds.", "created", appInsightsLogger);

                    // Artifical delay is needed since the ServiceBusTrigger will retry immediately.
                    await Task.Delay(retryDelay);
                    await messageReceiver.AbandonAsync(message.SystemProperties.LockToken);
                    throw new ApplicationException($"Service is busy. Will try again in {retryDelay/1000} seconds.");
                }
                else if (!res.IsSuccessStatusCode)
                {
                    await messageReceiver.CompleteAsync(message.SystemProperties.LockToken);    //Need to complete even though we have failure. This removes it from the queue to avoid an infinite state.
                    appInsightsLogger.LogWarning($"Unable to send request to backend. Status: {res.StatusCode.ToString()}, Reason: {res.ReasonPhrase}", backendUri, taskId);
                    await UpdateTaskStatus(taskId, backendUri, messageBody, $"Unable to send request to backend.", "failed", appInsightsLogger);
                }
                else
                {
                    await messageReceiver.CompleteAsync(message.SystemProperties.LockToken);
                    appInsightsLogger.LogInformation($"taskId {taskId} has successfully been pushed to the backend from queue {queueName}. Queue time: {elapsedTimeMs/60} seconds.", backendUri, taskId);
                }
            }
            catch (Exception ex)
            {
                appInsightsLogger.LogError(ex, backendUri, taskId);
            }
        }

        private static async Task UpdateTaskStatus(string taskId, string backendUri, string taskBody, string statusDetail, string backendStatus, AppInsightsLogger appInsightsLogger)
        {
            IDatabase db = null;
            try
            {
                db = RedisConnection.GetDatabase();
            }
            catch (Exception ex)
            {
                appInsightsLogger.LogError(ex, URL, taskId);
            }

            RedisValue storedStatus = RedisValue.Null;
            try
            {
                storedStatus = await db.StringGetAsync(taskId);
            }
            catch (Exception ex)
            {
                appInsightsLogger.LogError(ex, URL, taskId);
            }

            APITask task = null;
            if (storedStatus.HasValue)
            {
                task = JsonConvert.DeserializeObject<APITask>(storedStatus.ToString());
                task.Status = statusDetail;
                task.Timestamp = DateTime.UtcNow.ToString();
            }
            else
            {
                appInsightsLogger.LogWarning("Cannot find status in cache", URL, taskId);

                task = new APITask()
                {
                    TaskId = Guid.NewGuid().ToString(),
                    Status = statusDetail,
                    BackendStatus = backendStatus,
                    Body = taskBody,
                    Timestamp = DateTime.UtcNow.ToString(),
                    Endpoint = task.Endpoint,
                    PublishToGrid = true
                };
            }

            if (await db.StringSetAsync(task.TaskId, JsonConvert.SerializeObject(task)) == false)
            {
                var ex = new Exception("Unable to complete redis transaction.");
                appInsightsLogger.LogError(ex, task.Endpoint, task.TaskId);
            }
        }
    }
}
