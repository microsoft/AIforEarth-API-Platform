/*!
 * Copyright (c) Microsoft Corporation. All rights reserved.
 * Licensed under the MIT License.
 */
 namespace ProcessManager
{
    using Microsoft.AspNetCore.Http;
    using Microsoft.AspNetCore.Mvc;
    using Microsoft.Azure.EventGrid.Models;
    using Microsoft.Azure.WebJobs;
    using Microsoft.Azure.WebJobs.Extensions.Http;
    using Microsoft.Extensions.Logging;
    using Newtonsoft.Json;
    using Newtonsoft.Json.Linq;
    using System;
    using System.IO;
    using System.Net.Http;
    using System.Text;
    using System.Threading;
    using System.Threading.Tasks;
    using ProcessManager.Libraries;
    using ProcessManager.Classes;

    public static class BackendWebhook
    {
        private static string LOGGING_SERVICE_NAME = "BackendWebhook";
        private static string LOGGING_SERVICE_VERSION = "1.0";

        [FunctionName("BackendWebhook")]

        public static async Task<IActionResult> Run([HttpTrigger(AuthorizationLevel.Function, "post", Route = null)]HttpRequest req, ILogger logger)
        {
            AppInsightsLogger appInsightsLogger = new AppInsightsLogger(logger, LOGGING_SERVICE_NAME, LOGGING_SERVICE_VERSION);

            string response = string.Empty;
            const string SubscriptionValidationEvent = "Microsoft.EventGrid.SubscriptionValidationEvent";

            string requestContent = new StreamReader(req.Body).ReadToEnd();
            EventGridEvent[] eventGridEvents = JsonConvert.DeserializeObject<EventGridEvent[]>(requestContent);

            // We should only have 1 event
            foreach (EventGridEvent eventGridEvent in eventGridEvents)
            {
                JObject dataObject = eventGridEvent.Data as JObject;

                // Deserialize the event data into the appropriate type based on event type
                if (string.Equals(eventGridEvent.EventType, SubscriptionValidationEvent, StringComparison.OrdinalIgnoreCase))
                {
                    var eventData = dataObject.ToObject<SubscriptionValidationEventData>();
                    appInsightsLogger.LogInformation($"Got SubscriptionValidation event data, validation code: {eventData.ValidationCode}, topic: {eventGridEvent.Topic}", string.Empty);
                    // Do any additional validation (as required) and then return back the below response
                    var responseData = new SubscriptionValidationResponse();
                    responseData.ValidationResponse = eventData.ValidationCode;
                    return new OkObjectResult(responseData);
                }
                else
                {
                    var backendUri = new Uri(eventGridEvent.Subject);

                    var client = new HttpClient();
                    var stringContent = new StringContent(eventGridEvent.Data.ToString(), Encoding.UTF8, "application/json");

                    try
                    {
                        appInsightsLogger.LogInformation($"Sending request to {backendUri} for taskId {eventGridEvent.Id}.", eventGridEvent.Subject, eventGridEvent.Id);
                        client.DefaultRequestHeaders.Add("taskId", eventGridEvent.Id);
                        var res = await client.PostAsync(backendUri, stringContent);

                        if (res.StatusCode == (System.Net.HttpStatusCode)429) // Special return value indicating that the service is busy.  Let event grid handle the retries.
                        {
                            appInsightsLogger.LogInformation("Backend service is busy. Event grid will retry with backoff.", eventGridEvent.Subject, eventGridEvent.Id);
                        }
                        else if (!res.IsSuccessStatusCode)
                        {
                            appInsightsLogger.LogWarning($"Unable to send request to backend. Status: {res.StatusCode.ToString()}, Reason: {res.ReasonPhrase}", eventGridEvent.Subject, eventGridEvent.Id);
                        }

                        appInsightsLogger.LogInformation("Request has successfully been pushed to the backend.", eventGridEvent.Subject, eventGridEvent.Id);
                        return new StatusCodeResult((int)(res.StatusCode));
                    }
                    catch (Exception ex)
                    {
                        appInsightsLogger.LogError(ex, eventGridEvent.Subject, eventGridEvent.Id);
                        return new StatusCodeResult(500);
                    }
                }
            }
            
            return new OkResult();
        }
    }

    public class RetryHandler : DelegatingHandler
    {
        private const int MaxRetries = 5;

        public RetryHandler(HttpMessageHandler innerHandler)
            : base(innerHandler)
        { }
    }
}
