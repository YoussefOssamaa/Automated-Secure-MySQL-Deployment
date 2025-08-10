# Automated-Secure-MySQL-Deployment
Automated Secure MySQL Deployment (Bash Scripting, MySQL, RHEL, Ubuntu). Designed and implemented a fully automated setup for a secure remote MySQL database environment.
Automated Secure MySQL Deployment with Shell Scripting
This project simulates a real-world environment for deploying and managing a secure remote MySQL database using Bash scripting and virtual machines. The goal was to create a repeatable, scalable, and secure setup for database server installation, configuration, and client connectivity.

Overview
The system consists of:

Red Hat Enterprise Linux 9 VM – Hosts the MySQL 8+ database server.

Ubuntu 22.04 VM – Acts as the remote client for testing and verification.

Two Bash scripts were developed:

setup_mysql_server.sh – Automates installation and configuration of the MySQL server, creation of a dedicated database, setup of read-only and read-write user roles, configuration of firewall rules, and enabling secure remote access.

setup_mysql_client.sh – Configures the client machine for remote access, installs necessary MySQL client packages, and tests database connectivity and privileges.

Key Features
Automated installation and configuration of MySQL server and client without manual intervention.

Creation of role-based database accounts for controlled access (read-only / read-write).

Firewall configuration and MySQL settings adjustments to allow remote access securely.

Privilege testing from the client machine with both SELECT and INSERT operations.

Modular scripts designed for reusability in similar environments.

Technologies Used
Languages & Tools: Bash scripting, MySQL, nmcli, iptables/firewalld, SSH

Operating Systems: RHEL 9, Ubuntu 22.04

Virtualization: VMware / VirtualBox

Networking: NAT & Host-only adapters
