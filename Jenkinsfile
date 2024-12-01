pipeline {
    agent any
    environment {
        remoteHost = '54.160.146.79'  // Define the remote host variable for easy updates
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
                    scp -r * root@$remoteHost:/opt/website_project/
                    '''
                }
            }
        }

        stage('Build Image') {
            steps {
                sshagent(['docker-server']) {
                    sh '''
                    ssh root@$remoteHost << 'EOF'
                    cd /opt/website_project
                    docker buildx build -t static-website-nginx:develop-${BUILD_ID} .
                    EOF
                    '''
                }
            }
        }

        stage('Run Container') {
            steps {
                sshagent(['docker-server']) {
                    sh '''
                    ssh root@$remoteHost << 'EOF'
                    docker stop develop-container || true && docker rm develop-container || true
                    docker run --name develop-container -d -p 8081:80 static-website-nginx:develop-${BUILD_ID}
                    EOF
                    '''
                }
            }
        }

        stage('Test Website') {
            steps {
                sshagent(['docker-server']) {
                    sh '''
                    ssh root@$remoteHost << 'EOF'
                    curl -I http://$remoteHost:8081
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
                        ssh root@$remoteHost << 'EOF'
                        docker login -u $USERNAME -p $PASSWORD
                        docker tag static-website-nginx:develop-${BUILD_ID} $USERNAME/static-website-nginx:latest
                        docker tag static-website-nginx:develop-${BUILD_ID} $USERNAME/static-website-nginx:develop-${BUILD_ID}
                        docker push $USERNAME/static-website-nginx:latest
                        docker push $USERNAME/static-website-nginx:develop-${BUILD_ID}
                        EOF
                        '''
                    }
                }
            }
        }
    }
}
