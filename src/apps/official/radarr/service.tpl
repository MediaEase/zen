[Unit]
Description=Radarr Daemon
After=syslog.target network.target

[Service]
User=%i
Group=%i
Type=simple

Environment="TMPDIR=/home/%i/tmp/Radarr"
ExecStartPre=-/bin/mkdir -p /home/%i/tmp/Radarr
ExecStart=/opt/%i/Radarr/Radarr -nobrowser -data=/home/%i/.config/Radarr -config=/home/%i/.config/Radarr/config.xml
TimeoutStopSec=20
KillMode=process
Restart=on-failure

[Install]
WantedBy=multi-user.target
