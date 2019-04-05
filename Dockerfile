FROM 888658187696.dkr.ecr.us-east-1.amazonaws.com/spark:2.4.0-hadoop2.7

RUN mkdir -p /jobserver/logs && apt update && apt install -y vim

COPY _buildFolder /jobserver/

ENV PATH=$PATH:/jobserver/ JOBSERVER_FG=true
