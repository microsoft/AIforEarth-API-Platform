/*!
 * Copyright (c) Microsoft Corporation. All rights reserved.
 * Licensed under the MIT License.
 */
 namespace CacheManagement
{
    using AsyncCacheConnector;
    using Microsoft.AspNetCore.Http;
    using Microsoft.AspNetCore.Mvc;
    using Microsoft.Azure.WebJobs;
    using Microsoft.Azure.WebJobs.Extensions.Http;
    using Microsoft.Extensions.Logging;
    using StackExchange.Redis;
    using System;
    using System.Threading.Tasks;

    public static class CurrentProcessingGet
    {
        private const string APP_INSIGHTS_REQUESTS_KEY_NAME = "CURRENT_REQUESTS";
        private const string LOGGING_SERVICE_NAME = "CurrentProcessingGet";
        private const string LOGGING_SERVICE_VERSION = "1.0";

        private const string SERVICE_CLUSTER_KEY_NAME = "cluster";
        private const string API_PATH_KEY_NAME = "path";

        [FunctionName("CurrentProcessingGet")]
        public static async Task<IActionResult> Run(
            [HttpTrigger(AuthorizationLevel.Function, "post", Route = null)] HttpRequest req, ILogger logger)
        {
            IDatabase db = null;
            AppInsightsLogger appInsightsLogger = new AppInsightsLogger(logger, LOGGING_SERVICE_NAME, LOGGING_SERVICE_VERSION);

            string cluster = string.Empty;
            string path = string.Empty;
            var apiParams = req.GetQueryParameterDictionary();
            if (apiParams != null && apiParams.Keys.Contains(SERVICE_CLUSTER_KEY_NAME) && apiParams.Keys.Contains(API_PATH_KEY_NAME))
            {
                cluster = apiParams[SERVICE_CLUSTER_KEY_NAME];
                path = apiParams[API_PATH_KEY_NAME];
            }
            else
            {
                return new BadRequestObjectResult("The cluster and path parameters are requried.");
            }

            try
            {
                db = RedisConnection.GetDatabase();
            }
            catch (Exception ex)
            {
                appInsightsLogger.LogError(ex, cluster + "/" + path);
                return new StatusCodeResult(500);
            }

            RedisValue storedCount = RedisValue.Null;
            try
            {
                storedCount = await db.StringGetAsync(APP_INSIGHTS_REQUESTS_KEY_NAME + cluster + "/" + path);

                if (storedCount.HasValue)
                {
                    appInsightsLogger.LogInformation("Found status in cache", cluster + "/" + path);
                    return new OkObjectResult(storedCount.ToString());
                }
                else
                {
                    appInsightsLogger.LogInformation("Found status in cache", cluster + "/" + path);
                    return new StatusCodeResult(204);
                }
            }
            catch (Exception ex)
            {
                appInsightsLogger.LogError(ex, cluster + "/" + path);
                return new StatusCodeResult(500);
            }
        }
    }
}
