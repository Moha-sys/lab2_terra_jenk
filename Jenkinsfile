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
            defaultValue: 'http://localhost:4566',
            description: 'Floci AWS emulator endpoint (use http://host.docker.internal:4566 if Jenkins runs in Docker)'
        )
    }

    environment {
        AWS_ACCESS_KEY_ID     = 'test'
        AWS_SECRET_ACCESS_KEY = 'test'
        AWS_DEFAULT_REGION    = 'us-east-1'
        TF_VAR_floci_endpoint = "${params.FLOCI_ENDPOINT}"
    }

    stages {
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
