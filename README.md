
Deploying the eKS cluster using Jenkins and terraform 
Step 1: Set Up Jenkins Server
Provision a Jenkins Server:

Use a service like AWS EC2 to provision an instance.
Choose an appropriate instance type (e.g., t2.medium).
Install Java:
bash
Copy code
sudo apt update
sudo apt install openjdk-11-jdk -y
Install Jenkins:

Add Jenkins repository and key:
bash
Copy code
wget -q -O - https://pkg.jenkins.io/debian/jenkins.io.key | sudo apt-key add -
sudo sh -c 'echo deb http://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
Install Jenkins:
bash
Copy code
sudo apt update
sudo apt install jenkins -y
Start Jenkins:
bash
Copy code
sudo systemctl start jenkins
sudo systemctl enable jenkins
Access Jenkins:

Open a browser and navigate to http://your-server-ip:8080.
Retrieve the initial admin password:
bash
Copy code
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
Follow the setup wizard to complete the installation and create an admin user.
Step 2: Configure Jenkins for Terraform
Install Plugins:

Go to Manage Jenkins -> Manage Plugins.
Install the following plugins:
Git Plugin
Pipeline Plugin
Terraform Plugin
Configure Global Tools:

Go to Manage Jenkins -> Global Tool Configuration.
Add the following tools:
Git: Provide the path to Git executable if not installed, install it:
bash
Copy code
sudo apt install git -y
Terraform: Download and install Terraform, then add it to the PATH.
Add AWS Credentials:

Go to Manage Jenkins -> Manage Credentials.
Add AWS credentials (AWS Access Key ID and Secret Access Key) for Terraform.
Step 3: Set Up Terraform Code Repository
Create a Git Repository:
Initialize a new Git repository and add your Terraform code.
Commit and push the code to a version control system like GitHub.
Step 4: Configure S3 Bucket for Terraform State
Create an S3 Bucket:
Go to the AWS Management Console.
Create an S3 bucket named infra-terraform-state-01.
Ensure versioning is enabled for the bucket to maintain state file history.
Step 5: Set Up Jenkins Pipeline
Create a Jenkins Pipeline Job:

Go to Jenkins Dashboard -> New Item.
Create a new pipeline job and name it appropriately.
Configure the Pipeline Job:

Under Pipeline section, select Pipeline script from SCM.
Choose Git as the SCM.
Enter the repository URL and credentials.
Set the script path to the location of your Jenkinsfile.
Step 6: Run the Jenkins Pipeline
Trigger the Pipeline:

Manually trigger the pipeline from the Jenkins Dashboard.
Pipeline Execution:

The pipeline will execute the following stages:
Checkout: Clones the Git repository.
Terraform Init: Initializes the Terraform configuration.
Terraform Apply: Applies the Terraform configuration to create the EKS cluster.
Step 7: Verify EKS Cluster
Verify EKS Cluster:
Use AWS CLI or AWS Management Console to verify that the EKS cluster is up and running.
You can also configure kubectl to connect to the EKS cluster.
Additional Notes
NAT Gateway and Subnet Configuration:

Ensure that the NAT Gateway and subnets are correctly set up. The provided Terraform code had a small mistake in the availability zone configuration for the subnet.
hcl
Copy code
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.k8s_vpc.id
  cidr_block              = "10.0.0.0/24"
  availability_zone       = "us-east-1a" # Correct the availability zone
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet"
  }
}
VPC and Security Groups:

Ensure that the VPC and security groups are configured correctly to allow traffic as needed for your applications.
By following these steps, you'll have a Jenkins server set up to deploy an EKS cluster using Terraform. If you encounter any issues, you can refer to the Jenkins and Terraform documentation for troubleshooting.

you skipp the terraform code and jenkin file compeletey

ChatGPT
I apologize for that. Let's go through the steps to set up

the Jenkins server and configure it to use the provided Terraform code and Jenkinsfile. Here’s a detailed, step-by-step guide:

Step 1: Set Up Jenkins Server
Provision a Jenkins Server:

Use AWS EC2 (or any other cloud provider) to create an instance.
Choose an appropriate instance type (e.g., t2.medium).
Ensure the security group allows traffic on port 8080 (Jenkins default port).
Install Jenkins:

SSH into your instance and run the following commands:
bash
Copy code
sudo apt update
sudo apt install openjdk-11-jdk -y
wget -q -O - https://pkg.jenkins.io/debian/jenkins.io.key | sudo apt-key add -
sudo sh -c 'echo deb http://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
sudo apt update
sudo apt install jenkins -y
sudo systemctl start jenkins
sudo systemctl enable jenkins
Open a browser and navigate to http://<your-server-ip>:8080.
Retrieve the initial admin password:
bash
Copy code
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
Follow the setup wizard to complete the installation and create an admin user.
Step 2: Configure Jenkins for Terraform
Install Plugins:

