# Microblog - Production VPC

---

## Purpose

In the past exercise, we were focusing on implementing our Microblog app in a singular EC2 instance with a monitoring server monitoring it. These instances were sitting in the same VPC and same subnet. This time, we're creating our separate custom VPC with public and private subnets. We'll use this for our Production environment where our Web and Application servers will be.

This exercise is expanding from the previous one where we're building out our infrastructure to multiple hosts which is going to add complexity to our scripts and commands we're running for automation. We'll also be diving into networking configurations to ensure we have proper communication between the two VPCs so that we can easily connect with all our resources in the pipeline.

As we create our subnets, security groups, route tables, we'll be exploring and learning how to keep our infrastructure secure. Security and Automation are the keys to this exercise.

## High Level Overview

For this deployment, we're going to have Jenkins deploy our application to a dedicated application server by tunneling through our web server using scripts; where both are set up in a separate Production VPC and on separate subnets, one public and one private. We'll have a Web server using Nginx as a reverse proxy server that will redirect network traffic from port 80 to our application server port 5000. 

Our Jenkins server will be in our Operations VPC along with our Monitoring server, both being in separate subnets. We need Jenkins to perform our CI/CD automation, Python3.9 for our code interpreter, Python3.9-venv to be able to create virtual envs using Python3.9, python3-pip to install the python3 package manager, nginx for our reverse proxy server, and node-exporter to grab our server metrics. Our Monitoring server will have Prometheus and Grafana to create our Ops Dashboard.

Before we get started, we need a working repository for our application and CI/CD pipeline.

## Steps to Implement

