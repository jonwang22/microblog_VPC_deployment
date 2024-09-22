#!/bin/bash

application_server_IP="10.0.5.221"

# SSHing into AppServer
ssh -i .ssh/AppWL4.pem ubuntu@10.0.5.221 'source /home/ubuntu/start_app.sh' 
