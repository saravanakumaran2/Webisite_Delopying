pipeline {
    agent any

    environment {
        DOCKER_URI = 'tcp://54.160.146.79:2375'  // Docker server URI
        DOCKER_SERVER_CREDENTIALS = 'docker-server'  // Jenkins credentials ID for Docker server access
    }

    stages {
        stage('Cleanup') {
            steps {
                cleanWs()  // Clean the workspace
            }
        }

        stage('Checkout Code') {
            steps {
                checkout scm  // Checkout code from the Git repository
            }
        }

        stage('Build Image') {
            steps {
                withDockerServer([uri: DOCKER_URI, credentialsId: DOCKER_SERVER_CREDENTIALS]) {
                    script {
                        // Docker build command runs on the remote Docker server
                        docker.build("static-website-nginx:develop-${BUILD_ID}")
                    }
                }
            }
        }

        stage('Run Container') {
            steps {
                withDockerServer([uri: DOCKER_URI, credentialsId: DOCKER_SERVER_CREDENTIALS]) {
                    script {
                        // Stop and remove any existing container
                        sh "docker stop develop-container || true && docker rm develop-container || true"

                        // Run the container on the remote Docker server
                        sh "docker run --name develop-container -d -p 8081:80 static-website-nginx:develop-${BUILD_ID}"
                    }
                }
            }
        }

        stage('Test Website') {
            steps {
                // Test if the website is accessible using the new IP and port
                sh 'curl -I http://54.160.146.79:8081'
            }
        }

        stage('Push Image') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'dockerhub-auth', usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD')]) {
                    sh '''#!/bin/bash
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
