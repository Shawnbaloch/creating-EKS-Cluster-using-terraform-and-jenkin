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
