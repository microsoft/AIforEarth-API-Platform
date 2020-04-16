from task_management.distributed_api_task import DistributedApiTaskManager
from flask_restful import Resource

print("Creating API task manager.")

class ApiTaskManager:
    def __init__(self, flask_api, resource_prefix = ""):
        self.resource_pfx = resource_prefix
        flask_api.add_resource(Task, self.resource_pfx + '/task/<int:id>', resource_class_kwargs={ 'task_manager': self })
        self.distributed_api_task = DistributedApiTaskManager()

    def AddTask(self, request):
        task = '{}'
        if not request or not 'taskId' in request.headers:
            task = self.distributed_api_task.AddTask()
        else:
            id = request.headers.get('taskId')
            task = self.distributed_api_task.GetTaskStatus(id)

        return task

    def CompleteTask(self, taskId, status):
        print("Completing task: " + str(taskId) + " to:" + str(status))
        return self.distributed_api_task.CompleteTask(taskId, status)

    def FailTask(self, taskId, status):
        print("Failed task: " + str(taskId) + " to:" + str(status))
        return self.distributed_api_task.FailTask(taskId, status)

    def UpdateTaskStatus(self, taskId, status):
        print("Updating task: " + str(taskId) + " to:" + str(status))
        return self.distributed_api_task.UpdateTaskStatus(taskId, status)

    def AddPipelineTask(self, taskId, organization_moniker, version, api_name, body):
        print("Adding pipeline task: " + str(taskId))
        return self.distributed_api_task.AddPipelineTask(taskId, organization_moniker, version, api_name, body)

    def GetTaskStatus(self, taskId):
        return self.distributed_api_task.GetTaskStatus(taskId)

class Task(Resource):
    def __init__(self, **kwargs):
        self.distributed_api_task = kwargs['distributed_api_task']

    def get(self, id):
        st = self.distributed_api_task.GetTaskStatus(id)
        return(st.json())