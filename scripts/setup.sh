#!/bin/bash

appilication_server_IP="$APPLICATION_SERVER_IP" # <----$APPLICATION_SERVER_IP is set within .bashrc on the webserver as an environment variable
download_path="/home/ubuntu/start_app.sh"
login_name="ubuntu"
ssh_key="/home/ubuntu/.ssh/AppWL4.pem"
script_url="https://raw.githubusercontent.com/jonwang22/microblog_VPC_deployment/refs/heads/main/scripts/start_app.sh"
start_script="source $download_path"

# SSHing into AppServer
ssh -i "$ssh_key" "$login_name@$application_server_IP" << EOF
    curl -L -o $download_path $script_url && $start_script
EOF
