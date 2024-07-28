#!/bin/bash
if [[ $USER == 'root' ]]; then
  _zen() {
    local current prev_word db_file
    COMPREPLY=()
    current="${COMP_WORDS[COMP_CWORD]}"
    prev_word="${COMP_WORDS[COMP_CWORD - 1]}"
    db_file="/opt/MediaEase/MediaEase/harmonyui/var/data.db"

    if [[ ! -f "$db_file" ]]; then
      printf "Database file not found: %s\n" "$db_file" >&2
      return 1
    fi

    local -a settings users software_apps
    mapfile -t settings < <(sqlite3 "$db_file" "SELECT name FROM setting")
    mapfile -t users < <(sqlite3 "$db_file" "SELECT username FROM user")
    mapfile -t software_apps < <(find /opt/MediaEase/MediaEase/zen/src/software/{official,experimental} -maxdepth 1 -mindepth 1 -type d -exec basename {} \;)

    local -a commands software_ops user_ops support_ops set_ops log_ops migrate_ops pull_ops
    commands=("software" "user" "support" "set" "pull" "service" "log" "migrate")
    software_ops=("add" "remove" "reinstall" "update" "backup" "restore" "reset" "create")
    user_ops=("add" "remove" "ban" "unban" "set")
    support_ops=("enable" "disable")
    set_ops=("${settings[@]}")
    log_ops=("[servicename]")
    migrate_ops=("init" "restore")
    pull_ops=()

    case "${COMP_WORDS[1]}" in
    software)
      if [[ "${COMP_WORDS[2]}" =~ ^(add|remove|reinstall|update|backup|restore|reset|create)$ ]] && [[ "$prev_word" == "-u" ]]; then
        mapfile -t COMPREPLY < <(compgen -W "${users[*]}" -- "$current")
      elif [[ "${COMP_WORDS[2]}" =~ ^(add|remove|reinstall|update|backup|restore|reset|create)$ ]]; then
        mapfile -t COMPREPLY < <(compgen -W "${software_apps[*]}" -- "$current")
      else
        mapfile -t COMPREPLY < <(compgen -W "${software_ops[*]}" -- "$current")
      fi
      ;;
    user)
      if [[ "${COMP_WORDS[2]}" =~ ^(ban|unban)$ ]] && [[ "$current" != "-"* ]]; then
        mapfile -t COMPREPLY < <(compgen -W "${users[*]}" -- "$current")
      elif [[ "$prev_word" == "-u" ]]; then
        mapfile -t COMPREPLY < <(compgen -W "${users[*]}" -- "$current")
      elif [[ "$prev_word" == "-s" ]]; then
        mapfile -t COMPREPLY < <(compgen -W "${set_ops[*]}" -- "$current")
      else
        mapfile -t COMPREPLY < <(compgen -W "${user_ops[*]}" -- "$current")
      fi
      ;;
    support)
      mapfile -t COMPREPLY < <(compgen -W "${support_ops[*]}" -- "$current")
      ;;
    set)
      if [[ "$prev_word" == "-s" ]]; then
        mapfile -t COMPREPLY < <(compgen -W "${set_ops[*]}" -- "$current")
      else
        mapfile -t COMPREPLY < <(compgen -W "-s -v" -- "$current")
      fi
      ;;
    log)
      mapfile -t COMPREPLY < <(compgen -W "${log_ops[*]}" -- "$current")
      ;;
    migrate)
      mapfile -t COMPREPLY < <(compgen -W "${migrate_ops[*]}" -- "$current")
      ;;
    pull)
      mapfile -t COMPREPLY < <(compgen -W "${pull_ops[*]}" -- "$current")
      ;;
    *)
      mapfile -t COMPREPLY < <(compgen -W "${commands[*]}" -- "$current")
      ;;
    esac
  }
  complete -F _zen zen
fi
