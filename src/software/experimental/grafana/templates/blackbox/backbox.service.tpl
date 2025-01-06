[Unit]
Description=blackbox exporter service (Prometheus)
After=network-online.target

[Service]
Type=simple
PIDFile=/run/blackbox_exporter.pid
ExecStart=/usr/local/bin/blackbox_exporter\
 --web.listen-address=0.0.0.0:9905\
 --config.file="/opt/grafana/tools/blackbox/blackbox.yaml"
User=root
Group=root
SyslogIdentifier=blackbox_exporter
Restart=on-failure
RemainAfterExit=no
RestartSec=100ms
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
