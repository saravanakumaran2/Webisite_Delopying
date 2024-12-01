pipeline {
    agent any  // Runs on any available agent (node)

    environment {
        DOCKER_URI = 'tcp://54.160.146.79:2375'  // Define Docker Host URI (Remote Docker)
        DOCKER_SERVER_CREDENTIALS = 'docker-server'  // The Docker credentials ID
    }

    stages {
        stage('Cleanup') {
            steps {
                cleanWs()  // Cleans the workspace
            }
        }

        stage('Checkout Code') {
            steps {
                checkout scm  // Checks out the code from the repository
            }
        }

        stage('Build Image') {
            steps {
                withDockerServer([uri: DOCKER_URI, credentialsId: DOCKER_SERVER_CREDENTIALS]) {
                    script {
                        // Build the Docker image on the remote Docker server
                        def app = docker.build("static-website-nginx:develop-${BUILD_ID}")
                    }
                }
            }
        }

        stage('Run Container') {
            steps {
                withDockerServer([uri: DOCKER_URI, credentialsId: DOCKER_SERVER_CREDENTIALS]) {
                    script {
                        // Stop and remove any existing container, then run a new one on the remote Docker server
                        sh '''#!/bin/bash
                            # Stop and remove any existing container
                            docker stop develop-container || true && docker rm develop-container || true
                            
                            # Run the container with the new image
                            docker run --name develop-container -d -p 8081:80 static-website-nginx:develop-${BUILD_ID}
                        '''
                    }
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
                    script {
                        // Docker login for Docker Hub using username/password credentials
                        sh '''#!/bin/bash
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
}
