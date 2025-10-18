# rDNS to Hostname
Change your server's hostname to rDNS of main IP

How to use:

Save the script to a file, e.g.: set_rdns_hostname.sh

Make it executable:

chmod +x set_rdns_hostname.sh

Run with root privileges:

sudo ./set_rdns_hostname.sh

After running the script, check with:

hostname

hostnamectl status

cat /etc/hostname

Important notes:

Script only works if your IP has a PTR record (rDNS).

Some cloud providers require PTR record configuration in their control panel.

Ensure the rDNS returns a valid domain name for hostname purposes.