Go to Manage Jenkins -> Manage Plugins.
Install the following plugins:
Git Plugin
Pipeline Plugin
AWS Credentials Plugin
Configure Global Tools:

Go to Manage Jenkins -> Global Tool Configuration.
Configure the following tools:
Git: Provide the path to Git executable. Install Git if not already installed:
bash
Copy code
sudo apt install git -y
Terraform: Install Terraform by downloading it and adding it to your PATH. Verify with:
bash
Copy code
terraform --version
Add AWS Credentials:

Go to Manage Jenkins -> Manage Credentials.
Add AWS credentials (AWS Access Key ID and Secret Access Key) for Terraform.
Step 3: Set Up Terraform Code Repository
Create a Git Repository:
Initialize a new Git repository and add your Terraform code.
Commit and push the code to a version control system like GitHub.
Step 4: Configure S3 Bucket for Terraform State
Create an S3 Bucket:
Go to the AWS Management Console.
Create an S3 bucket named infra-terraform-state-01.
Ensure versioning is enabled for the bucket to maintain state file history.
Step 5: Set Up Jenkins Pipeline
Create a Jenkins Pipeline Job:

Go to Jenkins Dashboard -> New Item.
Create a new pipeline job and name it appropriately.
Configure the Pipeline Job:

Under Pipeline section, select Pipeline script from SCM.
Choose Git as the SCM.
Enter the repository URL and credentials.
Set the script path to the location of your Jenkinsfile.
Step 6: Configure Jenkinsfile and Terraform Code
Jenkinsfile
groovy
Copy code
pipeline {
    agent any
    
    stages {
        stage('Checkout') {
            steps {
                // Checkout the code from the GitHub repository
                script {
                    checkout scm
                }
            }
        }
        
        stage('Terraform Init') {
            steps {
                script {
                    def terraformInitCmd = """
                        terraform init \\
                        -backend-config="bucket=infra-terraform-state-01" \\
                        -backend-config="key=terraform.tfstate"
                    """
                    sh(script: terraformInitCmd, returnStatus: true)
                }
            }
        }
        
        stage('Terraform Apply') {
            steps {
                // Apply Terraform configuration to create the EKS cluster
                sh 'terraform apply -auto-approve'
            }
        }
    }
}
Terraform Code
hcl
Copy code
# Define the AWS provider
provider "aws" {
  region = "us-east-1" # Replace with your desired region
}

# Create a VPC
resource "aws_vpc" "k8s_vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = "k8s-infra"
  }
}

# Create an Elastic IP for the NAT Gateway
resource "aws_eip" "nat_eip" {
  vpc_id = aws_vpc.k8s_vpc.id
}

# Create a public subnet
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.k8s_vpc.id
  cidr_block              = "10.0.0.0/24"
  availability_zone       = "us-east-1a" # Replace with your desired AZ
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet"
  }
}

# Create a NAT Gateway for the public subnet
resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet.id
}

# Create a security group for SSH and allow all traffic
resource "aws_security_group" "sg" {
  name        = "k8s-infra-sg"
  description = "Security group for Kubernetes infrastructure"
  vpc_id      = aws_vpc.k8s_vpc.id

  # Allow SSH and all traffic (for demonstration purposes, consider tightening this)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic (for demonstration purposes, consider tightening this)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.0.4"

  cluster_name    = "ts4u"
  cluster_version = "1.23"

  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true

  vpc_id     = aws_vpc.k8s_vpc.id
  subnet_ids = [aws_subnet.public_subnet.id]

  enable_irsa = true

  eks_managed_node_groups = {
    green = {
      min_size     = 2
      max_size     = 2
      desired_size = 2

      instance_types = ["t2.medium"]
    }
  }
}

# Configure remote state in an S3 bucket
terraform {
  backend "s3" {
    bucket         = "infra-terraform-state-01"
    key            = "terraform.tfstate"
    region         = "us-east-1" # Replace with your desired region
  }
}
Step 7: Run the Jenkins Pipeline
Trigger the Pipeline:

Manually trigger the pipeline from the Jenkins Dashboard.
Pipeline Execution:

The pipeline will execute the following stages:
Checkout: Clones the Git repository.
Terraform Init: Initializes the Terraform configuration.
Terraform Apply: Applies the Terraform configuration to create the EKS cluster.
Step 8: Verify EKS Cluster
Verify EKS Cluster:
Use AWS CLI or AWS Management Console to verify that the EKS cluster is up and running.
You can also configure kubectl to connect to the EKS cluster:
bash
Copy code
aws eks update-kubeconfig --name ts4u --region us-east-1
kubectl get nodes
