#!/bin/bash

# Installing dependencies for Jenkins
sudo apt update && sudo apt install fontconfig openjdk-17-jre software-properties-common && sudo add-apt-repository ppa:deadsnakes/ppa && sudo apt install python3.9 python3.9-venv python3-pip

# Downloaded the Jenkins respository key. Added the key to the /usr/share/keyrings directory
sudo wget -O /usr/share/keyrings/jenkins-keyring.asc https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key

# Added Jenkins repo to sources list
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc]" https://pkg.jenkins.io/debian-stable binary/ | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null

# Downloaded all updates for packages again, installed Jenkins
sudo apt-get update
sudo apt-get install jenkins

# Started Jenkins and checked to make sure Jenkins is active and running with no issues
sudo systemctl start jenkins
sudo systemctl status jenkins

