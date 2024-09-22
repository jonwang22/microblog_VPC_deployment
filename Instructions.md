# Kura Labs Cohort 5- Deployment Workload 4


---



## Provisioning Server Infrastructure:

Welcome to Deployment Workload 4! In Workload 3 We shifted to infrastucture provisioned by us and learned about what goes into deploying an application.  That was hardly an effective system though.  Let's build out our infrastructure a little more.

Be sure to document each step in the process and explain WHY each step is important to the pipeline.

## Instructions

1. Clone this repo to your GitHub account. IMPORTANT: Make sure that the repository name is "microblog_VPC_deployment"

2. In the AWS console, create a custom VPC with one availability zome, a public and a private subnet.  There should be a NAT Gateway in 1 AZ and no VPC endpoints.  DNS hostnames and DNS resolution should be selected.

3. Navigate to subnets and edit the settings of the public subet you created to auto assign public IPv4 addresses.

4. In the Default VPC, create an EC2 t3.medium called "Jenkins" and install Jenkins onto it.  

5. Create an EC2 t3.micro called "Web_Server" In the PUBLIC SUBNET of the Custom VPC, and create a security group with ports 22 and 80 open.  

6. Create an EC2 t3.micro called "Application_Server" in the PRIVATE SUBNET of the Custom VPC,  and create a security group with ports 22 and 5000 open. Make sure you create and save the key pair to your local machine.

7. SSH into the "Jenkins" server and run `ssh-keygen`. Copy the public key that was created and append it into the "authorized_keys" file in the Web Server. 

IMPORTANT: Test the connection by SSH'ing into the 'Web_Server' from the 'Jenkins' server.  This will also add the web server instance to the "list of known hosts"

Question: What does it mean to be a known host?

8. In the Web Server, install NginX and modify the "sites-enabled/default" file so that the "location" section reads as below:
```
location / {
proxy_pass http://<private_IP>:5000;
proxy_set_header Host $host;
proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
}
```
IMPORTANT: Be sure to replace `<private_IP>` with the private IP address of the application server. Run the command `sudo nginx -t` to verify. Restart NginX afterward.

9. Copy the key pair (.pem file) of the "Application_Server" to the "Web_Server".  How you choose to do this is up to you.  (Best practice would be to SCP from your local machine into the Jenkins server but if not, it is possible to nano a new file and copy/paste the contents of the .pem file into it.  MAKE SURE TO INCLUDE EVERYTHING FROM -----BEGIN RSA PRIVATE KEY----- to -----END RSA PRIVATE KEY----- including a new line afterwards if you chose this route)

IMPORTANT: Test the connection by SSH'ing into the "Application_Server" from the "Web_Server".

10. Create scripts.  2 scripts are required for this Workload and outlined below:

a) a "start_app.sh" script that will run on the application server that will set up the server so that has all of the dependencies that the application needs, clone the GH repository, install the application dependencies from the requirements.txt file as well as [gunicorn, pymysql, cryptography], set ENVIRONMENTAL Variables, flask commands, and finally the gunicorn command that will serve the application IN THE BACKGROUND

b) a "setup.sh" script that will run in the "Web_Server" that will SSH into the "Application_Server" to run the "start_app.sh" script.

(HINT: run the scripts with "source" to avoid issues)

Question: What is the difference between running scripts with the source command and running the scripts either by changing the permissions or by using the 'bash' interpreter?

IMPORTANT: Save these scripts in your GitHub Respository in a "scripts" folder.

11. Create a Jenkinsfile that will 'Build' the application, 'Test' the application by running a pytest (you can re-use the test from WL3 or challenge yourself to create a new one), run the OWASP dependency checker, and then "Deploy" the application by SSH'ing into the "Web_Server" to run "setup.sh" (which would then run "start_app.sh").

IMPORTANT/QUESTION/HINT: How do you get the scripts onto their respective servers if they are saved in the GitHub Repo?  Do you SECURE COPY the file from one server to the next in the pipeline? Do you C-opy URL the file first as a setup? How much of this process is manual vs. automated?

Question 2: In WL3, a method of "keeping the process alive" after a Jenkins stage completed was necessary.  Is it in this Workload? Why or why not?

12. Create a MultiBranch Pipeline and run the build. IMPORTANT: Make sure the name of the pipeline is: "workload_4".  Check to see if the application can be accessed from the public IP address of the "Web_Server".

13. If all is well, create an EC2 t3.micro called "Monitoring" with Prometheus and Grafana and configure it so that it can collect metrics on the application server.

14. Document! All projects have documentation so that others can read and understand what was done and how it was done. Create a README.md file in your repository that describes:

	  a. The "PURPOSE" of the Workload,

  	b. The "STEPS" taken (and why each was necessary/important),
    
  	c. A "SYSTEM DESIGN DIAGRAM" that is created in draw.io (IMPORTANT: Save the diagram as "Diagram.jpg" and upload it to the root directory of the GitHub repo.),

	  d. "ISSUES/TROUBLESHOOTING" that may have occured,

  	e. An "OPTIMIZATION" section for that answers the questions: What are the advantages of separating the deployment environment from the production environment?  Does the infrastructure in this workload address these concerns?  Could the infrastructure created in this workload be considered that of a "good system"?  Why or why not?  How would you optimize this infrastructure to address these issues?

    f. A "CONCLUSION" statement as well as any other sections you feel like you want to include.
