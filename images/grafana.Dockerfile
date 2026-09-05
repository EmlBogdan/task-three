FROM grafana/grafana:latest

COPY --chown=grafana:grafana configs/dashboards.yaml /etc/grafana/provisioning/dashboards/dashboards.yaml
COPY --chown=grafana:grafana configs/datasources.yaml /etc/grafana/provisioning/datasources/datasources.yaml
COPY --chown=grafana:grafana dashboards /var/lib/grafana/dashboards
COPY --chown=grafana:grafana rules /etc/grafana/provisioning/alerting








