#!/usr/bin/env bash
# Script for deploying the job server to a host

set -e

ENV=docker
docker_tag=$1

bin=`dirname "${BASH_SOURCE-$0}"`
bin=`cd "$bin"; pwd`

if [ -z "$CONFIG_DIR" ]; then
  CONFIG_DIR=`cd "$bin"/../config/; pwd`
fi
configFile="$CONFIG_DIR/$ENV.sh"
if [ ! -f "$configFile" ]; then
  echo "Could not find $configFile"
  exit 1
fi
. "$configFile"

majorRegex='([0-9]+\.[0-9]+)\.[0-9]+'
if [[ $SCALA_VERSION =~ $majorRegex ]]
then
  majorVersion="${BASH_REMATCH[1]}"
else
  echo "Please specify SCALA_VERSION in ${configFile}"
  exit 1
fi

cd $(dirname $0)/..
sbt ++$SCALA_VERSION job-server-extras/assembly
if [ "$?" != "0" ]; then
  echo "Assembly failed"
  exit 1
fi

FILES="job-server-extras/target/scala-$majorVersion/spark-job-server.jar
       bin/server_start.sh
       bin/server_stop.sh
       bin/kill-process-tree.sh
       bin/setenv.sh
       $CONFIG_DIR/$ENV.conf
       config/log4j-server.properties"

if [ ! -d "$bin/../build/$ENV" ]; then
	mkdir -p $bin/../build/$ENV
fi

buildFolder=`cd "$bin"/../build/"$ENV"; pwd`

rm -rf $buildFolder/*
cp $FILES $buildFolder/
cp $configFile $buildFolder/settings.sh

sed "s|_buildFolder|build/$ENV|g" Dockerfile > Dockerfile.$ENV

if [[ -z "$docker_tag" ]]; then
  docker_tag=latest
fi

export AWS_PROFILE=non-prod

docker build --rm -t spark-jobserver:${docker_tag} -f Dockerfile.$ENV .
docker tag spark-jobserver:${docker_tag} spark-jobserver:latest
docker tag spark-jobserver:${docker_tag} 888658187696.dkr.ecr.us-east-1.amazonaws.com/spark-jobserver:${docker_tag}
docker tag spark-jobserver:latest 888658187696.dkr.ecr.us-east-1.amazonaws.com/spark-jobserver:latest
docker push 888658187696.dkr.ecr.us-east-1.amazonaws.com/spark-jobserver:${docker_tag}
docker push 888658187696.dkr.ecr.us-east-1.amazonaws.com/spark-jobserver:latest

cd $(dirname $0)/../aws
./update-task.sh