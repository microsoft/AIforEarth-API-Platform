namespace CacheManagement
{
    using AsyncCacheConnector;
    using Microsoft.AspNetCore.Http;
    using Microsoft.AspNetCore.Mvc;
    using Microsoft.Azure.EventGrid;
    using Microsoft.Azure.EventGrid.Models;
    using Microsoft.Azure.WebJobs;
    using Microsoft.Azure.WebJobs.Extensions.Http;
    using Microsoft.Extensions.Logging;
    using Newtonsoft.Json;
    using StackExchange.Redis;
    using System;
    using System.Collections.Generic;
    using System.IO;
    using System.Threading.Tasks;

    public static class CacheConnectorUpsert
    {
        private const string LOGGING_SERVICE_NAME = "CacheConnectorUpsert";
        private const string LOGGING_SERVICE_VERSION = "1.0";

        private const string EVENT_GRID_TOPIC_URI_VARIABLE_NAME = "EVENT_GRID_TOPIC_URI";
        private const string EVENT_GRID_KEY_VARIABLE_NAME = "EVENT_GRID_KEY";

        private const string BACKEND_STATUS_CREATED = "created";
        private const string BACKEND_STATUS_COMPLETED = "completed";
        private const string BACKEND_STATUS_RUNNING = "running";
        private const string BACKEND_STATUS_FAILED = "failed";

        private const string GRID_PUBLISH_RECORD_KEY = "ORIG";

        [FunctionName("cache-connector-upsert")]
        public static IActionResult Run([HttpTrigger(AuthorizationLevel.Function, "post", Route = null)]HttpRequest req, ILogger logger)
        {
            IDatabase db = null;
            AppInsightsLogger appInsightsLogger = new AppInsightsLogger(logger, LOGGING_SERVICE_NAME, LOGGING_SERVICE_VERSION);
            var redisOperation = "insert";

            APITask task = null;

            if (req.Body != null)
            {
                string body = string.Empty;
                try
                {
                    using (StreamReader reader = new StreamReader(req.Body))
                    {
                        if (reader.BaseStream.Length > 0)
                        {
                            body = reader.ReadToEnd();
                            logger.LogInformation("body: " + body);

                            try
                            {
                                appInsightsLogger.LogInformation("DeserializeObject<APITask>(body)");
                                task = JsonConvert.DeserializeObject<APITask>(body);
                            }
                            catch
                            {
                                appInsightsLogger.LogInformation("DeserializeObject<APITask>(body[])");
                                task = JsonConvert.DeserializeObject<APITask[]>(body)[0];
                            }

                            appInsightsLogger.LogInformation("task.PublishToGrid: " + task.PublishToGrid.ToString(), task.Endpoint, task.TaskId);
                        }
                        else
                        {
                            appInsightsLogger.LogWarning("Parameters missing. Unable to create task.");
                            return new BadRequestResult();
                        }
                    }
                }
                catch (Exception ex)
                {
                    appInsightsLogger.LogError(ex);
                    appInsightsLogger.LogRedisUpsert("Redis upsert failed.", redisOperation, task.Timestamp, body);
                    return new StatusCodeResult(500);
                }
            }
            else
            {
                appInsightsLogger.LogWarning("Parameters missing. Unable to create task.");
                return new BadRequestResult();
            }

            if (!String.IsNullOrWhiteSpace(task.TaskId))
            {
                appInsightsLogger.LogInformation("Updating status", task.Endpoint, task.TaskId);
                redisOperation = "update";
            }
            else
            {
                task.TaskId = Guid.NewGuid().ToString();
                appInsightsLogger.LogInformation("Generated new taskId: " + task.TaskId, task.Endpoint, task.TaskId);
            }

            task.Timestamp = DateTime.UtcNow.ToString();

            try
            {
                db = RedisConnection.GetDatabase();
            }
            catch (Exception ex)
            {
                appInsightsLogger.LogError(ex, task.Endpoint, task.TaskId);
                appInsightsLogger.LogRedisUpsert("Redis upsert failed.", redisOperation, task.Timestamp, task.Endpoint, task.TaskId);
                return new StatusCodeResult(500);
            }

            string serializedTask = string.Empty; 
            try
            {
                var taskBody = task.Body;
                task.Body = null;

                serializedTask = JsonConvert.SerializeObject(task);
                RedisValue res = RedisValue.Null;

                appInsightsLogger.LogInformation("Setting Redis task record", task.Endpoint, task.TaskId);
                var upsertTransaction = db.CreateTransaction();
                upsertTransaction.StringSetAsync(task.TaskId, serializedTask);

                // Get seconds since epoch
                TimeSpan ts = (DateTime.UtcNow - new DateTime(1970, 1, 1));
                int timestamp = (int)ts.TotalSeconds;

                appInsightsLogger.LogInformation(string.Format("Adding backend status '{0}' for endpoint.", task.BackendStatus), task.Endpoint, task.TaskId);
                upsertTransaction.SortedSetAddAsync(string.Format("{0}_{1}", task.EndpointPath, task.BackendStatus), new SortedSetEntry[] { new SortedSetEntry(task.TaskId, timestamp) });
                
                if (task.BackendStatus.Equals(BACKEND_STATUS_RUNNING))
                {
                    upsertTransaction.SortedSetRemoveAsync(string.Format("{0}_{1}", task.EndpointPath, BACKEND_STATUS_CREATED), task.TaskId);
                }
                else if (task.BackendStatus.Equals(BACKEND_STATUS_COMPLETED) || task.BackendStatus.Equals(BACKEND_STATUS_FAILED))
                {
                    upsertTransaction.SortedSetRemoveAsync(string.Format("{0}_{1}", task.EndpointPath, BACKEND_STATUS_RUNNING), task.TaskId);
                }

                bool isSubsequentPipelineCall = false;

                bool isPublish = false;
                bool.TryParse(task.PublishToGrid.ToString(), out isPublish);

                if (isPublish == true || task.PublishToGrid == true)
                {
                    if (string.IsNullOrEmpty(taskBody))
                    {
                        appInsightsLogger.LogInformation("It IS a pipeline call", task.Endpoint, task.TaskId);
                        // This is a subsequent pipeline publish.
                        isSubsequentPipelineCall = true;
                    }
                    else
                    {
                        appInsightsLogger.LogInformation("Adding body to redis: " + taskBody, task.Endpoint, task.TaskId);
                        upsertTransaction.StringSetAsync(string.Format("{0}_{1}", task.TaskId, GRID_PUBLISH_RECORD_KEY), taskBody);
                    }
                }

                ExecuteTransaction(upsertTransaction, task, appInsightsLogger);

                if (isSubsequentPipelineCall)
                {
                    // We have to get the original body, since it's currently empty.
                    taskBody = db.StringGet(string.Format("{0}_{1}", task.TaskId, GRID_PUBLISH_RECORD_KEY));
                    appInsightsLogger.LogInformation("Stored body: " + taskBody, task.Endpoint, task.TaskId);
                }

                if (task.PublishToGrid)
                {
                    if (PublishEvent(task, taskBody, appInsightsLogger) == false)
                    {
                        // Move task to failed
                        var updateTransaction = db.CreateTransaction();
                        task.Status = "Failed - unable to send to backend service.";
                        task.BackendStatus = BACKEND_STATUS_FAILED;
                        string updateBody = JsonConvert.SerializeObject(task);

                        updateTransaction.StringSetAsync(task.TaskId, updateBody);
                        updateTransaction.SortedSetAddAsync(string.Format("{0}_{1}", task.EndpointPath, task.BackendStatus), new SortedSetEntry[] { new SortedSetEntry(task.TaskId, timestamp) });
                        updateTransaction.SortedSetRemoveAsync(string.Format("{0}_{1}", task.EndpointPath, BACKEND_STATUS_CREATED), task.TaskId);

                        ExecuteTransaction(updateTransaction, task, appInsightsLogger);
                    }
                }

                //LogSetCount(string.Format("{0}_{1}", task.EndpointPath, task.BackendStatus), task, db, appInsightsLogger);
                appInsightsLogger.LogRedisUpsert("Redis upsert successful.", redisOperation, task.Timestamp, serializedTask, task.Endpoint, task.TaskId);
            }
            catch (Exception ex)
            {
                appInsightsLogger.LogError(ex, task.Endpoint, task.TaskId);
                appInsightsLogger.LogRedisUpsert("Redis upsert failed.", redisOperation, task.Timestamp, serializedTask, task.Endpoint, task.TaskId);
                return new StatusCodeResult(500);
            }
            
            return new OkObjectResult(serializedTask);
        }

        private static bool PublishEvent(APITask task, string taskBody, AppInsightsLogger appInsightsLogger)
        {
            string event_grid_topic_uri = Environment.GetEnvironmentVariable(EVENT_GRID_TOPIC_URI_VARIABLE_NAME, EnvironmentVariableTarget.Process);
            string event_grid_key = Environment.GetEnvironmentVariable(EVENT_GRID_KEY_VARIABLE_NAME, EnvironmentVariableTarget.Process);

            var ev = new EventGridEvent()
            {
                Id = task.TaskId,
                EventType = "task",
                Data = taskBody,
                EventTime = DateTime.Parse(task.Timestamp),
                Subject = task.Endpoint,
                DataVersion = "1.0"
            };

            string topicHostname = new Uri(event_grid_topic_uri).Host;
            TopicCredentials topicCredentials = new TopicCredentials(event_grid_key);
            EventGridClient client = new EventGridClient(topicCredentials);

            try
            {
                client.PublishEventsAsync(topicHostname, new List<EventGridEvent>() { ev }).GetAwaiter().GetResult();
            }
            catch (Exception ex)
            {
                appInsightsLogger.LogError(ex, task.Endpoint, task.TaskId);
                return false;
            }

            return true;
        }

        private static void ExecuteTransaction(ITransaction transaction, APITask task, AppInsightsLogger appInsightsLogger)
        {
            int attempt = 1;
            TimeSpan delaySeconds = TimeSpan.FromSeconds(0);
            var tran = transaction.ExecuteAsync();

            while (transaction.Wait(tran) == false)
            {
                Task.Delay(delaySeconds).GetAwaiter().GetResult();

                if (attempt >= 5)
                {
                    var ex = new Exception("Unable to complete redis transaction.");
                    appInsightsLogger.LogError(ex, task.Endpoint, task.TaskId);
                    throw ex;
                }

                delaySeconds.Add(TimeSpan.FromSeconds(2));
                attempt++;
            }
        }

        private static void LogSetCount(string setName, APITask task, IDatabase db, AppInsightsLogger appInsightsLogger)
        {
            var len = db.SortedSetLength(setName);
            appInsightsLogger.LogMetric(setName, len, task.EndpointPath);
        }
    }
}