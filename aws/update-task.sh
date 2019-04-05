#!/usr/bin/env bash

set -e

slave_task_arn=$(aws ecs register-task-definition --cli-input-json file://task-slave | jq -r .taskDefinition.taskDefinitionArn)
master_task_arn=$(aws ecs register-task-definition --cli-input-json file://task-master | jq -r .taskDefinition.taskDefinitionArn)
jobserver_task_arn=$(aws ecs register-task-definition --cli-input-json file://task-jobserver | jq -r .taskDefinition.taskDefinitionArn)

aws ecs update-service --cluster spark --service master --force-new-deployment --task-definition ${master_task_arn}
aws ecs update-service --cluster spark --service slave --force-new-deployment --task-definition ${slave_task_arn}
aws ecs update-service --cluster spark --service jobserver --force-new-deployment --task-definition ${jobserver_task_arn}