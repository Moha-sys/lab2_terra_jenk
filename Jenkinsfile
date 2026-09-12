pipeline {
    agent any

    parameters {
        choice(
            name: 'ENVIRONMENT',
            choices: ['dev', 'stg', 'prod'],
            description: 'Target environment to deploy'
        )
        choice(
            name: 'ACTION',
            choices: ['apply', 'plan', 'destroy'],
            description: 'Terraform action to perform'
        )
        string(
            name: 'FLOCI_ENDPOINT',
            defaultValue: 'http://172.17.0.1:4566',
            description: 'Floci AWS emulator endpoint (uses 172.17.0.1:4566 for Docker container to host communication)'
        )
    }

    environment {
        AWS_ACCESS_KEY_ID     = 'test'
        AWS_SECRET_ACCESS_KEY = 'test'
        AWS_DEFAULT_REGION    = 'us-east-1'
        TF_VAR_floci_endpoint = "${params.FLOCI_ENDPOINT}"
    }

    stages {
        stage('Configure Endpoint') {
            steps {
                script {
                    // When Jenkins runs in Docker, localhost points inside the container.
                    // Route localhost/127.0.0.1 to Docker host gateway (172.17.0.1).
                    if (params.FLOCI_ENDPOINT.contains('localhost') || params.FLOCI_ENDPOINT.contains('127.0.0.1')) {
                        env.TF_VAR_floci_endpoint = 'http://172.17.0.1:4566'
                    }
                    echo "Using Floci endpoint: ${env.TF_VAR_floci_endpoint}"
                }
            }
        }

        stage('Terraform Init') {
            steps {
                sh 'terraform init'
            }
        }

        stage('Select Workspace') {
            steps {
                sh '''
                    terraform workspace select ${ENVIRONMENT} || terraform workspace new ${ENVIRONMENT}
                '''
            }
        }

        stage('Terraform Validate') {
            steps {
                sh 'terraform validate'
            }
        }

        stage('Terraform Plan') {
            steps {
                sh '''
                    terraform plan -var-file="${ENVIRONMENT}.tfvars" -out=tfplan
                '''
            }
        }

        stage('Manual Approval Gate') {
            when {
                expression { params.ACTION == 'apply' || params.ACTION == 'destroy' }
            }
            steps {
                timeout(time: 15, unit: 'MINUTES') {
                    input(
                        message: "Review the plan above for '${params.ENVIRONMENT}'. Do you approve '${params.ACTION}' on Floci?",
                        ok: "Approve and Proceed"
                    )
                }
            }
        }

        stage('Terraform Apply / Destroy') {
            when {
                expression { params.ACTION != 'plan' }
            }
            steps {
                script {
                    if (params.ACTION == 'apply') {
                        sh 'terraform apply -input=false tfplan'
                    } else if (params.ACTION == 'destroy') {
                        sh "terraform destroy -var-file=${params.ENVIRONMENT}.tfvars -auto-approve"
                    }
                }
            }
        }
    }

    post {
        always {
            sh 'rm -f tfplan'
        }
    }
}
