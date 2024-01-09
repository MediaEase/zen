reverse_proxy /$username/$app_name* http://localhost:$port {
    uri strip_prefix /$username/$app_name
    header_up Host {http.request.host}
    header_up X-Real-IP {http.request.remote}
    header_up X-Forwarded-For {http.request.remote}
    header_up X-Forwarded-Port {http.request.port}
    header_up X-Forwarded-Proto {http.request.scheme}
}
