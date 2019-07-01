namespace AsyncCacheConnector
{
    using Microsoft.Extensions.Logging;
    using System;
    using System.Collections.Generic;
    using Microsoft.ApplicationInsights;
    using Microsoft.ApplicationInsights.DataContracts;

    internal class AppInsightsLogger
    {
        private static string service_owner = "AI4E";
        private static string service_cluster = "AzureFunctions";

        private string service_name = string.Empty;
        private string service_version = string.Empty;

        private ILogger logger = null;
        private static TelemetryClient telemetryClient = new TelemetryClient();

        public AppInsightsLogger(ILogger logger, string serviceName, string serviceVersion)
        {
            this.logger = logger;
            service_name = serviceName;
            service_version = serviceVersion;
        }

        public void LogMetric(string name, double value, string endpoint)
        {
            var metric = new MetricTelemetry(name, value);
            metric.Context.Operation.Name = endpoint;
            telemetryClient.TrackMetric(metric);
        }

        public void LogInformation(string message, string uri = "nil", string task_id = "nil")
        {
            try
            {
                logger.LogInformation(message + ", service_owner={service_owner}, " +
                    "service_name={service_name}, " +
                    "service_version={service_version}, " +
                    "service_cluster={service_cluster}, " +
                    "uri={uri}, " +
                    "task_id={task_id}", 
                    service_owner, 
                    service_name, 
                    service_version, 
                    service_cluster, 
                    uri, 
                    task_id);

            }
            catch(Exception ex)
            {
                logger.LogError(ex.Message + ex.StackTrace.ToString());
            }
        }

        public void LogRedisUpsert(string message, string upsert_type, string timestamp, string record, string uri = "nil", string task_id = "nil")
        {
            try
            {
                logger.LogInformation(message + ", service_owner={service_owner}, " +
                    "service_name={service_name}, " +
                    "service_version={service_version}, " +
                    "service_cluster={service_cluster}, " +
                    "uri={uri}, " +
                    "task_id={task_id}, " +
                    "upsert_type={upsert_type}, " +
                    "timestamp={timestamp}, " +
                    "record={record}",
                    service_owner,
                    service_name,
                    service_version,
                    service_cluster,
                    uri,
                    task_id,
                    upsert_type,
                    timestamp,
                    record);

            }
            catch (Exception ex)
            {
                logger.LogError(ex.Message + ex.StackTrace.ToString());
            }
        }

        public void LogWarning(string message, string uri = "nil", string task_id = "nil")
        {
            try
            {
                logger.LogWarning(message + ", service_owner={service_owner}, service_name={service_name}, service_version={service_version}, service_cluster={service_cluster}, uri={uri}, task_id={task_id}", service_owner, service_name, service_version, service_cluster, uri, task_id);
            }
            catch (Exception ex)
            {
                logger.LogError(ex.Message + ex.StackTrace.ToString());
            }
        }

        public void LogError(string message, string uri = "nil", string task_id = "nil")
        {
            try
            {
                logger.LogError(message + ", service_owner={service_owner}, service_name={service_name}, service_version={service_version}, service_cluster={service_cluster}, uri={uri}, task_id={task_id}", service_owner, service_name, service_version, service_cluster, uri, task_id);
            }
            catch (Exception ex)
            {
                logger.LogError(ex.Message + ex.StackTrace.ToString());
            }

        }
    }
}
