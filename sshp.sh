#!/bin/bash

CONFIG_FILE=~/.sshp/sshp.yaml
EDITOR=${EDITOR:-vi}
CMD_NAME=$(basename "$0")
VERSION=20250715.0926

create_config() {
  mkdir -p ~/.sshp
  if [ ! -f "$CONFIG_FILE" ]; then
    cat > "$CONFIG_FILE" << EOF
group1:
  name: "group1" # group name can be empty
  default:
    port: 22
    user: root
    password: 1qaz@WSX
  list:
    127.0.0.1:
      host: 127.0.0.1
      port: 22
      user: root
      password: 1qaz@WSX
EOF
    echo "Created configuration file: $CONFIG_FILE"
  fi
}

get_groups() {
  yq eval 'keys | .[]' "$CONFIG_FILE"
}
get_hosts() {
  local group=$1
  yq eval ".[\"$group\"].list | keys | .[]" "$CONFIG_FILE"
}

get_config() {
  local path=$1
  local result=$(yq eval -r ".$path" "$CONFIG_FILE" 2>/dev/null || echo "")
  
  if [ "$result" = "null" ] || [ -z "$result" ]; then
    echo ""
  else
    echo "$result"
  fi
}

merge_config() {
  local group=$1
  local host=$2
  
  local default_port=$(get_config "$group.default.port")
  local default_user=$(get_config "$group.default.user")
  local default_password=$(get_config "$group.default.password")
  
  local host_port=$(get_config "$group.list.[\"$host\"].port")
  [ -z "$host_port" ] && host_port="$default_port"
  
  local host_user=$(get_config "$group.list.[\"$host\"].user")
  [ -z "$host_user" ] && host_user="$default_user"
  
  local host_password=$(get_config "$group.list.[\"$host\"].password")
  [ -z "$host_password" ] && host_password="$default_password"
  
  local host_address=$(get_config "$group.list.[\"$host\"].host")
  [ -z "$host_address" ] && host_address=$host

  echo "$host_address $host_port $host_user $host_password"
}

show_groups() {
  echo "List of available groups:"
  get_groups | while read -r group; do
    local group_name=$(get_group_name "$group")
    if [ -z "$group_name" ]; then
      echo "$group"
    else
      echo "$group [$group_name]"
    fi
  done
}

get_group_name() {
  local group=$1
  local result=$(yq eval ".[\"$group\"].name" "$CONFIG_FILE" 2>/dev/null || echo "")
  if [ "$result" = "null" ] || [ -z "$result" ]; then
    echo ""
  else
    echo "$result"
  fi
}

show_hosts() {
  local group=$1
  if ! get_groups | grep -q "^$group$"; then
    echo "Error: Group '$group' does not exist"
    exit 1
  fi
  
  echo "Host list for group '$group':"
  get_hosts "$group" | while read -r host; do
    echo "  - $host"
  done
  echo "connect to host command:"
  get_hosts "$group" | while read -r host; do
    echo "$CMD_NAME $host"
  done
}

show_all() {
  echo "List of available hosts:"
  get_groups | while read -r group; do
    local group_name=$(get_group_name "$group")
    if [ -z "$group_name" ]; then
      echo "$group"
    else
      echo "$group [$group_name]"
    fi
    
    local host_list=()
    while read -r host; do
      host_list+=("$host")
    done < <(get_hosts "$group")
    
    if [ ${#host_list[@]} -gt 0 ]; then
      local output="  ${host_list[0]}"
      for ((i=1; i<${#host_list[@]}; i++)); do
        output="$output    ${host_list[$i]}"
      done
      echo "$output"
    fi
  done
}

connect_host() {
  local host_name=$1
  local found=false
  local found_group=""
  local found_host=""
  
  for group in $(get_groups); do
    for h in $(get_hosts "$group"); do
      if [ "$h" = "$host_name" ]; then
        found=true
        found_group=$group
        found_host=$h
        break 2
      fi
    done
  done
  
  if [ "$found" != "true" ]; then
    echo "Error: Host '$host_name' not found"
    exit 1
  fi
  
  # merge_config "$found_group" "$found_host"
  local config=$(merge_config "$found_group" "$found_host")
  local host_address=$(echo "$config" | awk '{print $1}')
  local port=$(echo "$config" | awk '{print $2}')
  local user=$(echo "$config" | awk '{print $3}')
  local password=$(echo "$config" | awk '{print $4}')
  
  if [ -z "$host_address" ]; then
    echo "Error: Host address not configured"
    exit 1
  fi
  
  if [ -z "$user" ]; then
    echo "Error: User not configured"
    exit 1
  fi
  
  if [ -z "$password" ]; then
    echo "Error: Password not configured"
    exit 1
  fi
  
  echo "Connecting to $user@$host_address:$port..."
  # echo "sshpass -p \"$password\" ssh -o StrictHostKeyChecking=no \"$user@$host_address\" -p \"$port\""
  sshpass -p "$password" ssh -o StrictHostKeyChecking=no "$user@$host_address" -p "$port"
}
edit_config() {
  create_config
  
  if [ -n "$EDITOR" ]; then
    $EDITOR "$CONFIG_FILE"
  else
    echo "Please set EDITOR environment variable to use this feature"
    echo "For example: export EDITOR=vim"
  fi
}

main() {
  if [ -z "$1" ]; then
    $0 -h
    exit 1
  fi
  create_config
  
  case "$1" in
    group)
      if [ -n "$2" ]; then
        show_hosts "$2"
      else
        show_groups
      fi
      ;;
    edit)
      if [ "$2" = "config" ]; then
        edit_config
      else
        echo "Unknown command: $2"
        exit 1
      fi
      ;;
    -h | --help)
      echo "SSH configuration management tool"
      echo "Usage:"
      echo "  $CMD_NAME group                - Show all groups"
      echo "  $CMD_NAME group <group name>   - Show hosts in a specific group"
      echo "  $CMD_NAME edit config          - Edit configuration file"
      echo "  $CMD_NAME -h | --help          - Show help information"
      echo "  $CMD_NAME <hostname>           - Connect to a specific host"
      echo "  $CMD_NAME all                  - Show all hosts"
      echo "  $CMD_NAME version              - Show version information"
      exit 1
      ;;
    all)
      show_all
      ;;
    version)
      echo "$VERSION"
      exit 0
      ;;
    *)
      connect_host "$1"
      ;;
  esac
}

if ! command -v yq &> /dev/null; then
  echo "Error: yq tool is required"
  echo "Please install yq: https://github.com/mikefarah/yq"
  exit 1
fi

main "$@"  
