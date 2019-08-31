/*!
 * Copyright (c) Microsoft Corporation. All rights reserved.
 * Licensed under the MIT License.
 */
 namespace AsyncCacheConnector
{
    using Newtonsoft.Json;
    using System;

    internal class APITask
    {
        public string TaskId { get; set; }
        public string Timestamp { get; set; }
        public string Status { get; set; }
        public string BackendStatus { get; set; }
        public string Endpoint { get; set; }
        public string Body { get; set; }
        public bool PublishToGrid { get; set; }

        public string EndpointPath
        {   //Example: http://13.92.196.47/v1/paws/process-data
            get
            {
                Uri uri = new Uri(Endpoint);
                return uri.AbsolutePath;
            }
        }

    }
}