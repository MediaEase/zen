#!/bin/bash
if [[ $USER == 'root' ]]; then
  _zen() {
    local current prev_word db_file preference_fields used_flags
    COMPREPLY=()
    current="${COMP_WORDS[COMP_CWORD]}"
    prev_word="${COMP_WORDS[COMP_CWORD - 1]}"
    DATABASE_URL=$(grep '^DATABASE_URL' /srv/harmonyui/.env.local)
    db_file="${DATABASE_URL##*/}"
    db_file="/srv/harmonyui/$db_file"

    if [[ ! -f "$db_file" ]]; then
      printf "Database file not found: %s\n" "$db_file" >&2
      return 1
    fi

    local -a users software_apps services setting_fields
    mapfile -t users < <(sqlite3 "$db_file" "SELECT username FROM user")
    mapfile -t software_apps < <(find /opt/MediaEase/MediaEase/zen/src/software/{official,experimental} -maxdepth 1 -mindepth 1 -type d -exec basename {} \;)
    mapfile -t services < <(sqlite3 "$db_file" "SELECT name FROM service")
    mapfile -t setting_fields < <(sqlite3 "$db_file" "PRAGMA table_info(setting);" | awk -F'|' '$2 != "id" {print $2}')

    local -a commands software_ops user_ops support_ops log_ops migrate_ops pull_ops service_ops user_add_ops
    commands=("software" "user" "support" "set" "pull" "service" "log" "migrate" "tools")
    software_ops=("add" "remove" "reinstall" "update" "backup" "restore" "reset" "create")
    service_ops=("start" "stop" "status" "enable" "disable" "reload" "restart")
    user_ops=("add" "remove" "ban" "unban" "set")
    user_add_ops=("-u" "-p" "-e" "-q" "-s")
    support_ops=("enable" "disable")
    log_ops=("[servicename]")
    migrate_ops=("init" "restore")
    pull_ops=()
    tools_subcommands=("igpu" "kernel" "quota")
    igpu_ops=("update")
    kernel_ops=("check")
    quota_ops=("install" "status" "set")

    used_flags=()
    for word in "${COMP_WORDS[@]}"; do
      if [[ "$word" =~ ^- ]]; then
        used_flags+=("$word")
      fi
    done
    local available_user_add_ops=()
    for flag in "${user_add_ops[@]}"; do
      if [[ ! " ${used_flags[*]} " =~ $flag ]]; then
        available_user_add_ops+=("$flag")
      fi
    done

    case "${COMP_WORDS[1]}" in
    software)
      if [[ "${COMP_WORDS[2]}" =~ ^(add|remove|reinstall|update|backup|restore|reset)$ ]]; then
        if [[ "$COMP_CWORD" -eq 3 ]]; then
          mapfile -t COMPREPLY < <(compgen -W "${software_apps[*]}" -- "$current")
        elif [[ "$COMP_CWORD" -eq 4 ]]; then
          mapfile -t COMPREPLY < <(compgen -W "-u" -- "$current")
        elif [[ "$prev_word" == "-u" ]]; then
          mapfile -t COMPREPLY < <(compgen -W "${users[*]}" -- "$current")
        fi
      elif [[ "${COMP_WORDS[2]}" == "create" ]]; then
        COMPREPLY=()
      else
        mapfile -t COMPREPLY < <(compgen -W "${software_ops[*]}" -- "$current")
      fi
      ;;
    user)
      if [[ "$COMP_CWORD" -eq 2 ]]; then
        mapfile -t COMPREPLY < <(compgen -W "${user_ops[*]}" -- "$current")
      else
        case "${COMP_WORDS[2]}" in
        add)
          if [[ "$prev_word" == "-u" ]]; then
            mapfile -t COMPREPLY < <(compgen -W "${users[*]}" -- "$current")
          elif [[ "$prev_word" == "-s" ]]; then
            mapfile -t COMPREPLY < <(compgen -W "/bin/bash /bin/sh /usr/bin/zsh" -- "$current")
          else
            mapfile -t COMPREPLY < <(compgen -W "${available_user_add_ops[*]}" -- "$current")
          fi
          ;;
        ban | remove | unban)
          if [[ "$COMP_CWORD" -eq 3 ]]; then
            mapfile -t COMPREPLY < <(compgen -W "${users[*]}" -- "$current")
          else
            COMPREPLY=()
          fi
          ;;
        set)
          if [[ "$COMP_CWORD" -eq 3 ]]; then
            mapfile -t COMPREPLY < <(compgen -W "-u" -- "$current")
          elif [[ "$prev_word" == "-u" ]]; then
            mapfile -t COMPREPLY < <(compgen -W "${users[*]}" -- "$current")
          elif [[ "$COMP_CWORD" -eq 5 ]]; then
            mapfile -t COMPREPLY < <(compgen -W "-s" -- "$current")
          elif [[ "$prev_word" == "-s" ]]; then
            mapfile -t preference_fields < <(sqlite3 "$db_file" "PRAGMA table_info(preference);" | awk -F'|' '$2 != "id" && $2 != "user_id" && $2 != "pinned_apps" && $2 != "selected_widgets" {print $2}')
            mapfile -t COMPREPLY < <(compgen -W "${preference_fields[*]}" -- "$current")
          elif [[ "$COMP_CWORD" -eq 7 ]]; then
            mapfile -t COMPREPLY < <(compgen -W "-v" -- "$current")
          elif [[ "$prev_word" == "-v" ]]; then
            if [[ "${COMP_WORDS[COMP_CWORD - 2]}" =~ _enabled$ ]]; then
              mapfile -t COMPREPLY < <(compgen -W "true false" -- "$current")
            else
              COMPREPLY=()
            fi
          fi
          ;;
        esac
      fi
      ;;
    support)
      mapfile -t COMPREPLY < <(compgen -W "${support_ops[*]}" -- "$current")
      ;;
    service)
      if [[ "$COMP_CWORD" -eq 2 ]]; then
        mapfile -t COMPREPLY < <(compgen -W "${service_ops[*]}" -- "$current")
      elif [[ "$COMP_CWORD" -eq 3 ]]; then
        mapfile -t COMPREPLY < <(compgen -W "${services[*]}" -- "$current")
      else
        COMPREPLY=()
      fi
      ;;
    set)
      if [[ "$COMP_CWORD" -eq 2 ]]; then
        mapfile -t COMPREPLY < <(compgen -W "-s" -- "$current")
      elif [[ "$prev_word" == "-s" ]]; then
        mapfile -t COMPREPLY < <(compgen -W "${setting_fields[*]}" -- "$current")
      elif [[ "$COMP_CWORD" -eq 4 ]]; then
        mapfile -t COMPREPLY < <(compgen -W "-v" -- "$current")
      elif [[ "$prev_word" == "-v" && "${COMP_WORDS[COMP_CWORD - 2]}" =~ enabled$ ]]; then
        mapfile -t COMPREPLY < <(compgen -W "true false" -- "$current")
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
    tools)
      if [[ "$COMP_CWORD" -eq 2 ]]; then
        mapfile -t COMPREPLY < <(compgen -W "${tools_subcommands[*]}" -- "$current")
      else
        case "${COMP_WORDS[2]}" in
        igpu)
          if [[ "$COMP_CWORD" -eq 3 ]]; then
            mapfile -t COMPREPLY < <(compgen -W "${igpu_ops[*]}" -- "$current")
          fi
          ;;
        kernel)
          if [[ "$COMP_CWORD" -eq 3 ]]; then
            mapfile -t COMPREPLY < <(compgen -W "${kernel_ops[*]}" -- "$current")
          fi
          ;;
        quota)
          if [[ "$COMP_CWORD" -eq 3 ]]; then
            mapfile -t COMPREPLY < <(compgen -W "${quota_ops[*]}" -- "$current")
          elif [[ "${COMP_WORDS[3]}" == "set" && "$COMP_CWORD" -eq 4 ]]; then
            mapfile -t COMPREPLY < <(compgen -W "${users[*]}" -- "$current")
          elif [[ "${COMP_WORDS[3]}" == "set" && "$COMP_CWORD" -eq 5 ]]; then
            mapfile -t COMPREPLY < <(compgen -W "max 100MB 500MB 1GB 10GB 100GB 1TB 10TB" -- "$current")
          fi
          ;;
        esac
      fi
      ;;
    *)
      mapfile -t COMPREPLY < <(compgen -W "${commands[*]}" -- "$current")
      ;;
    esac
  }
  complete -F _zen zen
fi
