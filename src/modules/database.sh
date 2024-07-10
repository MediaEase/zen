#!/usr/bin/env bash
# @file modules/database.sh
# @project MediaEase
# @version 1.0.0
# @description Contains a library of database functions used in the MediaEase project.
# @author Thomas Chauveau (tomcdj71)
# @author_contact thomas.chauveau.pro@gmail.com
# @license BSD-3 Clause (Included in LICENSE)
# @copyright Copyright (C) 2024, Thomas Chauveau
# All rights reserved.

# @function zen::database::query
# @description Executes a given SQLite3 query on the database.
# @global sqlite3_db Path to the SQLite3 database file.
# @arg $1 string SQLite3 query to be executed.
# @stdout Outputs the query result or errors.
# @return Returns the exit status of the sqlite3 command.
# @note Checks for the presence of a query and the database file.
#      Uses a .timeout of 20000 to handle database locks.
zen::database::query() {
  local query="$1"

  if [[ -z "$query" ]]; then
    mflibs::status::error "$(zen::i18n::translate "database.no_query_provided")"
    return 1
  fi

  declare -g sqlite3_db
  if [[ ! -f "$sqlite3_db" ]]; then
    mflibs::status::error "$(zen::i18n::translate "database.db_not_found" "$sqlite3_db")"
    return 1
  fi
  sqlite3 -cmd ".timeout 20000" "$sqlite3_db" "$query"
  sqlite3 -cmd ".timeout 20000" "$sqlite3_db" "$query" >"$([[ " ${MFLIBS_LOADED[*]} " =~ verbose ]] && echo "/dev/stdout" || echo "/dev/null")"
}

# @function zen::database::select::count
# @description Executes a SELECT COUNT operation on the database.
# @arg $1 string Name of the table for counting records.
# @arg $2 string Columns to be counted (optional, defaults to '*').
# @arg $3 string Conditions for counting (optional).
# @arg $4 string Additional SQL clauses like ORDER BY, GROUP BY (optional).
# @stdout Outputs the count result or errors.
# @return Returns the exit status of the sqlite3 command.
# @note Constructs a SELECT COUNT query based on the provided arguments.
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

# @function zen::database::select::count
# @description Executes a SELECT COUNT operation on the database.
# @arg $1 string Name of the table for counting records.
# @arg $2 string Columns to be counted (optional, defaults to '*').
# @arg $3 string Conditions for counting (optional).
# @arg $4 string Additional SQL clauses like ORDER BY, GROUP BY (optional).
# @stdout Outputs the count result or errors.
# @return Returns the exit status of the sqlite3 command.
# @note Constructs a SELECT COUNT query based on the provided arguments.
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

# @function zen::database::select::inner_join
# @description Executes an INNER JOIN SELECT operation on the database.
# @arg $1 string Columns to be selected.
# @arg $2 string Name of the primary table with alias.
# @arg $3 string Inner join clause with the table and alias.
# @arg $4 string Conditions for selection (optional).
# @arg $5 string Additional SQL clauses like ORDER BY, GROUP BY (optional).
# @arg $6 string Flag for DISTINCT selection (optional, set to '1' for DISTINCT).
# @stdout Outputs the query result or errors.
# @return Returns the exit status of the sqlite3 command.
# @note Constructs an INNER JOIN SELECT query based on the provided arguments.
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
# @function zen::database::insert
# @description Executes an INSERT operation on the database.
# @arg $1 string Name of the table to insert into.
# @arg $2 string Comma-separated list of columns for the insert operation.
# @arg $3 string Comma-separated list of values corresponding to the columns.
# @stdout Outputs the query result or errors.
# @return Returns the exit status of the sqlite3 command.
# @note Constructs an INSERT INTO query based on the provided arguments.
zen::database::insert() {
  local table="$1"
  local columns="$2"
  local values="$3"

  if [[ -z "$table" || -z "$columns" || -z "$values" ]]; then
    mflibs::status::error "$(zen::i18n::translate "database.missing_arguments")"
    return 1
  fi

  local query="INSERT INTO ${table} (${columns}) VALUES (${values});"

  zen::database::query "$query"
}

# @function zen::database::update
# @description Executes an UPDATE operation on the database.
# @arg $1 string Name of the table to update.
# @arg $2 string Column-value pairs for the update operation.
# @arg $3 string Conditions specifying which records to update.
# @stdout Outputs the query result or errors.
# @return Returns the exit status of the sqlite3 command.
# @note Constructs an UPDATE query based on the provided arguments.
zen::database::update() {
  local table="$1"
  local update_clause="$2"
  local where_clause="$3"

  if [[ -z "$table" || -z "$update_clause" || -z "$where_clause" ]]; then
    mflibs::status::error "$(zen::i18n::translate "database.missing_arguments")"
    return 1
  fi

  local query="UPDATE ${table} SET ${update_clause} WHERE ${where_clause};"

  zen::database::query "$query"
}

# @function zen::database::delete
# @description Executes a DELETE operation on the database.
# @arg $1 string Name of the table to delete from.
# @arg $2 string Conditions specifying which records to delete.
# @stdout Outputs the query result or errors.
# @return Returns the exit status of the sqlite3 command.
# @note Constructs a DELETE FROM query based on the provided arguments.
zen::database::delete() {
  local table="$1"
  local where_clause="$2"

  if [[ -z "$table" || -z "$where_clause" ]]; then
    mflibs::status::error "$(zen::i18n::translate "database.missing_arguments")"
    return 1
  fi

  local query="DELETE FROM ${table} WHERE ${where_clause};"

  zen::database::query "$query"
}

# @function zen::database::load_config
# @description Parses SQL query results into an associative array.
# @arg $1 string Result of the SQL query.
# @arg $2 string Reference to the associative array for query results.
# @arg $3 string Index of the identifier column in the query result.
# @arg $4 string Array of column names corresponding to the query result.
# @stdout Populates the provided associative array with query results.
# @note Expects query result in a specific format; sanitizes column names.
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

# @function zen::database::load_joined_config
# @description Parses SQL inner join query results into global variables.
# @arg $1 string Result of the SQL inner join query.
# @arg $2 string Prefix for global variable names.
# @arg $3 string Array of column names corresponding to the query result.
# @stdout Sets global variables for each column value in the query result.
# @note Assumes a specific format of the query result; requires an appropriate prefix.
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
