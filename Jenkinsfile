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
                // Initialize Terraform
                sh 'terraform init -backend-config="s3_bucket=infra-terraform-state-01" -backend-config="key=terraform.tfstate"'
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
}
