/*!
 * Copyright (c) Microsoft Corporation. All rights reserved.
 * Licensed under the MIT License.
 */
 namespace ProcessManager.Libraries
{
    using StackExchange.Redis;
    using System;

    internal static class RedisConnection
    {
        readonly static Lazy<ConnectionMultiplexer> lazyConnection = new Lazy<ConnectionMultiplexer>(() =>
        {
            var ops = ConfigurationOptions.Parse(REDIS_CONNECTION_STRING);
            ops.SyncTimeout = REDIS_SYNC_TIMEOUT;
            ops.ConnectTimeout = REDIS_GENERAL_TIMEOUT;
            ops.ConnectRetry = 10;
            ops.ReconnectRetryPolicy = new ExponentialRetry(5000);

            return ConnectionMultiplexer.Connect(ops);
        });

        public static string REDIS_CONNECTION_STRING => Environment.GetEnvironmentVariable("REDIS_CONNECTION_STRING", EnvironmentVariableTarget.Process).ToString();
        public static int REDIS_SYNC_TIMEOUT => int.Parse(Environment.GetEnvironmentVariable("REDIS_SYNC_TIMEOUT", EnvironmentVariableTarget.Process));
        public static int REDIS_GENERAL_TIMEOUT => int.Parse(Environment.GetEnvironmentVariable("REDIS_GENERAL_TIMEOUT", EnvironmentVariableTarget.Process));
        public static ConnectionMultiplexer Connection => lazyConnection.Value;

        public static IDatabase GetDatabase()
        {
            return Connection.GetDatabase();
        }

        public static IServer GetServer()
        {
            return Connection.GetServer(Connection.GetEndPoints()[0]);
        }
    }
}
