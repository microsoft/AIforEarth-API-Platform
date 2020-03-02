/*!
 * Copyright (c) Microsoft Corporation. All rights reserved.
 * Licensed under the MIT License.
 */
 namespace ProcessManager
{
    using Microsoft.Azure.WebJobs;
    using Microsoft.Extensions.Logging;
    using ProcessManager.Libraries;
    using ProcessManager.Classes;

    public static class TaskProcessLogger
    {
        private static string LOGGING_SERVICE_NAME = "TaskProcessLogger";
        private static string LOGGING_SERVICE_VERSION = "1.0";
        
        private const string BACKEND_STATUS_COMPLETED_PATTERN = "_completed";
        private const string BACKEND_STATUS_RUNNING_PATTERN = "_running";
        private const string BACKEND_STATUS_FAILED_PATTERN = "_failed";

        [FunctionName("TaskProcessLogger")]
        public static void Run([TimerTrigger("0 */5 * * * *")]TimerInfo myTimer, ILogger logger)
        {
            // CRON expression syntax: <second> <minute> <hour> <day-of-month> <month> <day-of-week> <year> <command>
            
            AppInsightsLogger appInsightsLogger = new AppInsightsLogger(logger, LOGGING_SERVICE_NAME, LOGGING_SERVICE_VERSION);
            QueueLogger queueLogger = new QueueLogger(appInsightsLogger);
            queueLogger.LogQueueLength(BACKEND_STATUS_COMPLETED_PATTERN);
            queueLogger.LogQueueLength(BACKEND_STATUS_RUNNING_PATTERN);
            queueLogger.LogQueueLength(BACKEND_STATUS_FAILED_PATTERN);
        }
    }
}
