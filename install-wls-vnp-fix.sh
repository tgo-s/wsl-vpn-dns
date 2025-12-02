
#!/bin/bash

# Create the vpn-dns.sh script that pulls DNS servers from Windows and feeds them
# into the smart-resolv script. The installed /bin/vpn-dns.sh will run at login via
# /etc/profile.d entry and write atomically to /etc/resolv.conf using sudo.

echo "Creating /bin/vpn-dns.sh..."
sudo tee /bin/vpn-dns.sh > /dev/null << 'EOF'
#!/bin/bash

set -euo pipefail

echo "Fetching DNS servers from Windows (this may take a few seconds)"

# Fetch DNS servers from Windows PowerShell. Output IPs one per line.
/mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe -Command '
$ErrorActionPreference="SilentlyContinue"
Get-NetAdapter -InterfaceDescription "Cisco AnyConnect*" | Get-DnsClientServerAddress | Select -ExpandProperty ServerAddresses
Get-NetAdapter | ?{-not ($_.InterfaceDescription -like "Cisco AnyConnect*") } | Get-DnsClientServerAddress | Select -ExpandProperty ServerAddresses
' | tr -d '\r' | awk '{print $1}' | sed '/^$/d' > /tmp/vpn-dns-ips

# Feed the IP list into smart-resolv to generate a resolv.conf to stdout
/tmp/smart-resolv.sh --stdout < /tmp/vpn-dns-ips > /tmp/new-resolv.conf

# Atomically move into place (requires sudo). Backup is created by smart-resolv.
if sudo mv /tmp/new-resolv.conf /etc/resolv.conf; then
    true
else
    echo "Failed to move /tmp/new-resolv.conf to /etc/resolv.conf. You may need to run this script with sudo."
    exit 1
fi

clear
EOF

# Make it executable
echo "Making /bin/vpn-dns.sh executable..."
sudo chmod +x /bin/vpn-dns.sh

# Add sudoers rule for convenience (NOPASSWD for this script only)
echo "Adding sudoers rule..."
echo "$(whoami) ALL=(ALL) NOPASSWD: /bin/vpn-dns.sh, /bin/mv, /bin/cp" | sudo tee /etc/sudoers.d/010-$(whoami)-vpn-dns

# Add to profile so it runs on login
echo "Adding script to /etc/profile.d..."
echo "/bin/vpn-dns.sh" | sudo tee /etc/profile.d/vpn-dns.sh

echo "✅ Setup complete!"
