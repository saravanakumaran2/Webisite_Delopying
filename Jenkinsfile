pipeline {
    agent any  // Runs on any available agent (node)
    environment {
        DOCKER_SERVER_CREDENTIALS = 'docker-server'  // Credentials ID for Docker server
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
                withCredentials([usernamePassword(credentialsId: 'docker-server', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                    sh '''
                        # Docker login using the Jenkins credentials
                        docker login -u $DOCKER_USER -p $DOCKER_PASS
                        # Build the Docker image
                        docker build -t static-website-nginx:develop-${BUILD_ID} .
                    '''
                }
            }
        }

        stage('Run Container') {
            steps {
                // Stops and removes existing container, then runs a new one
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
                // Tests if the website is accessible using the new IP
                sh 'curl -I http://54.160.146.79:8081'
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
