# wsl-vpn-dns
Fix the problem of accessing internet on WSL when using VPN

## Re-enable auto generation of resolv.conf (if disabled)
by commented the disable with #
>sudo nano /etc/wsl.conf

>bash
>#[network]
>#generateResolvConf = false
