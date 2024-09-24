#!/bin/bash

appserver="$1" # <----$APPLICATION_SERVER_IP is set as argument in Jenkinsfile
file_path="/home/ubuntu/start_app.sh"
repo_path="/home/ubuntu/microblog_VPC_deployment"
login_name="ubuntu"
ssh_key="/home/ubuntu/.ssh/AppWL4.pem"
script_url="https://raw.githubusercontent.com/jonwang22/microblog_VPC_deployment/refs/heads/main/scripts/start_app.sh"

# SSHing into AppServer and grabbing resources to start app.
ssh -i "$ssh_key" "$login_name@$appserver" << EOF
if  pgrep -f gunicorn > /dev/null; then
        echo "Gunicorn is running, cleaning environment."
        pkill gunicorn
	echo "Gunicorn process killed."
	echo "Downloading setup script and executing script..."
        echo "$file_path"
        echo "$script_url"
	curl -L -o $file_path $script_url 2>/dev/null
else
        echo "Gunicorn is currently not running. Environment is ready."
	echo "Downloading setup script and executing script..."
	echo "$file_path"
	echo "$script_url"
	curl -L -o $file_path $script_url 2>/dev/null
fi
EOF
