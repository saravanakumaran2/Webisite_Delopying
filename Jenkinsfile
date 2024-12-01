pipeline {
    agent any
    environment {
        SERVER_IP = '54.160.146.79'
        SSH_CREDENTIALS_ID = 'docker-server'
        DOCKERHUB_CREDENTIALS_ID = 'dockerhub-auth'
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
                sshagent([SSH_CREDENTIALS_ID]) {
                    sh """
                    scp -r Dockerfile Jenkinsfile README.md assets error images index.html root@${SERVER_IP}:/opt/website_project/
                    """
                }
            }
        }

        stage('Build Image') {
            steps {
                sshagent([SSH_CREDENTIALS_ID]) {
                    sh """
                    ssh -o StrictHostKeyChecking=no root@${SERVER_IP} << 'EOF'
                    cd /opt/website_project
                    docker build -t static-website-nginx:develop-${BUILD_ID} .
                    EOF
                    """
                }
            }
        }

        stage('Run Container') {
            steps {
                sshagent([SSH_CREDENTIALS_ID]) {
                    sh """
                    ssh -o StrictHostKeyChecking=no root@${SERVER_IP} << 'EOF'
                    docker stop develop-container || true
                    docker rm develop-container || true
                    docker run --name develop-container -d -p 8081:80 static-website-nginx:develop-${BUILD_ID}
                    EOF
                    """
                }
            }
        }

        stage('Test Website') {
            steps {
                sshagent([SSH_CREDENTIALS_ID]) {
                    sh """
                    ssh -o StrictHostKeyChecking=no root@${SERVER_IP} << 'EOF'
                    curl -I http://${SERVER_IP}:8081
                    EOF
                    """
                }
            }
        }

        stage('Push Image') {
            steps {
                sshagent([SSH_CREDENTIALS_ID]) {
                    withCredentials([usernamePassword(credentialsId: DOCKERHUB_CREDENTIALS_ID, usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD')]) {
                        sh """
                        ssh -o StrictHostKeyChecking=no root@${SERVER_IP} << 'EOF'
                        echo $PASSWORD | docker login -u $USERNAME --password-stdin
                        docker tag static-website-nginx:develop-${BUILD_ID} $USERNAME/static-website-nginx:latest
                        docker tag static-website-nginx:develop-${BUILD_ID} $USERNAME/static-website-nginx:develop-${BUILD_ID}
                        docker push $USERNAME/static-website-nginx:latest
                        docker push $USERNAME/static-website-nginx:develop-${BUILD_ID}
                        EOF
                        """
                    }
                }
            }
        }
    }
}
