#!/bin/bash
set -euo pipefail

PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
  echo "Run this installer as root (sudo)."
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_DIR="$SCRIPT_DIR/scripts"

required_templates=(
  "$TEMPLATE_DIR/hytale-start.sh"
  "$TEMPLATE_DIR/hytale-stop.sh"
  "$TEMPLATE_DIR/auto-update.sh"
  "$TEMPLATE_DIR/hytale.service"
)

for template in "${required_templates[@]}"; do
  if [[ ! -f "$template" ]]; then
    echo "Missing template: $template"
    exit 1
  fi
done

detect_pkg_manager() {
  if command -v apt-get >/dev/null 2>&1; then
    echo "apt-get"
    return 0
  fi
  if command -v dnf >/dev/null 2>&1; then
    echo "dnf"
    return 0
  fi
  if command -v yum >/dev/null 2>&1; then
    echo "yum"
    return 0
  fi
  if command -v zypper >/dev/null 2>&1; then
    echo "zypper"
    return 0
  fi
  if command -v pacman >/dev/null 2>&1; then
    echo "pacman"
    return 0
  fi
  if command -v apk >/dev/null 2>&1; then
    echo "apk"
    return 0
  fi
  return 1
}

PKG_MANAGER="$(detect_pkg_manager || true)"

install_packages() {
  local packages=("$@")

  case "$PKG_MANAGER" in
    apt-get)
      export DEBIAN_FRONTEND=noninteractive
      apt-get update
      apt-get install -y --no-install-recommends "${packages[@]}"
      ;;
    dnf)
      dnf install -y "${packages[@]}"
      ;;
    yum)
      yum install -y "${packages[@]}"
      ;;
    zypper)
      zypper --non-interactive install -y "${packages[@]}"
      ;;
    pacman)
      pacman -Sy --noconfirm "${packages[@]}"
      ;;
    apk)
      apk add --no-cache "${packages[@]}"
      ;;
    *)
      echo "No supported package manager found for automatic install."
      return 1
      ;;
  esac
}

pkg_for_command() {
  local cmd="$1"

  case "$PKG_MANAGER" in
    apt-get)
      case "$cmd" in
        screen) echo "screen" ;;
        unzip) echo "unzip" ;;
        flock) echo "util-linux" ;;
        systemctl) echo "systemd" ;;
        crontab) echo "cron" ;;
        *) return 1 ;;
      esac
      ;;
    dnf|yum)
      case "$cmd" in
        screen) echo "screen" ;;
        unzip) echo "unzip" ;;
        flock) echo "util-linux" ;;
        systemctl) echo "systemd" ;;
        crontab) echo "cronie" ;;
        *) return 1 ;;
      esac
      ;;
    zypper)
      case "$cmd" in
        screen) echo "screen" ;;
        unzip) echo "unzip" ;;
        flock) echo "util-linux" ;;
        systemctl) echo "systemd" ;;
        crontab) echo "cron" ;;
        *) return 1 ;;
      esac
      ;;
    pacman)
      case "$cmd" in
        screen) echo "screen" ;;
        unzip) echo "unzip" ;;
        flock) echo "util-linux" ;;
        systemctl) echo "systemd" ;;
        crontab) echo "cronie" ;;
        *) return 1 ;;
      esac
      ;;
    apk)
      case "$cmd" in
        screen) echo "screen" ;;
        unzip) echo "unzip" ;;
        flock) echo "util-linux" ;;
        crontab) echo "dcron" ;;
        *) return 1 ;;
      esac
      ;;
    *)
      return 1
      ;;
  esac
}

