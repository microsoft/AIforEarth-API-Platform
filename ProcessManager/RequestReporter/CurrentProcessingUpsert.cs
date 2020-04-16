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
    using Newtonsoft.Json;
    using StackExchange.Redis;
    using System;
    using System.IO;
    using System.Threading.Tasks;
    using ProcessManager.Libraries;
    using ProcessManager.Classes;

    public static class CurrentProcessingUpsert
    {
        private const string APP_INSIGHTS_REQUESTS_KEY_NAME = "CURRENT_REQUESTS";
        private const string LOGGING_SERVICE_NAME = "CurrentProcessingUpsert";
        private const string LOGGING_SERVICE_VERSION = "1.0";

        [FunctionName("CurrentProcessingUpsert")]
        public static async Task<IActionResult> Run(
            [HttpTrigger(AuthorizationLevel.Function, "post", Route = null)] HttpRequest req, ILogger logger)
        {
            AppInsightsLogger appInsightsLogger = new AppInsightsLogger(logger, LOGGING_SERVICE_NAME, LOGGING_SERVICE_VERSION);
            var redisOperation = "increment";

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
                            ProcessingUpdate update = null;

                            try
                            {
                                update = JsonConvert.DeserializeObject<ProcessingUpdate>(body);
                            }
                            catch
                            {
                                update = JsonConvert.DeserializeObject<ProcessingUpdate[]>(body)[0];
                            }

                            if (update == null)
                            {
                                appInsightsLogger.LogWarning("Parameters missing. Unable to update processing count.");
                                return new BadRequestResult();
                            }
                            else
                            {
                                return await RedisUpsert(update, appInsightsLogger, redisOperation);
                            }
                        }
                        else
                        {
                            appInsightsLogger.LogWarning("Parameters missing. Unable to update processing count.");
                            return new BadRequestResult();
                        }
                    }
                }
                catch (Exception ex)
                {
                    appInsightsLogger.LogError(ex);
                    appInsightsLogger.LogRedisUpsert("Redis upsert failed.", redisOperation, DateTime.UtcNow.ToString(), body);
                    return new StatusCodeResult(500);
                }
            }
            else
            {
                return new BadRequestResult();
            }

        }

        private static async Task<StatusCodeResult> RedisUpsert(ProcessingUpdate update, AppInsightsLogger appInsightsLogger, string redisOperation)
        {
            IDatabase db = null;

            try
            {
                db = RedisConnection.GetDatabase();
            }
            catch (Exception ex)
            {
                appInsightsLogger.LogError(ex, update.ApiPath);
                appInsightsLogger.LogRedisUpsert("Redis upsert failed.", redisOperation, DateTime.UtcNow.ToString(), update.ApiPath);
                return new StatusCodeResult(500);
            }

            try
            {
                var keyname = APP_INSIGHTS_REQUESTS_KEY_NAME + "/" + update.ServiceCluster + update.ApiPath;
                var newCount = await db.StringIncrementAsync(keyname, update.IncrementBy - update.DecrementBy);
                appInsightsLogger.LogMetric(keyname, newCount, update.ApiPath);
                return new StatusCodeResult(200);
            }
            catch (Exception ex)
            {
                appInsightsLogger.LogError(ex, update.ApiPath);
                appInsightsLogger.LogRedisUpsert("Redis upsert failed.", redisOperation, DateTime.UtcNow.ToString(), update.ApiPath);
                return new StatusCodeResult(500);
            }
        }
    }
}