### <ins>Setup Working Repository</ins>
#### <ins>Clone Source Code Repo</ins>
First, let's clone the application source code repository. We can use any Amazon EC2 Linux box in the AWS account or we can do this locally on your laptop.
* Clone source application repo to new github repository. Our Source Repository was [cloned from here.](https://github.com/kura-labs-org/C5-Deployment-Workload-4)
   ```
   git clone $SOURCE_REPO_LINK #Cloning source repo to local machine or instance
   git remote rename origin upstream #We are renaming the current remote origin to be called upstream
   git remote add origin $DESTINATION_REPO_LINK #Setting new repo as our remote origin
   git push origin main #Now we push the repo to the new repo using main branch (sometimes branch is master)
   ```
The reason why we want to clone the source repo and push it to our new repo is so we can have ownership of our working repository and make commits as needed and not mess with the source repository. This may be necessary when we may not have the necessary permissions to interact and commit to the source repository and we need to pull application code for our personal use. The reason why we aren't forking the repository is so we can track our commits and changes.

### <ins>Network Infrastructure Setup</ins>

For our networking, we're going to create a custom VPC that will be our Production VPC holding our application related resources. We'll need a public subnet for our web server and private subnet for our app server. We'll need individual route tables for both of those subnets. We'll need to create Internet and NAT Gateway for our VPC, set up routes on our route tables respectively. Lastly, create a VPC peering connection between our Production VPC and Operations VPC.

The whole reason why we want a completely separate VPC with public and private subnet is to separate our application and have it run in its own environment with minimal manual interactions after it's setup. We're reducing resource contention by having components separated, and improving security across our infrastructure with more detailed security groups and routing.

#### <ins>VPC</ins>
First, let's get our custom VPC setup. 
We need to create a VPC and set the CIDR block to something that doesn't conflict with our Operations VPC. For this instance, the CIDR block used was 10.0.0.0/20. This will set us up to configure our subnets properly and allocate the proper IP ranges to each subnet. There are two ways we can create our VPC. We can create it standalone or we can create it with our other network resources. Below are both methods.


```
VPC Option:
1. Go to VPC in AWS console.
2. Click 'Create VPC'.
3. Name your VPC.
4. Set your CIDR block. For this deployment we assigned this custom VPC with '10.0.0.0/20'. 
5. Click 'Create VPC'.


VPC and More Option:
1. Go to VPC in AWS console.
2. Click 'Create VPC'.
3. Select 'VPC and more' option.
4. De-select "Auto-generate" and in the blank under VPC, name your VPC. This deployment named the custom VPC as "Production VPC".
5. Choose your initial CIDR block range for your VPC. This deployment assigned '10.0.0.0/20' as the VPC CIDR.
6. We're only using 1 availability zone so select 1 AZ.
7. Select 1 public subnet and 1 private subnet. You can name each subnet as you need to.
8. Name the public and private route tables as well.
9. Expand the "Customize subnets CIDR blocks" drop down.
10. Set your public and private subnet CIDR blocks if you so choose, if not, AWS should have automatically split it up for you.
11. Select 1 AZ for your NAT gateway. 
12. Set VPC endpoints to "None".
13. For our DNS options, make sure "Enable DNS hostnames" and "Enable DNS resolution" are checked.
14. Click 'Create VPC' and we should be done.
```
Production VPC CIDR - 10.0.0.0/20  
Operations VPC CIDR - 172.31.0.0/16

If you decide to use the 'VPC and More' option then all your resources that you would need would be created for you. The Internet Gateway will be attached to the VPC and have a route entry in the Public Subnet route table. The NAT Gateway will be created and placed in the Public subnet where the Private Subnet route table will have a route to NAT Gateway. For the most part the network infrastructure would be mostly setup, the only thing we would need to do is to create a VPC Peering and add that to the route tables.

Let's continue as if we chose the first option of just creating the bare bones VPC.

#### <ins>Subnets</ins>
Now that we have our Production VPC created, we need to create our Public and Private subnets.

```
1. While on VPC dashboard, on the left side column, click 'Subnets'.
2. Click 'Create Subnet'
3. Select the Custom VPC we just made.
4. Type a name for the first subnet. For this we created our Web Subnet which is going to be our Public Subnet.
5. Choose an AZ.
6. Select a CIDR block for the Web Subnet.
7. Click 'Add new subnet'.
8. Repeat steps 4-6 where you choose the same AZ as the first subnet and select a different CIDR for the Private Subnet.
```

Web Subnet(Public) - 10.0.0.0/22  
App Subnet(Private) - 10.0.4.0/22

#### <ins>Internet/NAT Gateways</ins>

Now let's create our Internet and NAT gateways. Internet gateways give our instances a way to access the internet outside of the VPC. NAT gateway is a network address translation gateway that allows our private resources have access to the internet by translating the private IP to a temporary public IP for retrievals or gets and sending information out to the internet.

Our Internet Gateway is at the VPC level and is attached to a VPC. For this instance, we're attaching our Internet Gateway to our Custom VPC. Our NAT Gateway, we're placing it in the Web Subnet(Public) so that it has a route to the Internet Gateway.

#### <ins>VPC Peering</ins>

Now we need to create our VPC Peering connection. This allows us to create a connection between our two VPCs and enable traffic between the two. This will also allow us to communicate with resources in both VPCs via the Private IP, when configured correctly. For this deployment we'll be requesting from the Operations VPC to the Production VPC. After we have established and accepted the peering, we will now need to modify our Route tables.

#### <ins>Route Tables</ins>
For route tables we will be configuring them as such noted below for each route table. We'll have 3 route tables to configure, Public Route Table associated with our Web Subnet (public), Private Route Table associated with our Application Subnet (private), and our Operations Route Table associated with our Operations VPC's subnets (public).

**Production VPC - Public Route Table (Web Subnet associated)**
| Destination   | Target               |
|---------------|----------------------|
| 0.0.0.0/0     | Internet Gateway     |
| 10.0.0.0/20   | local                |
| 172.31.0.0/16 | VPC Peering          |

**Production VPC - Private Route Table (Application Subnet associated)**
| Destination   | Target               |
|---------------|----------------------|
| 0.0.0.0/0     | NAT Gateway          |
| 10.0.0.0/20   | local                |
| 172.31.0.0/16 | VPC Peering          |

**Operations VPC - Operations Route Table (All Subnets associated)**
| Destination   | Target               |
|---------------|----------------------|
| 0.0.0.0/0     | Internet Gateway     |
| 10.0.0.0/20   | VPC Peering          |
| 172.31.0.0/16 | local                |

With this configuration we are now able to communicate between our VPCs and our instances.

### <ins>Operations Environment Setup</ins>

Now we can move on and build out our Operational infrastructure that we'll use to deploy, maintain, and monitor our systems.

#### <ins>Jenkins Server</ins>

For Jenkins, we're going to use a t3.medium to handle all the workload that it'll be doing for our CI/CD Pipeline. 


1. Create the t3.medium and name it "Jenkins". In this deployment, we're going to use Jenkins solely for Jenkins and testing our application and handling our CI/CD Pipeline.
2. We need to configure our Security group to allow SSH(port 22) and Jenkins(port 8080) from all sources.
3. We'll need to install a few tools and packages for Jenkins to work. We need to install Jenkins itself (CI/CD tool), Python 3.9 (code interpreter), Python3.9-venv (virtual environment module), python3-pip (python package manager), java runtime (for Jenkins to run), fontconfig (for GUI text rendering), software-properties-common (scripts managing software repos like PPAs), deadsnakes ppa (for installing older/newer python versions). If you'd like to see the script used to install these components, [you can find it here](https://github.com/jonwang22/microblog_VPC_deployment/blob/main/scripts/install_jenkins.sh). Make sure the script is executable first with ```$chmod +x ~/microblog_EC2_deployment/setup_resources/install_resources.sh```.
4. In order for us to have Jenkins execute our pipeline, we need to create an ssh key for Jenkins. We then take the public key and add it to the Web Server's authorized keys list. We'll need to use this when Jenkins executes the pipeline.


#### <ins>Monitoring Server</ins>

We'll also need a monitoring server to monitor our application server to make sure the system is healthy and there are no issues with the server that could potentially impact our application.


1. Create the t3.micro and name it "Monitoring", we will need to install Prometheus and Grafana. Prometheus is going to retrieve metrics from Node-Exporter that will be on our App Server. Grafana is going to pull the scraped metrics from Prometheus and graph them so we can create dashboards to monitor our application server.
2. We need to configure a new security group for the "Monitoring" server. The group should allow SSH(port 22), Prometheus(port 9090), and Grafana(port 3000).
3. Install Prometheus and Grafana. You can use this script to install Prometheus and Grafana as well as configure Prometheus to access the target to Node-Exporter on the application server. You can find the [installation script here](https://github.com/jonwang22/microblog_VPC_deployment/blob/main/scripts/install_prometheus_grafana.sh). Make sure the script is executable first with ```$chmod +x ~/microblog_EC2_deployment/setup_resources/install_prometheus_grafana.sh```
4. We'll need to modify the /opt/prometheus/prometheus.yml file and change the IP target for Node-Exporter. The IP we'll use is the Private IP of the Application Server.


Now that we've setup our Operations infrastructure, we'll need to create our Production environment.

### <ins>Production Environment Setup</ins>

For our Prod environment, we'll be creating our Web Server that will handle our user traffic, and our Application Server that will handle our application load. 

#### <ins>Web Server</ins>

Web server will have Nginx as a reverse proxy and will handle incoming network traffic and help redirect that traffic to the App Server on the application port.

1. Create t3.micro named "Web_Server". We'll install nginx onto this host and then configure the forwarding in the `/etc/nginx/sites-enabled/default` file and point it to the Private IP of the Application server and the port that will host the application.
```
location / {
proxy_pass http://$APPSERVER_PRIVATE_IP:5000;
proxy_set_header Host $host;
proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
}
```
2. For the Security group, we need to enable SSH (port 22), HTTP (port 80).
3. Nginx will be listening to port 80 for traffic and then forward that traffic over to the App Server at port 5000 where the application will be running.
4. We will be using this server to execute a script called "setup.sh" that will ssh into the App Server and execute a script called "start_app.sh" script on the App Server that will then execute our application on port 5000.

#### <ins>Application Server</ins>

With our Web Server ready, we need to set up our Application Server.

1. Create t3.micro named "Application_Server". We need to create a script that installs the same packages and dependencies that we installed on "Jenkins" because this is where our application will be hosted. We also need to install node_exporter onto this server as well so we can have Prometheus scrape the gathered metrics and send it to Grafana. The install script for [node exporter is here](https://github.com/jonwang22/microblog_VPC_deployment/blob/main/scripts/install_node_exporter.sh).
2. For the Security group, we need to allow SSH (Port 22), and Gunicorn (Port 5000). Nginx will need access to port 5000 so we set the source of both rules to the security group for our web servers.
3. App Server is going to have our "start_app.sh" script that will execute all the installations and downloads we need to build our environment up for our application to run.
4. For our web server to have access to the application server, we need to secure copy the private key to the web server from our local machine when we downloaded the key after creating the application server. This private key will allow our web server to ssh into the app server and execute the commands we need to get our application up and running.

### <ins>CI/CD Pipeline</ins>

Now we need to build out our Jenkinsfile and multi-branch pipeline so we can start automating our deployment to our infrastructure. In Jenkins we need to create our Multi-Branch pipeline and call it "workload_4", connect our github repo to it so we can start working on our scripts and Jenkinsfile.

#### <ins>Script Testing</ins>

Here are the scripts we are using in this deployment. I can summarize each script as to what they are doing. The "setup.sh" script that will be curl'd into the Web Server by Jenkins will ssh into the App server and curl the "start_app.sh" that will execute all the commands needed to build out our application on the app server. Alot of testing was done manually. Starting from the "start_app.sh" and then working outwards to Jenkins. After getting a successful run on the App Server, I went to the Web Server and tested the "setup.sh" script to make sure the ssh from Web to App works and that the "start_app.sh" script runs on the App Server. Final stage is moving to Jenkinsfile and making sure the whole pipeline runs successfully.

[<ins>**setup.sh script**</ins>](https://github.com/jonwang22/microblog_VPC_deployment/blob/main/scripts/setup.sh)  
For my setup script, I'm creating variables for my script to use. I'm having the private IP for the app server as an argument for the script so that when I run this within Jenkins, I can store the Private IP into Jenkins credentials and then call that variable in the Jenkinsfile script on the deploy stage.
```
appserver="$1" # <----$APPLICATION_SERVER_IP is set as argument in Jenkinsfile
file_path="/home/ubuntu/start_app.sh"
repo_path="/home/ubuntu/microblog_VPC_deployment"
login_name="ubuntu"
ssh_key="/home/ubuntu/.ssh/AppWL4.pem"
script_url="https://raw.githubusercontent.com/jonwang22/microblog_VPC_deployment/refs/heads/main/scripts/start_app.sh"
```
Simply put, the rest of the script could've easily been a simple ssh using the key, authenticating in as ubuntu and then curling the start script and then sourcing it. I added a few steps to make sure that we kill an existing process so that we can refresh the application if our source code had any changes to it. Also we want to save our resources on our servers so having extra processes running will bog it down. Is this best practice, by all means no. If we had multiple app servers, then we could potentially do a rolling deployment or fractional deployment where we deploy to a single host while the other hosts are up and handling traffic for the application.

[<ins>**start_app.sh script**</ins>](https://github.com/jonwang22/microblog_VPC_deployment/blob/main/scripts/start_app.sh)  
The start script is combining all the commands we had to run in our previous deployment when we used a single instance. We're making sure we have all the packages and dependencies we need for our app, creating our virtual environment, making sure our code repo is on the server, and then running our application.

[<ins>**Jenkinsfile script**</ins>](https://github.com/jonwang22/microblog_VPC_deployment/blob/main/Jenkinsfile)
For my Jenkinsfile, the build is mimicking the beginning parts of my start script because it has to make sure it installs all the packages needed to test the app. The biggest thing in this file is using Jenkins Credentials store. I used Jenkins to store the ssh key it needed as well as the web server and app server private IPs so that the IPs are not existing out in the open of my source code. The deploy stage was tough but ultimately got it to work after figuring out how to store IPs into Jenkins as variables.

#### <ins>Jenkins Deployment</ins>
![image](https://github.com/user-attachments/assets/d4f93ec5-38b3-48ca-a8f4-4f721cfa87bc)
![image](https://github.com/user-attachments/assets/a682fac7-d94b-4ba3-8805-158c7da90c11)
![image](https://github.com/user-attachments/assets/d0b6a8d3-ed47-4812-a6bb-a3b40dd54368)
![image](https://github.com/user-attachments/assets/58bc3914-d4ff-452e-9819-4e09a5f87825)
![image](https://github.com/user-attachments/assets/7ce860d9-17a7-442b-8931-7279a3fc3fef)

## System Diagram
![Diagram](https://github.com/user-attachments/assets/6b8e038a-6d97-4774-ac5e-96e54c0a8a8e)


## Issues/Troubleshooting
I hit quite a few issues during my deployment process. A few points that gave me trouble are below:
1. Writing a working script for start_app.sh, missing dependencies or packages or syntax issues. 
2. Writing setup.sh script and figuring out how to get ssh to work and how to send commands with ssh. Took time and testing.
3. Testing ssh from Jenkins to Webserver and executing all the commands in Deploy stage. Making sure the environment variables are available for Jenkins to use in the scripts. Alot of syntax issues.
4. Making sure known_hosts accept the ssh keys where we need them to be accepted.

## Optimization
1. What are the advantages of separating the deployment environment from the production environment?  

    You have extra levels of security and isolation for your infrastructure. You can control more access points and source IPs with security groups and VPC Peering. You can separate your application logic from the web facing component. Also resource contention is separated where each instance now has its own role and that role only (aside from the application and database, that's still on a single instance).

2. Does the infrastructure in this workload address these concerns? 

    If we are comparing the concerns from the previous deployment to this workload then yes, this workload addresses the concerns found in the previous deployment of using a singular instance for everything.

3. Could the infrastructure created in this workload be considered that of a "good system"?  Why or why not?  How would you optimize this infrastructure to address these issues?
    
    The infrastructure created in this workload is closer to being a "good system". The layers of separation and building out components and splitting the service up into components is a good start. Some ways to optimize, is to create a 3 tiered web app, where we separate the database from the application server and into its own subnet. We could also develop a multi-az architecture where we have failover and redundancy. If we continue to scale and grow, we could deploy to multiple regions as well to extend our applications availability.

## Conclusion

All in all this workload was pretty good in teaching more about networking configurations and logical flow of data and what is going where and from where. Learning how ssh works and sourcing scripts is key to deploying to a bigger scale when the infrastructure eventually grows bigger.
