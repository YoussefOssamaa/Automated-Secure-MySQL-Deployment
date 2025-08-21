#!/bin/bash

set -e ##to exit on error


MYSQL_ROOT_PASSWORD="Root@1234"
DB_NAME="ProjectDB"
READ_ONLY_USER="readonly_user"
READ_ONLY_PASSWORD="Readonly@1234"
READ_WRITE_USER="readwrite_user"
READ_WRITE_PASSWORD="Readwrite@1234"


echo " Resetting and Configuring Network Adapters"

OLD_CONS=$(nmcli -t -f NAME connection show)
for con in $OLD_CONS; do
    echo "Deleting old connection: $con"
    sudo nmcli connection delete "$con" || true
done

sleep 2

IF_NAT=$(nmcli device | awk '/ethernet/ {print $1}' | head -n1)
IF_HOST=$(nmcli device | awk '/ethernet/ {print $1}' | tail -n1)

echo "Using $IF_NAT for NAT and $IF_HOST for Host-Only"

sudo nmcli connection add type ethernet ifname "$IF_NAT" con-name nat0
sudo nmcli connection add type ethernet ifname "$IF_HOST" con-name hostonly0

sudo nmcli connection up nat0
sudo nmcli connection up hostonly0

GATEWAY=$(nmcli -g IP4.GATEWAY device show "$IF_NAT" | head -n1)
if [ -n "$GATEWAY" ]; then
    sudo ip route del default || true
    sudo ip route add default via "$GATEWAY" dev "$IF_NAT"
    echo " Default route set via $GATEWAY on $IF_NAT"
else
    echo " Could not detect gateway on $IF_NAT"
fi

echo " Testing Internet..."
ping -c 3 8.8.8.8 || echo "Ping to 8.8.8.8 failed"




echo "INSTALLING MYSQL SERVER:"

sudo dnf install -y https://dev.mysql.com/get/mysql80-community-release-el9-1.noarch.rpm

echo "Importing the latest MySQL GPG key:"
sudo rpm --import https://repo.mysql.com/RPM-GPG-KEY-mysql-2023

sudo dnf clean all

if dnf module list mysql | grep -q mysql; then 
sudo dnf module reset mysql -y 
sudo dnf module disable mysql -y 
fi
sudo dnf install -y mysql-community-server

echo "Starting MySQL service:"
sudo systemctl enable mysqld
sudo systemctl start mysqld

if ! sudo systemctl is-active --quiet mysqld; then
    echo "Error: MySQL service is not running."
    exit 1
fi

echo "MYSQL SERVER INSTALLATION COMPLETED"

TEMP_PASS=$(sudo grep 'temporary password' /var/log/mysqld.log | tail -n 1 | awk '{print $NF}') 
if [ -z "$TEMP_PASS" ]; then
    echo "Error: Could not retrieve temporary password from /var/log/mysqld.log"
    exit 1
fi


echo "Checking if MySQL root password is already set..."
if mysqladmin -u root -p"$TEMP_PASS" status 2>/dev/null; then
    echo "Temporary password is valid, proceeding with secure installation."
else
    echo "Temporary password is invalid. Checking if root password is already set to $MYSQL_ROOT_PASSWORD..."
    if mysqladmin -u root -p"$MYSQL_ROOT_PASSWORD" status 2>/dev/null; then
        echo "Root password is already set to $MYSQL_ROOT_PASSWORD. Skipping secure installation."
        TEMP_PASS="$MYSQL_ROOT_PASSWORD"  
    else
        echo "Error: Unable to log in with temporary password or root password."
        exit 1
    fi
fi


mysql --connect-expired-password -u root -p"$TEMP_PASS" <<EOF
 
ALTER USER 'root'@'localhost' IDENTIFIED BY '$MYSQL_ROOT_PASSWORD';
DELETE FROM mysql.user WHERE User=''; 
DROP DATABASE IF EXISTS test;
FLUSH PRIVILEGES;
EOF


echo "Creating a new database: $DB_NAME"
sudo mysql -uroot -p"$MYSQL_ROOT_PASSWORD" <<EOF
CREATE DATABASE IF NOT EXISTS $DB_NAME;
CREATE USER IF NOT EXISTS '$READ_ONLY_USER'@'%' IDENTIFIED BY '$READ_ONLY_PASSWORD';
GRANT SELECT ON $DB_NAME.* TO '$READ_ONLY_USER'@'%';

CREATE USER IF NOT EXISTS '$READ_WRITE_USER'@'%' IDENTIFIED BY '$READ_WRITE_PASSWORD'; 
GRANT CREATE, SELECT, INSERT, UPDATE, DELETE ON $DB_NAME.* TO '$READ_WRITE_USER'@'%' ;   

FLUSH PRIVILEGES; 
EOF


sudo sed -i "s/^bind-address.*/bind-address = 0.0.0.0/" /etc/my.cnf.d/mysqld.cnf || echo "bind-address=0.0.0.0" | sudo tee -a /etc/my.cnf.d/mysqld.cnf


echo "Restarting MySQL service to apply changes:"
sudo systemctl restart mysqld

echo "adding port 3306 to firewall"
sudo firewall-cmd --permanent --add-port=3306/tcp 
sudo firewall-cmd --reload

echo "Installation and configuration of MySQL server completed successfully."


echo "Server script completed."
