/*!
 * Copyright (c) Microsoft Corporation. All rights reserved.
 * Licensed under the MIT License.
 */
 namespace ProcessManager.Libraries
{
    using System;
    using StackExchange.Redis;
    using System.Linq;
    using System.Collections.Generic;

    internal class QueueLogger
    {
        private AppInsightsLogger appInsightsLogger;

        public QueueLogger(AppInsightsLogger appInsightsLogger)
        {
            this.appInsightsLogger = appInsightsLogger;
        }

        public void LogQueueLength(string backendStatusSuffix, int adjustment = 0)
        {
            IDatabase db = null;
            IServer ser = null;

            try
            {
                db = RedisConnection.GetDatabase();
                ser = RedisConnection.GetServer();
            }
            catch (Exception ex)
            {
                appInsightsLogger.LogError(ex);
                throw ex;
            }

            Dictionary<string, string> keyNamesAndEndpoints = new Dictionary<string, string>();
            //name, value, endpoint

            ser.Keys(pattern: "*" + backendStatusSuffix).ToList().ForEach((key) => keyNamesAndEndpoints.Add(key, key.ToString().Replace(backendStatusSuffix, string.Empty)));

            foreach (var keypoint in keyNamesAndEndpoints)
            {
                var len = db.SortedSetLength(keypoint.Key) + adjustment;
                appInsightsLogger.LogMetric(keypoint.Key, len, keypoint.Value);
            }
        }
    }
}