#!/usr/bin/env bash
################################################################################
# @file_name: database
# @version: 1
# @project_name: zen
# @description: a library for database functions
#
# @author: Thomas Chauveau (tomcdj71)
# @author_contact: thomas.chauveau.pro@gmail.com
#
# @license: BSD-3 Clause (Included in LICENSE)
# Copyright (C) 2024, Thomas Chauveau
# All rights reserved.
################################################################################

################################################################################
# @description: Executes a given sqlite3 query on the database
# @arg: $1: sqlite3 query
# @output: Query result to stdout or errors to stderr
# @return_code: Returns the exit status of the sqlite3 command
################################################################################
zen::database::query() {
    local query="$1"
    
    if [[ -z "$query" ]]; then
        mflibs::status::error "$(zen::i18n::translate "common.no_query_provided")"
        return 1
    fi

    declare -g sqlite3_db
    if [[ ! -f "$sqlite3_db" ]]; then
        mflibs::status::error "$(zen::i18n::translate "common.db_not_found" "$sqlite3_db")"
        return 1
    fi
    sqlite3 -cmd ".timeout 20000" "$sqlite3_db" "$query"
    sqlite3 -cmd ".timeout 20000" "$sqlite3_db" "$query" >"$([[ " ${MFLIBS_LOADED[*]} " =~ verbose ]] && echo "/dev/stdout" || echo "/dev/null")"
}

################################################################################
# @description: Executes a SELECT operation on the database
# @arg: $1: Table name
# @arg: $2: Select clause (optional, defaults to '*')
# @arg: $3: Where clause (optional)
# @arg: $4: Additional clauses like ORDER BY, GROUP BY, etc (optional)
# @arg: $5: Distinct flag (optional, set to '1' for DISTINCT)
# @output: Query result to stdout or errors to stderr
# @return_code: Returns the exit status of the sqlite3 command
################################################################################
zen::database::select() {
    local select_clause="$1"
    local table="$2"
    local where_clause="$3"
    local additional_clauses="$4"
    local distinct_flag="${5:-0}"

    local query="SELECT"
    if [[ "$distinct_flag" == "1" ]]; then
        query+=" DISTINCT"
    fi
    query+=" ${select_clause} FROM ${table}"

    if [[ -n "$where_clause" ]]; then
        query+=" WHERE ${where_clause}"
    fi

    if [[ -n "$additional_clauses" ]]; then
        query+=" ${additional_clauses}"
    fi

    zen::database::query "$query"
}

################################################################################
# @description: Executes a SELECT COUNT operation on the database
# @arg: $1: Table name
# @arg: $2: Select clause (optional, defaults to '*')
# @arg: $3: Where clause (optional)
# @arg: $4: Additional clauses like ORDER BY, GROUP BY, etc (optional)
# @output: Query result to stdout or errors to stderr
# @return_code: Returns the exit status of the sqlite3 command
################################################################################
zen::database::select::count() {
    local select_clause="$1"
    local table="$2"
    local where_clause="$3"
    local additional_clauses="$4"

    local query="SELECT COUNT"
    query+=" ${select_clause} FROM ${table}"

    if [[ -n "$where_clause" ]]; then
        query+=" WHERE ${where_clause}"
    fi

    if [[ -n "$additional_clauses" ]]; then
        query+=" ${additional_clauses}"
    fi

    zen::database::query "$query"
}


################################################################################
# @description: Executes an INNER JOIN SELECT operation on the database
# @arg: $1: Select clause
# @arg: $2: Table name with alias
# @arg: $3: Inner join clause with table and alias
# @arg: $4: Where clause (optional)
# @arg: $5: Additional clauses like ORDER BY, GROUP BY, etc (optional)
# @arg: $6: Distinct flag (optional, set to '1' for DISTINCT)
# @output: Query result to stdout or errors to stderr
# @return_code: Returns the exit status of the sqlite3 command
################################################################################
zen::database::select::inner_join() {
    local select_clause="$1"
    local table="$2"
    local inner_join_clause="$3"
    local where_clause="${4:-1=1}"
    local additional_clauses="$5"
    local distinct_flag="$6"
    
    local query="SELECT"
    if [[ "$distinct_flag" == "1" ]]; then
        query+=" DISTINCT"
    fi
    query+=" ${select_clause} FROM ${table} INNER JOIN ${inner_join_clause}"

    if [[ -n "$where_clause" ]]; then
        query+=" WHERE ${where_clause}"
    fi

    if [[ -n "$additional_clauses" ]]; then
        query+=" ${additional_clauses}"
    fi
    zen::database::query "$query"
}

