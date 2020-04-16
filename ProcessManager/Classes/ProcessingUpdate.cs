/*!
 * Copyright (c) Microsoft Corporation. All rights reserved.
 * Licensed under the MIT License.
 */
 namespace ProcessManager.Classes
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