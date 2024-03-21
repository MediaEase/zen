sendmail_path = "/usr/sbin/sendmail -t -i"
mail.force_extra_parameters = "?ping_threshold=200&max_per_second=2"
session.cookie_httponly = 1
session.cookie_secure = 1
max_file_uploads = 5
memory_limit = 1024M
max_execution_time = 120
max_input_vars = 1000
session.gc_maxlifetime = 3600
upload_max_filesize = "4M"
post_max_size = "4M"
date.timezone = UTC
expose_php = Off
realpath_cache_size = 4096k
realpath_cache_ttl = 600
file_uploads = On
disable_functions = system,passthru
output_buffering = 4096
display_errors = On
display_startup_errors = On
error_reporting = E_ALL
session.use_strict_mode = 0
[opcache]
opcache.enable=1
opcache.memory_consumption=128
opcache.interned_strings_buffer=8
opcache.max_accelerated_files=32000
opcache.validate_timestamps=1