################################################################################
# @description: Executes an INSERT operation on the database
# @arg: $1: Table name
# @arg: $2: Comma-separated list of columns
# @arg: $3: Comma-separated list of values corresponding to the columns
# @output: Query result to stdout or errors to stderr
# @return_code: Returns the exit status of the sqlite3 command
################################################################################
zen::database::insert() {
    local table="$1"
    local columns="$2"
    local values="$3"

    if [[ -z "$table" || -z "$columns" || -z "$values" ]]; then
        mflibs::status::error "$(zen::i18n::translate "common.missing_arguments")"
        return 1
    fi

    local query="INSERT INTO ${table} (${columns}) VALUES (${values});"

    zen::database::query "$query"
}

################################################################################
# @description: Executes an UPDATE operation on the database
# @arg: $1: Table name
# @arg: $2: Update clause (column-value pairs)
# @arg: $3: Where clause (specifies which records to update)
# @output: Query result to stdout or errors to stderr
# @return_code: Returns the exit status of the sqlite3 command
################################################################################
zen::database::update() {
    local table="$1"
    local update_clause="$2"
    local where_clause="$3"

    if [[ -z "$table" || -z "$update_clause" || -z "$where_clause" ]]; then
        mflibs::status::error "$(zen::i18n::translate "common.missing_arguments")"
        return 1
    fi

    local query="UPDATE ${table} SET ${update_clause} WHERE ${where_clause};"

    zen::database::query "$query"
}

################################################################################
# @description: Executes a DELETE operation on the database
# @arg: $1: Table name
# @arg: $2: Where clause (specifies which records to delete)
# @output: Query result to stdout or errors to stderr
# @return_code: Returns the exit status of the sqlite3 command
################################################################################
zen::database::delete() {
    local table="$1"
    local where_clause="$2"

    if [[ -z "$table" || -z "$where_clause" ]]; then
        mflibs::status::error "$(zen::i18n::translate "common.missing_arguments")"
        return 1
    fi

    local query="DELETE FROM ${table} WHERE ${where_clause};"

    zen::database::query "$query"
}

################################################################################
# @description: Parses SQL query results and populates global variables
# @arg: $1: query result string,
# @arg: $2: prefix for global variables,
# @arg: $3: index of the identifier column in the query result,
# @arg: $4: array of column names
# @output: Sets global variables
# @return_code: None
# shellcheck disable=SC2034
################################################################################
zen::database::load_config() {
    local query_result="$1"
    local -n assoc_array="$2"
    local identifier_index="$3"
    local -n column_names="$4"
    local identifier value column_name key

    IFS=$'\n' read -d '' -ra array <<<"$query_result"
    
    for row in "${array[@]}"; do
        IFS='|' read -ra row_data <<<"$row"
        identifier="${row_data[identifier_index]}"
        for i in "${!row_data[@]}"; do
            column_name="${column_names[i]}"
            value="${row_data[i]}"
            key="${column_name}"
            key="${key//[^a-zA-Z0-9_]/_}"
            assoc_array["$key"]="$value"
        done
    done
}

################################################################################
# @description: Parses SQL inner join query results and populates global variables
# @arg: $1: inner join query result string, 
# @arg: $2: prefix for global variables,
# @arg: $3: array of column names
# @output: Sets global variables
################################################################################
zen::database::load_joined_config() {
    local query_result="$1"
    local prefix="$2"
    local -n column_names="$3"
    local identifier value sanitized_name column_name
    IFS=$'\n' read -d '' -ra config_array <<<"$query_result"

    for row in "${config_array[@]}"; do
        IFS='|' read -ra row_data <<<"$row"
        identifier="${row_data[2]}"
        for i in "${!row_data[@]}"; do
            column_name="${column_names[i]}"
            value="${row_data[i]}"
            sanitized_name="${prefix}_${identifier}_${column_name}"
            sanitized_name="${sanitized_name//[^a-zA-Z0-9_]/_}"
            declare -g "$sanitized_name"="$value"
        done
    done
}
