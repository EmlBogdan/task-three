FROM prom/alertmanager

COPY images/alertmanager/alertmanager.yml /tmp/alertmanager.yml

CMD [ "--config.file=/tmp/alertmanager.yml" ]
