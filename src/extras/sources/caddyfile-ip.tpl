{
    persist_config off
    log {
        output file /var/log/caddy/access.log {
            roll_size 50MiB
            roll_local_time
            roll_keep_for 720h
            roll_keep 5
            level debug
        }
    }
    ocsp_stappling off
}
SERVER_NAME {
    header {
        Strict-Transport-Security "max-age=31536000;"
        X-XSS-Protection "1; mode=block"
        X-Frame-Options "DENY"
        X-Robots-Tag "none"
        -Server
    }
    bind {$ADDRESS}
    tls internal
    tls EMAIL_ADDRESS
    tls /etc/ssl/certs/mediaease.crt /etc/ssl/private/mediaease.key
    root * /srv/harmonyui/public

    encode zstd gzip
    
    file_server
    php_fastcgi unix//var/run/php/php8.3-fpm.sock {
        resolve_root_symlink
    }

    @phpFile {
        path *.php*
    }
    error @phpFile "Not found" 404

    import /etc/caddy/softwares/*.caddy
}
