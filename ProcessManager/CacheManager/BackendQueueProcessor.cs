/*!
 * Copyright (c) Microsoft Corporation. All rights reserved.
 * Licensed under the MIT License.
 */
 namespace ProcessManager
{
    using Microsoft.AspNetCore.Http;
    using Microsoft.AspNetCore.Mvc;
    using Microsoft.Azure.WebJobs;
    using Microsoft.Azure.WebJobs.Extensions.Http;
    using Microsoft.Extensions.Logging;
    using StackExchange.Redis;
    using System;
    using ProcessManager.Libraries;
    using ProcessManager.Classes;
    using System.Threading.Tasks;
    using Microsoft.Azure.ServiceBus;


    public static class BackendQueueProcessor
    {
        private static string UUID_KEYNAME = "taskId";

        private static string LOGGING_SERVICE_NAME = "BackendQueueProcessor";
        private static string LOGGING_SERVICE_VERSION = "1.0";
        private static string URL = "taskmanagement";

        [FunctionName("BackendQueueProcessor")]
        public static async Task<IActionResult> Run([ServiceBusTrigger("tasksapiqueue", Connection = "SERVICE_BUS_CONNECTION_STRING")] 
            string myQueueItem,
            Int32 deliveryCount,
            DateTime enqueuedTimeUtc,
            string messageId, ILogger logger)
        {
            logger.LogTrace("BackendQueueProcessor was called ");
            return new OkResult();
            // var timestamp = DateTime.UtcNow;
            // log.LogTrace($@"[{message.UserProperties[@"TestRunId"]}]: Message received at {timestamp}: {JObject.FromObject(message)}");

            // AppInsightsLogger appInsightsLogger = new AppInsightsLogger(logger, LOGGING_SERVICE_NAME, LOGGING_SERVICE_VERSION);

            // var enqueuedTime = message.ScheduledEnqueueTimeUtc;
            // var elapsedTimeMs = (timestamp - enqueuedTime).TotalMilliseconds;

            // var taskId = message.UserProperties["TaskId"];
            // var backendUri = message.UserProperties["Uri"];
            // var body = message.UserProperties["Body"];

            // var client = new HttpClient();

            // try
            // {
            //     appInsightsLogger.LogInformation($"Sending request to {backendUri} for taskId {taskId}.", backendUri, taskId);
            //     client.DefaultRequestHeaders.Add("taskId", taskId);

            //     var res = await client.PostAsync(new Uri(backendUri), body);

            //     if (res.StatusCode == (System.Net.HttpStatusCode)429) // Special return value indicating that the service is busy.  Let event grid handle the retries.
            //     {
            //         appInsightsLogger.LogInformation("Backend service is busy. Will try again.", backendUri, taskId);
            //         throw new ApplicationException("Backend service is busy. Will try again.");
            //     }
            //     else if (!res.IsSuccessStatusCode)
            //     {
            //         appInsightsLogger.LogWarning($"Unable to send request to backend. Status: {res.StatusCode.ToString()}, Reason: {res.ReasonPhrase}", backendUri, taskId);
            //     }

            //     appInsightsLogger.LogInformation("Request has successfully been pushed to the backend.", backendUri, taskId);
            // }
            // catch (Exception ex)
            // {
            //     appInsightsLogger.LogError(ex, backendUri, taskId);
            // }
        }
    }
}
