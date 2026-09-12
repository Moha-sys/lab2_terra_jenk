pipeline {
    agent any

    parameters {
        choice(
            name: 'ENVIRONMENT',
            choices: ['dev', 'stg', 'prod'],
            description: 'Target environment to deploy'
        )
        string(
            name: 'ALERT_EMAIL',
            defaultValue: 'mafkh05@gmail.com',
            description: 'Email address to receive failure notifications'
        )
        string(
            name: 'FLOCI_ENDPOINT',
            defaultValue: 'http://172.17.0.1:4566',
            description: 'Floci AWS emulator endpoint (Docker bridge host IP)'
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

        stage('Console Action Approval') {
            steps {
                timeout(time: 15, unit: 'MINUTES') {
                    script {
                        def userChoice = input(
                            id: 'ConsoleActionPrompt',
                            message: "Review the plan above for '${ENVIRONMENT}'. Choose action to execute on Floci:",
                            ok: "Confirm Action",
                            parameters: [
                                choice(
                                    name: 'ACTION',
                                    choices: ['apply', 'abort', 'destroy'],
                                    description: 'Select action to execute on Floci'
                                )
                            ]
                        )

                        def action = (userChoice instanceof Map) ? userChoice['ACTION'] : userChoice

                        echo "Selected action from console: ${action}"

                        if (action == 'apply') {
                            echo "Applying Terraform plan on Floci..."
                            sh 'terraform apply -input=false tfplan'
                        } else if (action == 'destroy') {
                            echo "Destroying Terraform resources on Floci..."
                            sh "terraform destroy -var-file=${ENVIRONMENT}.tfvars -auto-approve"
                        } else {
                            echo "Aborting deployment without making changes to Floci."
                            currentBuild.result = 'ABORTED'
                            error("Pipeline aborted by user choice.")
                        }
                    }
                }
            }
        }
    }

    post {
        always {
            sh 'rm -f tfplan'
        }
        failure {
            mail to: "${params.ALERT_EMAIL}",
                 subject: "❌ [FAILED] Jenkins Pipeline: ${env.JOB_NAME} Build #${env.BUILD_NUMBER}",
                 body: """Hi Mohamed,

The Terraform deployment pipeline has FAILED on environment '${params.ENVIRONMENT}'.

Build Details:
------------------------------------------
Job Name:    ${env.JOB_NAME}
Build #:     #${env.BUILD_NUMBER}
Environment: ${params.ENVIRONMENT}
Status:      FAILED
Console Log: ${env.BUILD_URL}console
------------------------------------------

Please check the console log at the link above to investigate the issue.
"""
        }
    }
}