ensure_dependencies() {
  local missing=()
  local packages=()
  local cmd pkg existing found

  for cmd in "$@"; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      missing+=("$cmd")
    fi
  done

  if [[ ${#missing[@]} -eq 0 ]]; then
    return 0
  fi

  if [[ -z "${PKG_MANAGER:-}" ]]; then
    echo "Missing required commands: ${missing[*]}"
    echo "No supported package manager found. Install dependencies manually and rerun."
    exit 1
  fi

  for cmd in "${missing[@]}"; do
    pkg="$(pkg_for_command "$cmd" || true)"
    if [[ -z "$pkg" ]]; then
      echo "Missing required command '$cmd' and no package mapping for '$PKG_MANAGER'."
      exit 1
    fi

    found=0
    for existing in "${packages[@]}"; do
      if [[ "$existing" == "$pkg" ]]; then
        found=1
        break
      fi
    done
    if [[ $found -eq 0 ]]; then
      packages+=("$pkg")
    fi
  done

  echo "Installing missing dependencies: ${packages[*]}"
  install_packages "${packages[@]}"

  for cmd in "${missing[@]}"; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      echo "Dependency installation did not provide required command: $cmd"
      exit 1
    fi
  done
}

prompt_default() {
  local var_name="$1"
  local prompt="$2"
  local default="$3"
  local input

  read -r -p "$prompt [$default]: " input
  input="${input:-$default}"
  printf -v "$var_name" "%s" "$input"
}

confirm() {
  local prompt="$1"
  local default="${2:-Y}"
  local answer

  if [[ "$default" == "Y" ]]; then
    read -r -p "$prompt [Y/n]: " answer
    [[ -z "$answer" || "$answer" =~ ^[Yy]$ ]]
  else
    read -r -p "$prompt [y/N]: " answer
    [[ "$answer" =~ ^[Yy]$ ]]
  fi
}

escape_sed_replacement() {
  printf '%s' "$1" | sed -e 's/[\/&|]/\\&/g'
}

render_template() {
  local src="$1"
  local dst="$2"
  local owner="$3"
  local group="$4"
  local mode="$5"
  local tmp

  tmp="$(mktemp)"
  sed \
    -e "s|__SERVICE_NAME__|$(escape_sed_replacement "$SERVICE_NAME")|g" \
    -e "s|__SCREEN_SESSION__|$(escape_sed_replacement "$SCREEN_SESSION")|g" \
    -e "s|__USER_NAME__|$(escape_sed_replacement "$USER_NAME")|g" \
    -e "s|__GROUP_NAME__|$(escape_sed_replacement "$GROUP_NAME")|g" \
    -e "s|__HOME_DIR__|$(escape_sed_replacement "$H_DIR")|g" \
    "$src" > "$tmp"

  install -o "$owner" -g "$group" -m "$mode" "$tmp" "$dst"
  rm -f "$tmp"
}

echo "Hytale service installer"
echo

prompt_default SERVICE_NAME "Systemd service name" "hytale"
prompt_default USER_NAME "Linux user that runs Hytale" "hytale"
prompt_default GROUP_NAME "Linux group for that user" "$USER_NAME"
prompt_default H_DIR "Hytale home directory" "/home/$USER_NAME"
prompt_default SCREEN_SESSION "screen session name" "$SERVICE_NAME"
prompt_default CRON_SCHEDULE "Auto-update cron schedule" "0 6,14,22 * * *"
prompt_default UPDATE_LOG "Auto-update log file" "/var/log/${SERVICE_NAME}-update.log"

echo
echo "Validating environment..."

if ! id "$USER_NAME" >/dev/null 2>&1; then
  echo "User does not exist: $USER_NAME"
  exit 1
fi

if command -v getent >/dev/null 2>&1; then
  if ! getent group "$GROUP_NAME" >/dev/null 2>&1; then
    echo "Group does not exist: $GROUP_NAME"
    exit 1
  fi
elif ! grep -Eq "^${GROUP_NAME}:" /etc/group; then
  echo "Group does not exist: $GROUP_NAME"
  exit 1
fi

ensure_dependencies screen unzip flock systemctl

if [[ ! -d "$H_DIR" ]]; then
  echo "Creating $H_DIR ..."
  install -d -o "$USER_NAME" -g "$GROUP_NAME" -m 0750 "$H_DIR"
fi

if [[ ! -x "$H_DIR/hytale-downloader-linux-amd64" ]]; then
  echo "Warning: $H_DIR/hytale-downloader-linux-amd64 is missing or not executable."
  echo "The server can run, but auto-update will fail until downloader is installed."
fi

echo "Installing runtime scripts into $H_DIR ..."
render_template "$TEMPLATE_DIR/hytale-start.sh" "$H_DIR/hytale-start.sh" "$USER_NAME" "$GROUP_NAME" 0750
render_template "$TEMPLATE_DIR/hytale-stop.sh" "$H_DIR/hytale-stop.sh" "$USER_NAME" "$GROUP_NAME" 0750
render_template "$TEMPLATE_DIR/auto-update.sh" "$H_DIR/auto-update.sh" "$USER_NAME" "$GROUP_NAME" 0750

if [[ ! -f "$H_DIR/version_info.txt" ]]; then
  install -o "$USER_NAME" -g "$GROUP_NAME" -m 0640 /dev/null "$H_DIR/version_info.txt"
fi

SERVICE_DEST="/etc/systemd/system/${SERVICE_NAME}.service"
echo "Installing systemd unit to $SERVICE_DEST ..."
render_template "$TEMPLATE_DIR/hytale.service" "$SERVICE_DEST" root root 0644

echo "Reloading and enabling service ..."
systemctl daemon-reload
systemctl enable "$SERVICE_NAME"

if confirm "Install root cron entry for auto-update?" "Y"; then
  ensure_dependencies crontab
  CRON_ENTRY="$CRON_SCHEDULE $H_DIR/auto-update.sh >> $UPDATE_LOG 2>&1"
  EXISTING_CRON="$(crontab -l 2>/dev/null || true)"
  if printf '%s\n' "$EXISTING_CRON" | grep -Fqx "$CRON_ENTRY"; then
    echo "Cron entry already present."
  else
    if [[ -n "$EXISTING_CRON" ]]; then
      printf '%s\n%s\n' "$EXISTING_CRON" "$CRON_ENTRY" | crontab -
    else
      printf '%s\n' "$CRON_ENTRY" | crontab -
    fi
    echo "Cron entry installed."
  fi
fi

if confirm "Start (or restart) ${SERVICE_NAME} now?" "Y"; then
  systemctl restart "$SERVICE_NAME"
fi

echo
echo "Installation complete."
echo "Service: ${SERVICE_NAME}"
echo "Home dir: ${H_DIR}"
echo "Installed scripts:"
echo "  - ${H_DIR}/hytale-start.sh"
echo "  - ${H_DIR}/hytale-stop.sh"
echo "  - ${H_DIR}/auto-update.sh"
echo "Unit file: ${SERVICE_DEST}"
