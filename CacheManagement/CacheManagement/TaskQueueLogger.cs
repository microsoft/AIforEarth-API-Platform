/*!
 * Copyright (c) Microsoft Corporation. All rights reserved.
 * Licensed under the MIT License.
 */
 namespace AsyncCacheConnector
{
    using Microsoft.Azure.WebJobs;
    using Microsoft.Extensions.Logging;

    public static class TaskQueueLogger
    {
        private static string LOGGING_SERVICE_NAME = "TaskQueueLogger";
        private static string LOGGING_SERVICE_VERSION = "1.0";

        private const string BACKEND_STATUS_CREATED_PATTERN = "_created";

        [FunctionName("TaskQueueLogger")]
        public static void Run([TimerTrigger("*/30 * * * * *")]TimerInfo myTimer, ILogger logger)
        {
            // CRON expression syntax: <second> <minute> <hour> <day-of-month> <month> <day-of-week> <year> <command>
            
            AppInsightsLogger appInsightsLogger = new AppInsightsLogger(logger, LOGGING_SERVICE_NAME, LOGGING_SERVICE_VERSION);
            QueueLogger queueLogger = new QueueLogger(appInsightsLogger);
            queueLogger.LogQueueLength(BACKEND_STATUS_CREATED_PATTERN, adjustment: 1);  // Add 1 so that we account for > 1 waiting.
        }
    }
}
