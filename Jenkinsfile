pipeline {
    agent any
    environment {
        IMAGE_NAME = 'static-website-nginx'
        PORT = '8081'
        SSH_USER = 'root'  // SSH user for the remote server
        REMOTE_SERVER = '54.221.41.125'  // Remote server IP
    }
    stages {
        stage('Pre-check: Docker Availability') {
            steps {
                echo 'Checking Docker availability on the remote server...'
                sshagent(credentials: ['docker']) {
                    sh '''
                        ssh -o StrictHostKeyChecking=no $SSH_USER@$REMOTE_SERVER \
                        "if ! command -v docker &> /dev/null; then \
                            echo 'Error: Docker is not installed or accessible.'; exit 1; \
                        fi"
                    '''
                }
            }
        }

        stage('Test SSH Access') {
            steps {
                echo 'Testing SSH access to the remote server...'
                sshagent(credentials: ['docker']) {
                    sh '''
                        ssh -o StrictHostKeyChecking=no $SSH_USER@$REMOTE_SERVER echo "SSH connection successful."
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
                sshagent(credentials: ['docker']) {
                    sh '''
                        scp -o StrictHostKeyChecking=no -r $WORKSPACE/* $SSH_USER@$REMOTE_SERVER:/tmp/website_deployment/
                    '''
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                echo 'Building Docker image on the remote server...'
                sshagent(credentials: ['docker']) {
                    sh '''
                        ssh -o StrictHostKeyChecking=no $SSH_USER@$REMOTE_SERVER \
                        "cd /tmp/website_deployment && \
                         docker build -t ${IMAGE_NAME}:develop-${BUILD_ID} ."
                    '''
                }
            }
        }

        stage('Run Docker Container') {
            steps {
                echo 'Stopping and removing any existing container, then starting a new one...'
                sshagent(credentials: ['docker']) {
                    sh '''
                        ssh -o StrictHostKeyChecking=no $SSH_USER@$REMOTE_SERVER \
                        "docker stop develop-container || echo 'No container to stop'; \
                         docker rm develop-container || echo 'No container to remove'; \
                         docker run --name develop-container -d -p ${PORT}:80 ${IMAGE_NAME}:develop-${BUILD_ID}"
                    '''
                }
            }
        }

        stage('Test Website Availability') {
            steps {
                echo 'Testing website accessibility...'
                script {
                    def result = sh(script: "curl -I http://$REMOTE_SERVER:${PORT} -o /dev/null -w '%{http_code}'", returnStdout: true).trim()
                    if (result != "200") {
                        error "Website is not accessible, received status code: $result"
                    } else {
                        echo 'Website is accessible.'
                    }
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                echo 'Pushing Docker image to DockerHub...'
                withCredentials([usernamePassword(credentialsId: 'docker-auth', usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD')]) {
                    sshagent(['docker']) {
                        sh '''
                            ssh -o StrictHostKeyChecking=no $SSH_USER@$REMOTE_SERVER \
                            "docker login -u $USERNAME -p $PASSWORD; \
                             docker tag ${IMAGE_NAME}:develop-${BUILD_ID} $USERNAME/${IMAGE_NAME}:latest; \
                             docker tag ${IMAGE_NAME}:develop-${BUILD_ID} $USERNAME/${IMAGE_NAME}:develop-${BUILD_ID}; \
                             docker push $USERNAME/${IMAGE_NAME}:latest; \
                             docker push $USERNAME/${IMAGE_NAME}:develop-${BUILD_ID}"
                        '''
                    }
                }
            }
        }

        stage('Deploy to Application Server') {
            steps {
                echo 'Deploying the application to the app server...'
                sshagent(credentials: ['docker']) {
                    sh '''
                        ssh -o StrictHostKeyChecking=no $SSH_USER@$REMOTE_SERVER \
                        "docker pull $USERNAME/${IMAGE_NAME}:latest; \
                         docker stop develop-container || true; \
                         docker rm develop-container || true; \
                         docker run --name develop-container -d -p ${PORT}:80 $USERNAME/${IMAGE_NAME}:latest"
                    '''
                }
            }
        }
    }
    post {
        success {
            echo 'Pipeline executed successfully!'
        }
        failure {
            echo 'Pipeline failed!'
        }
        always {
            echo 'Cleaning up temporary resources...'
            cleanWs()  // Cleanup should be done in the post section after the entire pipeline is completed
        }
    }
}
