/*!
 * Copyright (c) Microsoft Corporation. All rights reserved.
 * Licensed under the MIT License.
 */
 namespace ProcessManager.Libraries
{
    using Microsoft.Extensions.Logging;
    using System;
    using System.Collections.Generic;
    using Microsoft.ApplicationInsights;
    using Microsoft.ApplicationInsights.DataContracts;
    using Microsoft.ApplicationInsights.Extensibility;

    internal class AppInsightsLogger
    {
        private static string service_owner = "AI4E";
        private static string service_cluster = "AzureFunctions";

        private string service_name = string.Empty;
        private string service_version = string.Empty;

        private ILogger logger = null;

        private readonly TelemetryClient telemetryClient;

        public AppInsightsLogger(ILogger logger, string serviceName, string serviceVersion)
        {
            this.logger = logger;
            service_name = serviceName;
            service_version = serviceVersion;

            var config = new TelemetryConfiguration { InstrumentationKey = System.Environment.GetEnvironmentVariable("APPINSIGHTS_INSTRUMENTATIONKEY", EnvironmentVariableTarget.Process) };
            this.telemetryClient = new TelemetryClient(config);
        }

        public void LogMetric(string name, double value, string endpoint)
        {
            var metric = new MetricTelemetry(name, value);
            metric.Context.Operation.Name = endpoint;
            telemetryClient.TrackMetric(metric);
        }

        public void LogInformation(string message, string uri = "nil", string task_id = "nil")
        {
            logger.LogInformation("msg: " + message.ToString());
            logger.LogInformation("url: " + uri.ToString());
            logger.LogInformation("task_id: " + task_id.ToString());
            logger.LogInformation("service_owner: " + service_owner.ToString());
            logger.LogInformation("service_name: " + service_name.ToString());
            logger.LogInformation("service_version: " + service_version.ToString());
            logger.LogInformation("service_cluster: " + service_cluster.ToString());

            var formatted_msg = String.Format("{0}, service_owner={1}, service_name={2}, service_version={3}, service_cluster={4}, uri={5}, task_id={6}", 
                message, service_owner, service_name, service_version, service_cluster, uri, task_id);

            try
            {
                logger.LogInformation(formatted_msg);

            }
            catch(Exception ex)
            {
                logger.LogCritical(ex, message);
            }
        }

        public void LogRedisUpsert(string message, string upsert_type, string timestamp, string record, string uri = "nil", string task_id = "nil")
        {
            var formatted_msg = String.Format("{0}, service_owner={1}, service_name={2}, service_version={3}, service_cluster={4}, uri={5}, task_id={6}, upsert_type={7}, timestamp={8}, record={9}",
                message, service_owner, service_name, service_version, service_cluster, uri, task_id, upsert_type, timestamp, record);

            try
            {
                logger.LogInformation(formatted_msg);

            }
            catch(Exception ex)
            {
                logger.LogCritical(ex, message);
            }
        }

        public void LogWarning(string message, string uri = "nil", string task_id = "nil")
        {
            var formatted_msg = message +
                "," +
                $"service_owner={service_owner}, service_name={service_name}, service_version={service_version}, service_cluster={service_cluster}, uri={uri}, task_id={task_id}";

            try
            {
                logger.LogWarning(formatted_msg, service_owner, service_name, service_version, service_cluster, uri, task_id);
            }
            catch (Exception ex)
            {
                logger.LogCritical(ex, message);
            }
        }

        public void LogError(Exception ex, string uri = "nil", string task_id = "nil", string message = "")
        {
            var formatted_msg = message +
                "," +
                $" service_owner={service_owner}, service_name={service_name}, service_version={service_version}, service_cluster={service_cluster}, uri={uri}, task_id={task_id}";

            try
            {
                logger.LogCritical(ex, formatted_msg,
                    service_owner, service_name, service_version, service_cluster, uri, task_id);
            }
            catch (Exception e)
            {
                logger.LogCritical(e, message);
            }

        }
    }
}
