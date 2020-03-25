library(httr)
library(jsonlite)
library(reticulate)

source_python("/ai4e_api_tools/task_management/distributed_api_task.py")

task_mgr = DistributedApiTaskManager()

AddTask<-function(request){
  return(task_mgr$AddTask())

CompleteTask<-function(taskId, status){
  return(task_mgr$CompleteTask(taskId, status))
}

UpdateTaskStatus<-function(taskId, status){
  return(task_mgr$UpdateTaskStatus(taskId, status))
}

AddPipelineTask<-function(taskId, organization_moniker, version, api_name, body){
  return(task_mgr$AddPipelineTask(taskId, organization_moniker, version, api_name, body))
}

GetTaskStatus<-function(taskId){
  return(task_mgr$GetTaskStatus(taskId))
}

# Please have an empty last line in the end; otherwise, you will see an error when starting a webserver
