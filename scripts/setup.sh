#!/bin/bash

application_server_IP="$APPLICATION_SERVER_IP" # <----$APPLICATION_SERVER_IP is set within .bashrc on the webserver as an environment variable
file_path="/home/ubuntu/start_app.sh"
repo_path="/home/ubuntu/microblog_VPC_deployment"
login_name="ubuntu"
ssh_key="/home/ubuntu/.ssh/AppWL4.pem"
script_url="https://raw.githubusercontent.com/jonwang22/microblog_VPC_deployment/refs/heads/main/scripts/start_app.sh"
start_script="source $file_path"

# SSHing into AppServer

# Trying to reduce output with this
ssh -i "$ssh_key" "$login_name@$application_server_IP" << EOF 2>/dev/null
if [[ -d "$repo_path" ]] && [[ -f "$file_path" ]]; then
	echo "Repository and File already exist."
	echo "Deleting existing local repo and file."
	rm -rf "$repo_path"
	rm "$file_path"
	if  pgrep -f gunicorn > /dev/null; then
		echo "Gunicorn is running, cleaning environment."
		pkill gunicorn
		curl -L -o "$file_path" "$script_url" 2>/dev/null && chmod 755 "$file_path" && "$start_script"
	else
		echo "Gunicorn is currently not running. Environment is ready."
		curl -L -o "$file_path $script_url" 2>/dev/null && chmod 755 "$file_path" && "$start_script"
	fi
else
	curl -L -o "$file_path" "$script_url" 2>/dev/null && chmod 755 "$file_path" && "$start_script"
fi
EOF

# Clean way to run commands via SSH. Issue with this is the SSH login terminal output shows up along with the output from the commands we want to run.
#ssh -i "$ssh_key" "$login_name@$application_server_IP" << EOF 2>/dev/null
#    curl -L -o $download_path $script_url 2>/dev/null && chmod 755 $download_path && $start_script && rm $download_path
#EOF
