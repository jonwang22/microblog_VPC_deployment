#!/bin/bash

application_server_IP="$APPLICATION_SERVER_IP" # <----$APPLICATION_SERVER_IP is set within .bashrc on the webserver as an environment variable
download_path="/home/ubuntu/start_app.sh"
login_name="ubuntu"
ssh_key="/home/ubuntu/.ssh/AppWL4.pem"
script_url="https://raw.githubusercontent.com/jonwang22/microblog_VPC_deployment/refs/heads/main/scripts/start_app.sh"
start_script="source $download_path"

# SSHing into AppServer

# Trying to reduce output with this
ssh -i "$ssh_key" "$login_name@$application_server_IP" "curl -L -o $download_path $script_url 2>/dev/null && chmod 755 $download_path && $start_script && rm $download_path"


# Clean way to run commands via SSH. Issue with this is the SSH login terminal output shows up along with the output from the commands we want to run.
#ssh -i "$ssh_key" "$login_name@$application_server_IP" << EOF 2>/dev/null
#    curl -L -o $download_path $script_url 2>/dev/null && chmod 755 $download_path && $start_script && rm $download_path
#EOF
