pipeline {
    agent any
    environment {
        DOCKER_IMAGE_NAME = "static-website-nginx"
        REMOTE_SERVER = "root@54.160.146.79"
        REMOTE_PATH = "/opt/website_project/"
    }
    stages {
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

        stage('Copy Files to Remote Server') {
            steps {
                sshagent(['docker-server']) {
                    sh '''
                    scp -r * ${REMOTE_SERVER}:${REMOTE_PATH}
                    '''
                }
            }
        }

        stage('Build Image') {
            steps {
                sshagent(['docker-server']) {
                    sh '''
                    ssh ${REMOTE_SERVER} << 'EOF'
                    cd ${REMOTE_PATH}
                    docker build -t ${DOCKER_IMAGE_NAME}:develop-${BUILD_ID} .
                    EOF
                    '''
                }
            }
        }

        stage('Run Container') {
            steps {
                sshagent(['docker-server']) {
                    sh '''
                    ssh ${REMOTE_SERVER} << 'EOF'
                    docker stop develop-container || true
                    docker rm develop-container || true
                    docker run --name develop-container -d -p 8081:80 ${DOCKER_IMAGE_NAME}:develop-${BUILD_ID}
                    EOF
                    '''
                }
            }
        }

        stage('Test Website') {
            steps {
                sshagent(['docker-server']) {
                    sh '''
                    ssh ${REMOTE_SERVER} << 'EOF'
                    curl -I http://54.160.146.79:8081
                    EOF
                    '''
                }
            }
        }

        stage('Push Image') {
            steps {
                sshagent(['docker-server']) {
                    withCredentials([usernamePassword(credentialsId: 'dockerhub-auth', usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD')]) {
                        sh '''
                        ssh ${REMOTE_SERVER} << 'EOF'
                        docker login -u $USERNAME -p $PASSWORD
                        docker tag ${DOCKER_IMAGE_NAME}:develop-${BUILD_ID} $USERNAME/${DOCKER_IMAGE_NAME}:latest
                        docker tag ${DOCKER_IMAGE_NAME}:develop-${BUILD_ID} $USERNAME/${DOCKER_IMAGE_NAME}:develop-${BUILD_ID}
                        docker push $USERNAME/${DOCKER_IMAGE_NAME}:latest
                        docker push $USERNAME/${DOCKER_IMAGE_NAME}:develop-${BUILD_ID}
                        EOF
                        '''
                    }
                }
            }
        }
    }
}
