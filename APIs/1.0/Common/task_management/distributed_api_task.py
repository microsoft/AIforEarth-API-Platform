# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.
import requests
import aiohttp
import asyncio
import datetime
import json
from os import getenv
from urllib.parse import urlparse, urlunparse
from urllib3.util import Retry

class DistributedApiTaskManager:
    def __init__(self):
        self.cache_connector_upsert_url = getenv('CACHE_CONNECTOR_UPSERT_URI')
        self.cache_connector_get_url = getenv('CACHE_CONNECTOR_GET_URI')

    def AddTask(self):
        ret = asyncio.get_event_loop().run_until_complete(self.AddTaskAsync())
        return json.loads(ret)

    async def AddTaskAsync(self):
        async with aiohttp.ClientSession() as session:
            async with session.post(self.cache_connector_upsert_url) as resp:
                if resp.status != 200:
                    return '{"TaskId": "-1", "Status": "error"}'
                else:
                    return await resp.text("UTF-8")

    def _UpdateTaskStatus(self, taskId, status, backendStatus):
        old_stat = self.GetTaskStatus(taskId)
        endpoint = 'http://localhost'
        if not old_stat['Endpoint']:
            print("Cannot find task status. Creating")
        else:
            endpoint = old_stat['Endpoint']

        ret = asyncio.get_event_loop().run_until_complete(self._UpdateTaskStatusAsync(taskId, status, backendStatus, endpoint))
        return json.loads(ret)

    async def _UpdateTaskStatusAsync(self, taskId, status, backendStatus, endpoint):
        session = aiohttp.ClientSession()
        resp = await session.post(self.cache_connector_upsert_url, json={'TaskId': taskId, 
                'Timestamp': datetime.datetime.strftime(datetime.datetime.now(), "%Y-%m-%d %H:%M:%S"), 
                'Status': status, 
                'BackendStatus': backendStatus,
                'Endpoint': endpoint,
                'PublishToGrid': False
            })
        if resp.status != 200:
            print("status code: " + str(resp.status_code))
            resstr = '{"TaskId": "' + taskId + '", "Status": "not found"}'
        else:
            resstr = await resp.text("UTF-8")

        await session.close()
        return resstr

    def CompleteTask(self, taskId, status):
        return self._UpdateTaskStatus(taskId, status, 'completed')

    def UpdateTaskStatus(self, taskId, status):
        return self._UpdateTaskStatus(taskId, status, 'running')

    def FailTask(self, taskId, status):
        return self._UpdateTaskStatus(taskId, status, 'failed')

    def AddPipelineTask(self, taskId, organization_moniker, version, api_name, body):
        old_stat = self.GetTaskStatus(taskId)
        if old_stat['Status'] == "not found":
            print("Cannot find task status.")
            return json.loads('{"TaskId": "-1", "Status": "error"}')
        
        parsed_endpoint = urlparse(old_stat['Endpoint'])
        path = '{}/{}/{}'.format(version, organization_moniker, api_name)
        next_endpoint = '{}://{}/{}'.format(parsed_endpoint.scheme, parsed_endpoint.netloc, path)

        print("Sending to next endpoint: " + next_endpoint)

        asyncio.set_event_loop(asyncio.new_event_loop())
        ret = asyncio.get_event_loop().run_until_complete(self.AddPipelineTaskAsync(taskId, next_endpoint, body))
        return json.loads(ret)

    async def AddPipelineTaskAsync(self, taskId, next_endpoint, body):
        session = aiohttp.ClientSession()
        resp = await session.post(self.cache_connector_upsert_url, json={'TaskId': taskId, 
                'Timestamp': datetime.datetime.strftime(datetime.datetime.now(), "%Y-%m-%d %H:%M:%S"), 
                'Status': 'created', 
                'BackendStatus': 'created',
                'Endpoint': next_endpoint,
                'Body': body,
                'PublishToGrid': True
            })
        if resp.status != 200:
            print("status code: " + str(r.status_code))
            resstr = '{"TaskId": "' + taskId + '", "Status": "not found"}'
        else:
            resstr = await resp.text("UTF-8")

        await session.close()
        return resstr

    def GetTaskStatus(self, taskId):
        asyncio.set_event_loop(asyncio.new_event_loop())
        ret = asyncio.get_event_loop().run_until_complete(self.GetTaskStatusAsync(taskId))
        return json.loads(ret)

    async def GetTaskStatusAsync(self, taskId):
        session = aiohttp.ClientSession()
        resp = await session.get(self.cache_connector_get_url, params={'taskId': taskId})
        if resp.status != 200:
            resstr = '{"TaskId": "' + taskId + '", "Status": "not found"}'
        else:
            resstr = await resp.text("UTF-8")

        await session.close()
        return resstr