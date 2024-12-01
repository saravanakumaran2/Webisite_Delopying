pipeline {
    agent any  // Runs on any available agent (node)
    environment {
        DOCKER_SERVER_CREDENTIALS = 'docker-server'  // The SSH credentials ID for Docker server
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

        stage('Build Image') {
            steps {
                // Builds the Docker image
                withCredentials([sshUserPrivateKey(credentialsId: 'docker-server', keyFileVariable: 'SSH_PRIVATE_KEY')]) {
                    sh '''
                        # Add SSH private key to Docker environment
                        export DOCKER_SSH_KEY=$SSH_PRIVATE_KEY
                        # Set up SSH agent to handle private key
                        eval $(ssh-agent -s)
                        ssh-add <(echo "$DOCKER_SSH_KEY")
                        # Docker build command
                        docker build -t static-website-nginx:develop-${BUILD_ID} .
                    '''
                }
            }
        }

        stage('Run Container') {
            steps {
                // Stops and removes existing container, then runs a new one
                withCredentials([sshUserPrivateKey(credentialsId: 'docker-server', keyFileVariable: 'SSH_PRIVATE_KEY')]) {
                    sh '''
                        # Use the SSH private key for authentication
                        export DOCKER_SSH_KEY=$SSH_PRIVATE_KEY
                        eval $(ssh-agent -s)
                        ssh-add <(echo "$DOCKER_SSH_KEY")
                        # Stop and remove any existing container
                        docker stop develop-container || true && docker rm develop-container || true
                        # Run the container with the new image
                        docker run --name develop-container -d -p 8081:80 static-website-nginx:develop-${BUILD_ID}
                    '''
                }
            }
        }

        stage('Test Website') {
            steps {
                // Tests if the website is accessible using the new IP
                sh 'curl -I http://54.160.146.79:8081'
            }
        }

        stage('Push Image') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'dockerhub-auth', usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD')]) {
                    sh '''
                        # Docker login for Docker Hub using username/password credentials
                        docker login -u $USERNAME -p $PASSWORD
                        # Tag and push Docker images to Docker Hub
                        docker tag static-website-nginx:develop-${BUILD_ID} $USERNAME/static-website-nginx:latest
                        docker tag static-website-nginx:develop-${BUILD_ID} $USERNAME/static-website-nginx:develop-${BUILD_ID}
                        docker push $USERNAME/static-website-nginx:latest
                        docker push $USERNAME/static-website-nginx:develop-${BUILD_ID}
                    '''
                }
            }
        }
    }
}
