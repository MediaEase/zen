#!/usr/bin/env bash
# @file modules/requests.sh
# @project MediaEase
# @version 1.1.0
# @description Contains a library of functions used in the MediaEase Project for managing requests.
# @license BSD-3 Clause (Included in LICENSE)
# @copyright Copyright (C) 2025, MediaEase

# @function zen::request::api_put
# @description Sends a JSON payload to an internal API endpoint using curl.
#			   Uses the -k flag to skip SSL checks and adds the header
#			   X-API-TOKEN from ${user[api_key]} for authentication.
# @arg $1: Path to the endpoint (e.g. /api/me/services/validate-service)
# @arg $2: JSON payload to send
# @arg $3: (optional) Content type of the payload - default: application/json
# @global $api_url Internal API URL
# @stdout Prints the API response.
# shellcheck disable=SC2154
################################################################################
zen::request::api_put() {
    local endpoint="$1"
    local payload="$2"
    local content_type="${3:-application/json}"
    local response
    if echo "$payload" | jq empty 2>/dev/null; then
        payload=$(echo "$payload" | jq 'walk(if type == "object" then with_entries(select(.value != "null")) else . end)')
    else
        mflibs::status::error "$(zen::i18n::translate "errors.network.invalid_json_payload")"
        return 1
    fi
    response=$(curl -ksL \
        -w "%{http_code}" \
        "${api_url}${endpoint}" \
        -H "Content-Type: $content_type" \
        -H 'accept: application/json' \
        -H "X-API-KEY: ${user[api_key]}" \
        -o /dev/null \
        -d "$payload")
    if [[ "$response" == "201" || "$response" == "200" ]]; then
        mflibs::status::success "$(zen::i18n::translate "success.network.request_sent")"
    else
        mflibs::status::error "$(zen::i18n::translate "errors.network.invalid_api_response" "$response")"
    fi
}

# @function zen::request::app_request_save
# @description Sends a request to an application endpoint using curl.
#			   Uses the -k flag to skip SSL checks and adds the header
#			   X-API-TOKEN from ${api_service[apikey]} for authentication.
# @arg $1: full url endpoint of the application
# @arg $2: (optional) HTTP method - default: POST
# @arg $3: JSON payload to send
# @arg $4: (optional) Whether to use the API key - default: true
# @arg $5: (optional) The API key field - default: X-API-KEY
# @stdout Prints the API response.
################################################################################
zen::request::app_request_save() {
    local endpoint="$1"
    local method="$2"
    local json_payload="${3:-}"
    local use_api_key="${4:-true}"
    local api_key_field="${5:-X-API-KEY}"

    local response
    local curl_args=(
        -ksL
        -w "%{http_code}"
        -X "$method"
        "$endpoint"
        -H "Content-Type: application/json"
        -H "accept: application/json"
        -o /dev/null
        -d "$json_payload"
    )
    if [[ "$use_api_key" == "true" ]]; then
        curl_args+=(-H "${api_key_field}: ${api_service[apikey]}")
    fi
    response=$(curl "${curl_args[@]}")
    if [[ "$response" =~ ^20[0-4]$ ]]; then
        mflibs::status::success "$(zen::i18n::translate "success.network.request_sent" "$endpoint")"
    else
        echo "cacaaaa"
        mflibs::status::error "$(zen::i18n::translate "errors.network.invalid_api_response" "$response")"
    fi
}

# @function zen::request::app_request_get
# @description Sends a GET request to an application endpoint using curl.
#			   Uses the -k flag to skip SSL checks and adds the header
#			   X-API-TOKEN from ${api_service[apikey]} for authentication.
# @arg $1: full url endpoint of the application
# @arg $2: (optional) Whether to use the API key - default: true
# @arg $3: (optional) The API key field - default: X-API-KEY
# @stdout Prints the API response.
################################################################################
zen::request::app_request_get() {
    local endpoint="$1"
    local use_api_key="${2:-true}"
    local api_key_field="${3:-X-API-KEY}"
    local response
    local curl_args=(
        -ksL
        "$endpoint"
    )
    if [[ "$use_api_key" == "true" ]]; then
        curl_args+=(-H "${api_key_field}: ${api_service[apikey]}")
    fi
    response=$(curl "${curl_args[@]}")
    if [[ "$response" != "" ]]; then
        echo "$response"
    else
        mflibs::status::error "$(zen::i18n::translate "errors.network.invalid_api_response" "$response")"
    fi
}
