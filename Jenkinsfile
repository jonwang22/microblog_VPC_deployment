pipeline {
  agent any
    stages {
        stage ('Build') {
            steps {
                sh '''#!/bin/bash
                python3.9 -m venv venv
		source venv/bin/activate
		pip install --upgrade pip
		pip install -r requirements.txt
		pip install gunicorn pymysql cryptography
		export FLASK_APP=microblog.py
		flask translate compile
		flask db upgrade
                '''
            }
        }
        stage ('Test') {
            steps {
                sh '''#!/bin/bash
                source venv/bin/activate
                py.test ./tests/unit/ --verbose --junit-xml test-reports/results.xml
                '''
            }
            post {
                always {
                    junit 'test-reports/results.xml'
                }
            }
        }
      stage ('OWASP FS SCAN') {
            steps {
                dependencyCheck additionalArguments: '--scan ./ --disableYarnAudit --disableNodeAudit', odcInstallation: 'DP-Check'
                dependencyCheckPublisher pattern: '**/dependency-check-report.xml'
            }
        }
      stage ('Deploy') {
            steps {
                sh '''#!/bin/bash
		
		# Setting my variables
		webserver="10.0.2.152"
		file_path="/home/ubuntu/setup.sh"
		login_name="ubuntu"
		ssh_key="/home/ubuntu/.ssh/jenkinsauthkey"
		script_url="https://raw.githubusercontent.com/jonwang22/microblog_VPC_deployment/refs/heads/main/scripts/setup.sh"	
 		
		# SSHing and downloading setup script.
		ssh -i "$ssh_key" "$login_name@$webserver" "curl -L -o $file_path $script_url 2>/dev/null && chmod 755 $file_path && source $file_path"
		'''
            }
        }
    }
}
