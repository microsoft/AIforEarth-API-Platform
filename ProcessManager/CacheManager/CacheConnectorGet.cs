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

    public static class CacheConnectorGet
    {
        private static string UUID_KEYNAME = "taskId";

        private static string LOGGING_SERVICE_NAME = "CacheConnectorGet";
        private static string LOGGING_SERVICE_VERSION = "1.0";
        private static string URL = "taskmanagement";

        [FunctionName("CacheConnectorGet")]
        public static async Task<IActionResult> Run([HttpTrigger(AuthorizationLevel.Function, "get", Route = null)]HttpRequest req, ILogger logger)
        {
            IDatabase db = null;
            AppInsightsLogger appInsightsLogger = new AppInsightsLogger(logger, LOGGING_SERVICE_NAME, LOGGING_SERVICE_VERSION);

            string uuid = "nil";
            var apiParams = req.GetQueryParameterDictionary();
            if (apiParams != null && apiParams.Keys.Contains(UUID_KEYNAME))
            {
                uuid = apiParams[UUID_KEYNAME];
            }
            else
            {
                appInsightsLogger.LogWarning("Called without a taskId", URL);
            }

            try
            {
                db = RedisConnection.GetDatabase();
            }
            catch (Exception ex)
            {
                appInsightsLogger.LogError(ex, URL, uuid);
                return new StatusCodeResult(500);
            }

            RedisValue storedStatus = RedisValue.Null;
            try
            {
                storedStatus = await db.StringGetAsync(uuid);

                if (storedStatus.HasValue)
                {
                    return new OkObjectResult(storedStatus.ToString());
                }
                else
                {
                    appInsightsLogger.LogWarning("Cannot find status in cache", URL, uuid);
                    return new StatusCodeResult(204);
                }
            }
            catch (Exception ex)
            {
                appInsightsLogger.LogError(ex, URL, uuid);
                return new StatusCodeResult(500);
            }
        }
    }
}
