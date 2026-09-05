FROM grafana/agent:v0.44.8

COPY configs/alertmanager.yml /tmp/prometheus.yml

CMD [ "-config.file=/tmp/agent.yaml" ]