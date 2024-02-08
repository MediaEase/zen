#!/usr/bin/env bash
################################################################################
# @file_name: database.sh
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
# zen::database::query
#
# Executes a given SQLite3 query on the database. This function is a general
# utility for performing any SQLite3 query.
#
# Globals:
#   sqlite3_db - Path to the SQLite3 database file.
# Arguments:
#   query - SQLite3 query to be executed.
# Outputs:
#   Outputs the query result to stdout or errors to stderr.
# Returns:
#   Returns the exit status of the sqlite3 command.
# Notes:
#   The function checks for the presence of a query and the database file.
#   It uses a .timeout of 20000 to handle database locks.
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
# zen::database::select
#
# Executes a SELECT operation on the database. This function is capable of
# performing complex SELECT queries including WHERE and other additional clauses.
#
# Arguments:
#   table - Name of the table to select from.
#   select_clause - Columns to be selected (optional, defaults to '*').
#   where_clause - Conditions for selection (optional).
#   additional_clauses - Additional SQL clauses like ORDER BY, GROUP BY (optional).
#   distinct_flag - Flag for DISTINCT selection (optional, set to '1' for DISTINCT).
# Outputs:
#   Outputs the query result to stdout or errors to stderr.
# Returns:
#   Returns the exit status of the sqlite3 command.
# Notes:
#   Constructs a SELECT query based on the provided arguments.
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
# zen::database::select::count
#
# Executes a SELECT COUNT operation on the database. This function is used
# to count the number of records that meet certain conditions.
#
# Arguments:
#   table - Name of the table for counting records.
#   select_clause - Columns to be counted (optional, defaults to '*').
#   where_clause - Conditions for counting (optional).
#   additional_clauses - Additional SQL clauses like ORDER BY, GROUP BY (optional).
# Outputs:
#   Outputs the count result to stdout or errors to stderr.
# Returns:
#   Returns the exit status of the sqlite3 command.
# Notes:
#   Constructs a SELECT COUNT query based on the provided arguments.
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
# zen::database::select::inner_join
#
# Executes an INNER JOIN SELECT operation on the database. This function allows
# for joining tables and selecting data based on complex relationships.
#
# Arguments:
#   select_clause - Columns to be selected.
#   table - Name of the primary table with alias.
#   inner_join_clause - Inner join clause with the table and alias.
#   where_clause - Conditions for selection (optional).
#   additional_clauses - Additional SQL clauses like ORDER BY, GROUP BY (optional).
#   distinct_flag - Flag for DISTINCT selection (optional, set to '1' for DISTINCT).
# Outputs:
#   Outputs the query result to stdout or errors to stderr.
# Returns:
#   Returns the exit status of the sqlite3 command.
# Notes:
#   Constructs an INNER JOIN SELECT query based on the provided arguments.
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
# zen::database::insert
#
# Executes an INSERT operation on the database. This function is used to insert
# new records into a specified table.
#
# Arguments:
#   table - Name of the table to insert into.
#   columns - Comma-separated list of columns for the insert operation.
#   values - Comma-separated list of values corresponding to the columns.
# Outputs:
#   Outputs the query result to stdout or errors to stderr.
# Returns:
#   Returns the exit status of the sqlite3 command.
# Notes:
#   Constructs an INSERT INTO query based on the provided arguments.
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
# zen::database::update
#
# Executes an UPDATE operation on the database. This function is used to update
# existing records in a specified table.
#
# Arguments:
#   table - Name of the table to update.
#   update_clause - Column-value pairs for the update operation.
#   where_clause - Conditions specifying which records to update.
# Outputs:
#   Outputs the query result to stdout or errors to stderr.
# Returns:
#   Returns the exit status of the sqlite3 command.
# Notes:
#   Constructs an UPDATE query based on the provided arguments.
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
# zen::database::delete
#
# Executes a DELETE operation on the database. This function is used to delete
# records from a specified table.
#
# Arguments:
#   table - Name of the table to delete from.
#   where_clause - Conditions specifying which records to delete.
# Outputs:
#   Outputs the query result to stdout or errors to stderr.
# Returns:
#   Returns the exit status of the sqlite3 command.
# Notes:
#   Constructs a DELETE FROM query based on the provided arguments.
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
# zen::database::load_config
#
# Parses SQL query results and populates an associative array with the results.
# This function is designed to handle the output of SQL queries and format them
# into a usable form in bash scripts.
#
# Arguments:
#   query_result - A string containing the result of the SQL query.
#   assoc_array - A reference to the associative array to be populated with the
#                 query results.
#   identifier_index - The index of the identifier column in the query result.
#   column_names - An array of column names corresponding to the query result.
# Outputs:
#   Populates the provided associative array with key-value pairs where keys are
#   the column names and values are the corresponding values from the query.
# Notes:
#   The function expects the query result to be in a specific format, typically
#   obtained from a database query command. It sanitizes column names for bash
#   compatibility.
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
            # shellcheck disable=SC2034
            assoc_array["$key"]="$value"
        done
    done
}

################################################################################
# zen::database::load_joined_config
#
# Parses SQL inner join query results and populates global variables dynamically.
# Each variable is named based on a combination of a prefix, identifier, and
# column name, making it suitable for handling complex query results.
#
# Arguments:
#   query_result - A string containing the result of the SQL inner join query.
#   prefix - A prefix to be added to each global variable name.
#   column_names - An array of column names corresponding to the query result.
# Outputs:
#   Sets global variables dynamically for each column value in the query result.
#   The variable names are generated by concatenating the prefix, identifier,
#   and column name, sanitized for bash compatibility.
# Notes:
#   This function is particularly useful for handling the results of inner join
#   queries where multiple tables are involved. It assumes a specific format of
#   the query result and requires an appropriate prefix for variable naming.
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
