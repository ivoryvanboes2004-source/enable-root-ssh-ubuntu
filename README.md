# Enable Root SSH + Remove All Users (Except Root)

This script:

- Forces you to set a new root password
- Enables root SSH login
- Enables password authentication
- Restarts the SSH service
- Removes all normal users (UID ≥ 1000) except root
- Optional reboot

⚠️ WARNING  
This will delete all regular users on the system.  
Only run this if you understand the consequences.

---

## What it does

1. Prompts you to choose a root password  
2. Sets:
   - `PermitRootLogin yes`
   - `PasswordAuthentication yes`
3. Restarts SSH
4. Deletes all non-system users (UID ≥ 1000)
5. Optional reboot

---

## Usage

```bash
curl -fsSL https://raw.githubusercontent.com/ivoryvanboes2004-source/enable-root-ssh-ubuntu/refs/heads/main/enable-root-ssh.sh -o enable-root.sh
chmod +x enable-root.sh
sudo ./enable-root.sh
