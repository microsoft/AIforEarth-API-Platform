namespace CacheManagement
{
    using System;

    internal class ProcessingUpdate
    {
        public string ApiPath { get; set; }
        public string ServiceCluster { get; set; }
        public long IncrementBy { get; set; }
        public long DecrementBy { get; set; }
    }
}