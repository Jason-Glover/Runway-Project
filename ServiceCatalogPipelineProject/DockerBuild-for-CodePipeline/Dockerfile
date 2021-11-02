FROM public.ecr.aws/ubuntu/ubuntu:20.04 AS core

RUN mkdir -p /root/scripts
WORKDIR /root

RUN apt update && apt upgrade
RUN apt install unzip -y && apt install python3 -y && apt install curl -y && apt install python3-pip -y
RUN cd /tmp && curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o awscliv2.zip
RUN cd /tmp && unzip awscliv2.zip
RUN cd /tmp && ./aws/install
COPY requirements.txt /root/scripts
COPY lambda-cloudformation.yaml /root/scripts
COPY sync-catalog.py /root/scripts

