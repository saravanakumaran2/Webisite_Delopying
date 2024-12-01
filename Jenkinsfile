pipeline {
    agent any
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
            agent {
                // Ensure that the Docker commands run on the Docker server node
                node {
                    label 'docker-server'  // Make sure this matches the node/agent label where Docker is configured
                }
            }
            steps {
                // Build the Docker image on the Docker server
                withCredentials([usernamePassword(credentialsId: 'docker-server', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                    sh '''
                        docker login -u $DOCKER_USER -p $DOCKER_PASS
                        docker build -t static-website-nginx:develop-${BUILD_ID} .
                    '''
                }
            }
        }

        stage('Run Container') {
            agent {
                // Ensure that the Docker commands run on the Docker server node
                node {
                    label 'docker-server'  // Ensure Docker server node is used here
                }
            }
            steps {
                // Stops and removes existing container, then runs a new one on Docker server
                withCredentials([usernamePassword(credentialsId: 'docker-server', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                    sh '''
                        docker login -u $DOCKER_USER -p $DOCKER_PASS
                        docker stop develop-container || true && docker rm develop-container || true
                        docker run --name develop-container -d -p 8081:80 static-website-nginx:develop-${BUILD_ID}
                    '''
                }
            }
        }

        stage('Test Website') {
            steps {
                // Tests if the website is accessible
                sh 'curl -I http://54.85.223.42:8081'
            }
        }

        stage('Push Image') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'dockerhub-auth', usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD')]) {
                    sh '''
                        docker login -u $USERNAME -p $PASSWORD
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
