FROM grafana/agent:v0.44.8

COPY configs/agent.yaml /tmp/agent.yaml

CMD [ "-config.file=/tmp/agent.yaml" ]