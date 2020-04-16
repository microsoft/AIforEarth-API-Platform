import requests
import datetime
import json
from os import getenv
from urllib.parse import urlparse, urlunparse

class DistributedApiTaskManager:
    def __init__(self):
        self.cache_connector_upsert_url = getenv('CACHE_CONNECTOR_UPSERT_URI')
        self.cache_connector_get_url = getenv('CACHE_CONNECTOR_GET_URI')

    def AddTask(self):
        r = requests.post(self.cache_connector_upsert_url)

        if r.status_code != 200:
            return -1
        else:
            return r.json()

    def _UpdateTaskStatus(self, taskId, status, backendStatus):
        old_stat = self.GetTaskStatus(taskId)
        if old_stat == "not found":
            print("Cannot find task status.")
        
        r = requests.post(self.cache_connector_upsert_url,
            data=json.dumps(
                {'Uuid': taskId, 
                'Timestamp': datetime.datetime.strftime(datetime.datetime.now(), "%Y-%m-%d %H:%M:%S"), 
                'Status': status, 
                'BackendStatus': backendStatus,
                'Endpoint': old_stat['Endpoint'],
                'Body': old_stat['Body'],
                'PublishToGrid': False
                })
            )

        if r.status_code != 200:
            print("status code: " + str(r.status_code))
            return -1
        else:
            return r.json()

    def CompleteTask(self, taskId, status):
        return self._UpdateTaskStatus(taskId, status, 'completed')

    def FailTask(self, taskId, status):
        return self._UpdateTaskStatus(taskId, status, 'failed')

    def UpdateTaskStatus(self, taskId, status):
        return self._UpdateTaskStatus(taskId, status, 'running')

    def AddPipelineTask(self, taskId, organization_moniker, version, api_name, body):
        old_stat = self.GetTaskStatus(taskId)
        if old_stat == "not found":
            print("Cannot find task status.")
        
        parsed_endpoint = urlparse(old_stat['Endpoint'])

        next_endpoint = urlunparse(('http', parsed_endpoint.netloc, organization_moniker + '/' + version + '/' + api_name))
        print("Sending to next endpoint: " + next_endpoint)

        r = requests.post(self.cache_connector_upsert_url,
            data=json.dumps(
                {'Uuid': taskId, 
                'Timestamp': datetime.datetime.strftime(datetime.datetime.now(), "%Y-%m-%d %H:%M:%S"), 
                'Status': 'created', 
                'BackendStatus': 'created',
                'Endpoint': next_endpoint,
                'Body': body,
                'PublishToGrid': True
                })
            )

        if r.status_code != 200:
            print("status code: " + str(r.status_code))
            return -1
        else:
            return r.json()

    def GetTaskStatus(self, taskId):
        r = requests.get(self.cache_connector_get_url, params={'taskId': taskId})

        if r.status_code != 200:
            return "not found"
        else:
            return r.json()