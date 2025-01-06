[Unit]
Description=Fluent Bit
Documentation=https://docs.fluentbit.io/manual/
Requires=network.target
After=network.target

[Service]
Type=simple
EnvironmentFile=-/etc/sysconfig/fluent-bit
EnvironmentFile=-/etc/default/fluent-bit
ExecStart=/opt/grafana/fluentbit/bin/fluent-bit -c /etc/fluent-bit/fluentbit.conf -v
Restart=always

[Install]
WantedBy=multi-user.target
