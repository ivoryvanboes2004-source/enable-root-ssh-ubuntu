#!/usr/bin/env bash
set -euo pipefail

log(){ echo -e "\n[+] $*"; }
warn(){ echo -e "\n[!] $*" >&2; }
die(){ warn "$*"; exit 1; }

[[ "${EUID:-$(id -u)}" -eq 0 ]] || die "Run as root (sudo -i)."

SSHD_CONFIG="/etc/ssh/sshd_config"

# --- Set root password (user chooses) ---
log "Set ROOT password (you will type it twice)."
read -rsp "New root password: " ROOT_PW; echo
read -rsp "Repeat root password: " ROOT_PW2; echo

[[ -n "${ROOT_PW}" ]] || die "Password cannot be empty."
[[ "${ROOT_PW}" == "${ROOT_PW2}" ]] || die "Passwords do not match."
unset ROOT_PW2

echo "root:${ROOT_PW}" | chpasswd
unset ROOT_PW
log "Root password set."

# --- Enable root SSH + password auth ---
log "Updating SSH config: PermitRootLogin yes + PasswordAuthentication yes"

# PermitRootLogin
if grep -qE '^\s*#?\s*PermitRootLogin\s+' "$SSHD_CONFIG"; then
  sed -i -E 's/^\s*#?\s*PermitRootLogin\s+.*/PermitRootLogin yes/' "$SSHD_CONFIG"
else
  echo "PermitRootLogin yes" >> "$SSHD_CONFIG"
fi

# PasswordAuthentication
if grep -qE '^\s*#?\s*PasswordAuthentication\s+' "$SSHD_CONFIG"; then
  sed -i -E 's/^\s*#?\s*PasswordAuthentication\s+.*/PasswordAuthentication yes/' "$SSHD_CONFIG"
else
  echo "PasswordAuthentication yes" >> "$SSHD_CONFIG"
fi

# Restart SSH service
log "Restarting SSH service..."
if systemctl list-units --type=service --all | grep -qE '^sshd\.service'; then
  systemctl restart sshd
else
  systemctl restart ssh
fi

# --- Remove all "normal" users except root ---
log "Finding normal users (UID >= 1000) to remove (excluding root)..."
MAPFILE -t USERS_TO_REMOVE < <(awk -F: '($3>=1000)&&($1!="root") {print $1}' /etc/passwd)

if [[ ${#USERS_TO_REMOVE[@]} -eq 0 ]]; then
  log "No normal users found to remove."
else
  echo "[!] The following users will be removed (UID>=1000):"
  printf ' - %s\n' "${USERS_TO_REMOVE[@]}"
  echo
  read -r -p "Type YES to confirm removal of these users: " CONFIRM
  [[ "$CONFIRM" == "YES" ]] || die "Aborted."

  for u in "${USERS_TO_REMOVE[@]}"; do
    log "Removing user: $u"
    # -r removes home + mail spool
    userdel -r "$u" || warn "Failed to remove $u (maybe logged in / busy)."
  done
fi

# Optional reboot
echo
read -r -p "Reboot now? (y/n): " RB
if [[ "${RB,,}" == "y" ]]; then
  log "Rebooting..."
  reboot
fi

log "Done."
