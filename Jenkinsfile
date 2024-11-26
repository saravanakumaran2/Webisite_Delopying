pipeline {
    agent any
    environment {
        IMAGE_NAME = 'static-website-nginx'
        PORT = '8081'
    }
    stages {
        stage('Pre-check: Docker Availability') {
            steps {
                echo 'Checking Docker availability on the remote server...'
                sshagent(['docker']) {
                    sh '''
                        ssh -o StrictHostKeyChecking=no docker@3.89.21.153 \
                        "if ! command -v docker &> /dev/null; then \
                            echo 'Error: Docker is not installed or accessible.'; exit 1; \
                        fi"
                    '''
                }
            }
        }

        stage('Cleanup') {
            steps {
                echo 'Cleaning workspace...'
                cleanWs()
            }
        }

        stage('Checkout Code') {
            steps {
                echo 'Checking out the code...'
                checkout scm
            }
        }

        stage('Build Docker Image') {
            steps {
                echo 'Building Docker image on the remote server...'
                sshagent(['docker']) {
                    sh '''
                        ssh -o StrictHostKeyChecking=no docker@3.89.21.153 \
                        "docker build -t ${IMAGE_NAME}:develop-${BUILD_ID} ."
                    '''
                }
            }
        }

        stage('Run Docker Container') {
            steps {
                echo 'Stopping and removing any existing container, then starting a new one...'
                sshagent(['docker']) {
                    sh '''
                        ssh -o StrictHostKeyChecking=no docker@3.89.21.153 \
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
                sh '''
                    if ! curl -I http://3.89.21.153:${PORT}; then
                        echo 'Website is not accessible';
                        exit 1;
                    fi
                '''
            }
        }

        stage('Push Docker Image') {
            steps {
                echo 'Pushing Docker image to DockerHub...'
                withCredentials([usernamePassword(credentialsId: 'dockerhub-auth', usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD')]) {
                    sshagent(['docker']) {
                        sh '''
                            ssh -o StrictHostKeyChecking=no docker@3.89.21.153 \
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
                sshagent(['docker']) {
                    sh '''
                        ssh -o StrictHostKeyChecking=no docker@<APP_HOST_VM_IP> \
                        "docker pull $USERNAME/${IMAGE_NAME}:latest; \
                         docker stop develop-container || true; \
                         docker rm develop-container || true; \
                         docker run --name develop-container -d -p 8081:80 $USERNAME/${IMAGE_NAME}:latest"
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
        }
    }
}
