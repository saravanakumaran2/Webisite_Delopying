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
        stage('Cleanup') {
            steps {
                cleanWs() // Clean workspace
            }
        }

        stage('Clone Git Repo') {
            steps {
                checkout scm // Checkout source code
            }
        }

        stage('Listing Files') {
            steps {
                sh 'ls -l' // List files in the workspace
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

        stage('Build Docker Image') {
            steps {
                echo 'Building Docker image...'
                dir('app') {
                    withCredentials([usernamePassword(credentialsId: 'docker-auth', usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD')]) {
                        sh '''
                            docker build -t $USERNAME/$IMAGE_NAME:develop-8 .
                            docker login -u $USERNAME -p $PASSWORD
                            docker push $USERNAME/$IMAGE_NAME:develop-8
                        '''
                    }
                }
            }
        }

        stage('Deploy Docker Container') {
            steps {
                echo 'Deploying Docker container...'
                sshagent(credentials: ['root']) {
                    sh '''
                        ssh -o StrictHostKeyChecking=no $SSH_USER@54.221.41.125 \
                        "docker stop develop-container || true && docker rm develop-container || true"
                    '''
                    sh '''
                        ssh -o StrictHostKeyChecking=no $SSH_USER@54.221.41.125 \
                        "docker run --name develop-container -d -p $PORT:80 $USERNAME/$IMAGE_NAME:develop-8"
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
                    withCredentials([usernamePassword(credentialsId: 'docker-auth', usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD')]) {
                        sh '''
                            docker login -u $USERNAME -p $PASSWORD
                            docker tag $USERNAME/$IMAGE_NAME:develop-8 docker.io/$USERNAME/$IMAGE_NAME:latest
                            docker push docker.io/$USERNAME/$IMAGE_NAME:latest
                            docker push docker.io/$USERNAME/$IMAGE_NAME:develop-8
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
