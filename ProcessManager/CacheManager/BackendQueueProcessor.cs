using System;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Host;
using Microsoft.Extensions.Logging;

namespace ProcessManager
{
    public static class BackendQueueProcessor
    {
        [FunctionName("BackendQueueProcessor")]
        public static void Run([ServiceBusTrigger("tasksapiqueue", Connection = "SERVICE_BUS_CONNECTION_STRING")]string myQueueItem, ILogger log)
        {
            log.LogInformation($"C# ServiceBus queue trigger function processed message: {myQueueItem}");
        }
    }
}
