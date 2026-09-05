FROM prom/alertmanager

COPY configs/alertmanager.yml /tmp/alertmanager.yml

CMD [ "--config.file=/tmp/alertmanager.yml" ]
