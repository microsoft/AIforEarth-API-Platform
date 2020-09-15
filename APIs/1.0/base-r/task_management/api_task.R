# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.
library(crul)
library(jsonlite)
library(urltools)

InternalUpdateTaskStatus<-function(taskId, status, backendStatus){
  print(paste0("Updating task: ", taskId, " to:", status))
  old_stat <- GetTaskStatus(taskId)

  if (old_stat$TaskId == "-1") {
    return(old_stat)
  }

  if (is.empty(old_stat$Endpoint)) {
    endpoint <- 'http://localhost'
  }
  else {
    endpoint <- old_stat$Endpoint
  }

  timestamp <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
 
  jdf <- data.frame(taskId, timestamp, status, backendStatus, endpoint, FALSE)
  colnames(jdf) <- c("TaskId", "Timestamp", "Status", "BackendStatus", "Endpoint", "PublishToGrid")

  update_uri <- Sys.getenv('CACHE_CONNECTOR_UPSERT_URI')
  caller <- Async$new(urls = c(update_uri))
  (r <- caller$post(body = toJSON(jdf), headers=list("Content-Type"="application/json")))

  if (r[[1]]$status_code != 200) {
    print(paste("Status from task upsert: ", r[[1]]$status_code))
    return(paste0('{"TaskId": "', taskId, '", "Status": "unable to update"}'))
  }

  res <- r[[1]]$parse("UTF-8")
  return(res)
}

AddPipelineTask<-function(taskId, organization_moniker, version, api_name, body){
  old_stat <- GetTaskStatus(taskId)
  
  if (old_stat$TaskId == "-1") {
    print("Cannot find task status.")
    return('{"TaskId": "-1", "Status": "error"}')
  }

  parsed_endpoint <- url_parse(old_stat$Endpoint)

  parsed_endpoint$path <- paste0(version, '/', organization_moniker, '/', api_name)
  next_endpoint <- url_compose(parsed_endpoint)

  print(paste("Sending to next endpoint:", next_endpoint))
  timestamp <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")

  jdf <- data.frame(taskId, timestamp, "created", "created", next_endpoint, TRUE)
  colnames(jdf) <- c("TaskId", "Timestamp", "Status", "BackendStatus", "Endpoint", "PublishToGrid")

  update_uri <- paste0(Sys.getenv('CACHE_CONNECTOR_UPSERT_URI'), "&taskId=", taskId)

  caller <- Async$new(urls = c(update_uri))
  (r <- caller$post(body = toJSON(jdf), headers=list("Content-Type"="application/json")))

  if (r[[1]]$status_code != 200) {
    return(paste0('{"TaskId": "', taskId, '", "Status": "not found"}'))
  }

  res <- r[[1]]$parse("UTF-8")
  print(paste("AddPipelineTask result: ", res))
  return(res)
}

AddTask<-function(request){
  print("Creating DistributedApiTaskManager.")
  res = "{}"
  
  # We should never have to add a new task.  That is done by the task management infra.
  if (is.null(request) || is.null(request$HTTP_TASKID)) {
    return('{"TaskId": "-1", "Status": "error"}')
  }
  else {
    print(paste("Adding task for ", request$HTTP_TASKID))
    res <- GetTaskStatus(request$HTTP_TASKID)
    print(paste("AddTask result: ", res))
    return(res)
  }
}

UpdateTaskStatus<-function(taskId, status){
  return(InternalUpdateTaskStatus(taskId, status, "running"))
}

CompleteTask<-function(taskId, status){
  return(InternalUpdateTaskStatus(taskId, status, "completed"))
}

FailTask<-function(taskId, status){
  return(InternalUpdateTaskStatus(taskId, status, "failed"))
}

#* Get status of task by id
#* @param taskId The id of the task
#* @get /task/<taskId>
GetTaskStatus<-function(taskId){
  print(paste("taskid:", taskId))
  uri <- paste0(Sys.getenv('CACHE_CONNECTOR_GET_URI'), "&taskId=", taskId)
  caller <- Async$new(urls = c(uri))
  (r <- caller$get())
  print(paste(r[[1]]$status_code))
  cnt <- r[[1]]$parse("UTF-8")

  if (r[[1]]$status_code != 200) {
    print(paste0("GetTaskStatus result:", "Task (", taskId, ") error: ", r[[1]]$status_code, ": ", cnt))
    return('{"TaskId": "-1", "Status": "error"}')
  }
  else {
    res <- fromJSON(cnt)
    return(res)
  }
}

# Please have an empty last line in the end; otherwise, you will see an error when starting a webserver
