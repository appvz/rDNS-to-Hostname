#!/bin/bash

# Script: set_rdns_hostname.sh
# Description: Get rDNS of public IP and set it as hostname
# @copyright Copyright (c) AppVZ Online
# license https://appvz.com, https://github.com/appvz/rDNS-to-Hostname

# Check root privileges
if [ "$EUID" -ne 0 ]; then
    echo "⚠️  Please run this script as root: sudo $0"
    exit 1
fi

# Function to check internet connection
check_internet() {
    if ! ping -c 1 -W 3 google.com >/dev/null 2>&1; then
        echo "❌ No internet connection!"
        exit 1
    fi
}

# Function to get public IP
get_public_ip() {
    IP=$(curl -s --connect-timeout 5 ifconfig.me)
    if [ -z "$IP" ]; then
        echo "❌ Cannot get public IP"
        exit 1
    fi
    echo "$IP"
}

# Function to get rDNS
get_rdns() {
    local ip="$1"
    
    # Use dig to get rDNS
    RDNS=$(dig +short -x "$ip" 2>/dev/null | head -n1)
    
    if [ -z "$RDNS" ]; then
        echo "❌ No rDNS record found for IP $ip"
        exit 1
    fi
    
    # Remove trailing dot if present
    RDNS=${RDNS%.}
    echo "$RDNS"
}

# Function to validate hostname
validate_hostname() {
    local hostname="$1"
    
    # Check length
    if [ ${#hostname} -gt 253 ]; then
        echo "❌ Hostname too long (max 253 characters)"
        return 1
    fi
    
    # Check valid characters
    if ! echo "$hostname" | grep -Eq '^[a-zA-Z0-9.-]+$'; then
        echo "❌ Hostname contains invalid characters"
        return 1
    fi
    
    # Check doesn't start/end with hyphen
    if echo "$hostname" | grep -Eq '^-|-$'; then
        echo "❌ Hostname cannot start or end with hyphen"
        return 1
    fi
    
    return 0
}

# Function to set hostname
set_hostname() {
    local new_hostname="$1"
    
    echo "⚙️  Setting hostname to: $new_hostname"
    
    # Set temporary hostname
    hostnamectl set-hostname "$new_hostname"
    
    # Update /etc/hostname file
    echo "$new_hostname" > /etc/hostname
    
    # Update /etc/hosts (keep existing entries, only modify localhost)
    if grep -q "127.0.0.1.*localhost" /etc/hosts; then
        sed -i "s/127.0.0.1.*localhost/127.0.0.1 localhost $new_hostname/" /etc/hosts
    else
        echo "127.0.0.1 localhost $new_hostname" >> /etc/hosts
    fi
    
    # Add IPv6 entry
    if grep -q "::1.*localhost" /etc/hosts; then
        sed -i "s/::1.*localhost/::1 localhost $new_hostname ip6-localhost ip6-loopback/" /etc/hosts
    fi
}

# Main execution
main() {
    echo "🚀 Starting script to set hostname from rDNS..."
    
    # Check connection
    check_internet
    
    # Get public IP
    IP=$(get_public_ip)
    
    # Get rDNS
    RDNS=$(get_rdns "$IP")
    
    # Validate hostname
    if ! validate_hostname "$RDNS"; then
        echo "❌ rDNS '$RDNS' is not suitable for hostname"
        exit 1
    fi
    
    # Display information
    echo ""
    echo "📋 UPDATE INFORMATION:"
    echo "   IP: $IP"
    echo "   rDNS: $RDNS"
    echo "   Old hostname: $(hostname)"
    echo ""
    
    # Confirmation
    read -p "⚠️  Do you want to set hostname to '$RDNS'? (y/N): " confirm
    
    if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
        echo "❌ Operation cancelled"
        exit 0
    fi
    
    # Set hostname
    set_hostname "$RDNS"
    
    echo ""
    echo "✅ COMPLETED!"
    echo "   New hostname: $(hostname)"
    echo ""
    echo "📝 Note:"
    echo "   - You may need to restart terminal or system"
    echo "   - Check with command: hostnamectl status"
}

# Run main function
main