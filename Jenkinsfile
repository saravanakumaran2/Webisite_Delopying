pipeline {
    agent any
    environment {
        DOCKER_HOST = 'tcp://18.208.155.27:2375'
        IMAGE_NAME = 'static-website-nginx'
        PORT = '8081'
    }
    stages {
        stage('Pre-check: Docker Availability') {
            steps {
                // Check if Docker is installed and accessible
                sh '''
                    if ! command -v docker &> /dev/null; then
                        echo "Error: Docker is not installed or not accessible."
                        exit 1
                    fi
                '''
            }
        }

        stage('Cleanup') {
            steps {
                cleanWs() // Cleans the workspace
            }
        }

        stage('Checkout Code') {
            steps {
                checkout scm // Checks out the code from the repository
            }
        }

        stage('Build Image') {
            steps {
                // Retry on failure, build the Docker image on the attached Docker server
                retry(3) {
                    sh "docker -H ${DOCKER_HOST} build -t ${IMAGE_NAME}:develop-${BUILD_ID} ."
                }
            }
        }

        stage('Run Container') {
            steps {
                // Gracefully stop and remove any existing container, then run a new one on the attached Docker server
                sh '''
                    docker -H ${DOCKER_HOST} stop develop-container || echo "No container to stop"
                    docker -H ${DOCKER_HOST} rm develop-container || echo "No container to remove"
                '''
                sh "docker -H ${DOCKER_HOST} run --name develop-container -d -p ${PORT}:80 ${IMAGE_NAME}:develop-${BUILD_ID}"
            }
        }

        stage('Test Website') {
            steps {
                // Tests if the website is accessible
                sh "curl -I http://18.208.155.27:${PORT} || echo 'Website is not accessible'"
            }
        }

        stage('Push Image') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'dockerhub-auth', usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD')]) {
                    sh '''
                        docker -H ${DOCKER_HOST} login -u $USERNAME -p $PASSWORD
                        docker -H ${DOCKER_HOST} tag ${IMAGE_NAME}:develop-${BUILD_ID} $USERNAME/${IMAGE_NAME}:latest
                        docker -H ${DOCKER_HOST} tag ${IMAGE_NAME}:develop-${BUILD_ID} $USERNAME/${IMAGE_NAME}:develop-${BUILD_ID}
                        docker -H ${DOCKER_HOST} push $USERNAME/${IMAGE_NAME}:latest
                        docker -H ${DOCKER_HOST} push $USERNAME/${IMAGE_NAME}:develop-${BUILD_ID}
                    '''
                }
            }
        }

        stage('Deploy to App Server') {
            steps {
                sshagent(['ssh-key']) {
                    withCredentials([usernamePassword(credentialsId: 'docker', usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD')]) { 
                        sh '''
                            ssh -tt docker@<APP_HOST_VM_IP> -o StrictHostKeyChecking=no \
                                "docker pull $USERNAME/${IMAGE_NAME}:latest && \
                                docker stop develop-container || true && \
                                docker rm develop-container || true && \
                                docker run --name develop-container -d -p 9000:80 $USERNAME/${IMAGE_NAME}:latest"
                        '''
                    }
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
    }
}
