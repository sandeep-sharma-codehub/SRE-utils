#####################################################
# Author: Sandeep Sharma
# Script: jenkins_installation.sh
# Description: This script installs Jenkins on Ubuntu
# Usage: ./jenkins_installation.sh
#####################################################
#!/bin/bash

# Function for error handling
handle_error() {
    echo "Error: $1"
    exit 1
}

# Update system packages
echo "Updating system packages..."
sudo apt-get update -y || handle_error "Failed to update packages"
#sudo apt upgrade -y || handle_error "Failed to upgrade packages"

# Install Java
echo "Installing OpenJDK 11..."
sudo apt install openjdk-11-jdk -y || handle_error "Failed to install Java"

# Verify Java installation
echo "Verifying Java installation..."
java -version || handle_error "Java installation verification failed"

# Add Jenkins repository key
echo "Adding Jenkins repository key..."
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee \
/usr/share/keyrings/jenkins-keyring.asc > /dev/null || handle_error "Failed to add Jenkins repository key"

# Add Jenkins repository
echo "Adding Jenkins repository..."
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
/etc/apt/sources.list.d/jenkins.list > /dev/null || handle_error "Failed to add Jenkins repository"

# Update package lists
echo "Updating package lists..."
sudo apt update -y || handle_error "Failed to update package lists after adding Jenkins repository"

# Install Jenkins
echo "Installing Jenkins..."
sudo apt install jenkins -y || handle_error "Failed to install Jenkins"

# Start Jenkins service
echo "Starting Jenkins service..."
sudo systemctl start jenkins || handle_error "Failed to start Jenkins service"

# Enable Jenkins to start on boot
echo "Enabling Jenkins to start on boot..."
sudo systemctl enable jenkins || handle_error "Failed to enable Jenkins service"

# Verify Jenkins is running
echo "Verifying Jenkins service status..."
sudo systemctl status jenkins --no-pager || handle_error "Jenkins service is not running properly"

echo "Jenkins installation completed successfully!"
echo "You can access Jenkins at: http://$(hostname -I | awk '{print $1}'):8080"
echo "Initial admin password can be found with: sudo cat /var/lib/jenkins/secrets/initialAdminPassword"



