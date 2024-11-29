pipeline {
    agent any
    environment {
        // Add any environment variables you need for your pipeline, such as SSH_USER, USERNAME, IMAGE_NAME, etc.
        SSH_USER = 'root'
        USERNAME = 'saravana227' // DockerHub username
        IMAGE_NAME = 'static-website-nginx' // Docker image name
        PORT = '8081' // Port on which the app will be deployed
    }
    stages {
        stage('Declarative: Checkout SCM') {
            steps {
                checkout scm
            }
        }

        stage('Pre-check: Docker Availability') {
            steps {
                echo 'Checking Docker availability on the remote server...'
                sshagent(credentials: ['root']) {
                    sh '''
                        ssh -o StrictHostKeyChecking=no $SSH_USER@54.221.41.125 \
                        "if ! command -v docker &> /dev/null; then \
                            echo 'Error: Docker is not installed or accessible.'; \
                            exit 1; \
                        fi"
                    '''
                }
            }
        }

        stage('Test SSH Access') {
            steps {
                echo 'Testing SSH access to the remote server...'
                sshagent(credentials: ['root']) {
                    sh '''
                        ssh -o StrictHostKeyChecking=no $SSH_USER@54.221.41.125 \
                        "echo SSH connection successful."
                    '''
                }
            }
        }

        stage('Checkout Code') {
            steps {
                echo 'Checking out the code...'
                checkout scm
            }
        }

        stage('Sync Code to Remote Server') {
            steps {
                echo 'Syncing code to the remote server...'
                sshagent(credentials: ['root']) {
                    sh '''
                        scp -o StrictHostKeyChecking=no -r $WORKSPACE/* $SSH_USER@54.221.41.125:/tmp/website_deployment/
                    '''
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                echo 'Building Docker image on the remote server...'
                sshagent(credentials: ['root']) {
                    sh '''
                        ssh -o StrictHostKeyChecking=no $SSH_USER@54.221.41.125 \
                        "cd /tmp/website_deployment && \
                         docker build -t $USERNAME/$IMAGE_NAME:develop-8 ."
                    '''
                }
            }
        }

        stage('Run Docker Container') {
            steps {
                echo 'Stopping and removing any existing container, then starting a new one...'
                sshagent(credentials: ['root']) {
                    sh '''
                        ssh -o StrictHostKeyChecking=no $SSH_USER@54.221.41.125 \
                        "docker stop develop-container || echo 'No container to stop'; \
                         docker rm develop-container || echo 'No container to remove'; \
                         docker run --name develop-container -d -p $PORT:80 $USERNAME/$IMAGE_NAME:develop-8"
                    '''
                }
            }
        }

        stage('Test Website Availability') {
            steps {
                echo 'Testing website accessibility...'
                script {
                    def response = sh(script: "curl -I http://54.221.41.125:$PORT -o /dev/null -w %{http_code}", returnStdout: true).trim()
                    if (response == "200") {
                        echo 'Website is accessible.'
                    } else {
                        error 'Website is not accessible.'
                    }
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                echo 'Pushing Docker image to DockerHub...'
                sshagent(credentials: ['root']) {
                    withCredentials([string(credentialsId: 'docker-hub-password', variable: 'PASSWORD')]) {
                        sh '''
                            ssh -o StrictHostKeyChecking=no $SSH_USER@54.221.41.125 \
                            "docker login -u $USERNAME -p $PASSWORD && \
                             docker tag $USERNAME/$IMAGE_NAME:develop-8 docker.io/$USERNAME/$IMAGE_NAME:latest && \
                             docker push docker.io/$USERNAME/$IMAGE_NAME:latest && \
                             docker push docker.io/$USERNAME/$IMAGE_NAME:develop-8"
                        '''
                    }
                }
            }
        }

        stage('Deploy to Application Server') {
            steps {
                echo 'Deploying the application to the app server...'
                sshagent(credentials: ['root']) {
                    sh '''
                        ssh -o StrictHostKeyChecking=no $SSH_USER@54.221.41.125 \
                        "docker pull docker.io/$USERNAME/$IMAGE_NAME:latest && \
                         docker stop develop-container || true && \
                         docker rm develop-container || true && \
                         docker run --name develop-container -d -p $PORT:80 docker.io/$USERNAME/$IMAGE_NAME:latest"
                    '''
                }
            }
        }

        stage('Declarative: Post Actions') {
            steps {
                echo 'Cleaning up temporary resources...'
                cleanWs()
            }
        }
    }
    post {
        failure {
            echo 'Pipeline failed!'
        }
        success {
            echo 'Pipeline succeeded!'
        }
    }
}
