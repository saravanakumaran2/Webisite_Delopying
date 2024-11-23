pipeline {
    agent any
    environment {
        // Set the Docker Host URI (using SSH for remote Docker instance)
        DOCKER_HOST = 'ssh://ubuntu@3.88.177.235' // Change to your Docker server IP and user
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
                sh 'docker build -t static-website-nginx:develop-${BUILD_ID} .'
            }
        }

        stage('Run Container') {
            steps {
                // Stops and removes the existing container, then runs a new one
                sh 'docker stop develop-container || true && docker rm develop-container || true'
                sh 'docker run --name develop-container -d -p 8081:80 static-website-nginx:develop-${BUILD_ID}'
            }
        }

        stage('Test Website') {
            steps {
                // Tests if the website is accessible
                sh 'curl -I http://3.88.177.235:8081'
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
