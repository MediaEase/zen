[Unit]
Description=Pushgateway (Prometheus)
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/var/lib/pushgateway/pushgateway

[Install]
WantedBy=multi-user.target
