#!/bin/bash 

set -e 

MYSQL_SERVER_IP="192.168.245.130"  
DB_NAME="ProjectDB"
READ_ONLY_USER="readonly_user"
READ_ONLY_PASSWORD="Readonly@1234"
READ_WRITE_USER="readwrite_user"
READ_WRITE_PASSWORD="Readwrite@1234"

 
echo "Installing MySQL client"
sudo apt update -y
sudo apt install mysql-client -y


echo "Client script completed."




