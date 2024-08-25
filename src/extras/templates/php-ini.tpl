[PHP]
; Core PHP settings
memory_limit = 1024M
max_execution_time = 120
max_input_time = 60
max_input_vars = 1000
file_uploads = On
max_file_uploads = 5
upload_max_filesize = "4M"
post_max_size = "4M"
realpath_cache_size = 4096k
realpath_cache_ttl = 600
output_buffering = 4096
disable_functions = ""
display_errors = On
display_startup_errors = On
log_errors = On
error_reporting = E_ALL
error_log = /var/log/php-fpm/error.log
date.timezone = UTC
expose_php = On

[Session]
; Session settings
session.save_handler = files
session.save_path = "/var/lib/php/sessions"
session.gc_maxlifetime = 3600
session.cookie_httponly = 1
session.cookie_secure = 1
session.use_strict_mode = 0

[Mail]
; Mail settings
sendmail_path = "/usr/sbin/sendmail -t -i"
mail.force_extra_parameters = "?ping_threshold=200&max_per_second=2"
mail.smtp_port = 25
sendmail_from = mediaease

[Opcache]
; Opcache settings for development
opcache.enable=1
opcache.memory_consumption=128
opcache.interned_strings_buffer=8
opcache.max_accelerated_files=32000
opcache.revalidate_freq=0
opcache.fast_shutdown=1
opcache.validate_timestamps=1

[PHP-FPM]
; PHP-FPM Process Manager settings
pm = dynamic
pm.max_children = 100
pm.start_servers = 25
pm.min_spare_servers = 10
pm.max_spare_servers = 35
pm.max_requests = 1000
