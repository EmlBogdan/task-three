FROM prom/prometheus

COPY --chown=nobody:nobody configs/prometheus.yml /tmp/prometheus.yml

CMD [ "--config.file=/tmp/prometheus.yml --storage.tsdb.path=/prometheus --web.enable-remote-write-receiver" ]