#!/bin/bash

#Testing purposes

#echo "Hello World"
#export TEST="I'm creating a test environment variable"
#echo $TEST

#Setting up environment

#Checking if repo from GitHub exists on server.
if [[ ! -d "/home/ubuntu/microblog_VPC_deployment" ]]; then
	echo "Repo does not exist, cloning source code from Github..."
	git clone https://github.com/jonwang22/microblog_VPC_deployment.git
	cd /home/ubuntu/microblog_VPC_deployment
else
	echo "Repo exists, updating repo with latest commits..."
	cd /home/ubuntu/microblog_VPC_deployment
	git pull origin main

#Installing python and python related software for application
echo "Updating current installed packages..."
sudo apt update -y
echo "Installing font configs, java runtime env, and tools managing software sources..."
sudo apt install -y fontconfig openjdk-17-jre software-properties-common
echo "Installing Deadsnakes PPA Repo for Python..."
sudo add-apt-repository -y ppa:deadsnakes/ppa
echo "Install Python resources..."
sudo apt install -y python3.9
sudo apt install -y python3.9-venv
sudo apt install -y python3-pip

# Build application
#Checking if repo from GitHub exists on server.
if [[ ! -d "/home/ubuntu/microblog_VPC_deployment" ]]; then
        echo "Repo does not exist, cloning source code from Github..."
        git clone https://github.com/jonwang22/microblog_VPC_deployment.git
	echo "Cloned repo, navigating to repo..."
        cd /home/ubuntu/microblog_VPC_deployment
else
        echo "Repo exists, navigating to repo and updating with latest commits..."
        cd /home/ubuntu/microblog_VPC_deployment
        git pull origin main
fi

echo "Creating Python Virtual Environment..."
python3.9 -m venv venv
source venv/bin/activate

echo "Upgrading PIP..."
pip install --upgrade pip


echo "Installing all necessary application dependencies..."
pip install -r requirements.txt
pip install gunicorn pymysql cryptography

echo "Setting FLASK_APP application..."
export FLASK_APP=microblog.py

echo "Compiling source code..."
flask translate compile
flask db upgrade

echo "Starting application..."
gunicorn -b :5000 -w 4 microblog:app --daemon

echo "Application launched. You can now access the application from the web browser."
