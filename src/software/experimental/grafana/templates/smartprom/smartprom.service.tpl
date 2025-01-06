[Unit]
Description=SMART Prometheus metrics

[Service]
ExecStart=/opt/grafana/tools/scripts/prometheus-smartctl/.venv/bin/python /opt/grafana/tools/scripts/prometheus-smartctl/smartprom.py
Restart=always

[Install]
WantedBy=multi-user.target
