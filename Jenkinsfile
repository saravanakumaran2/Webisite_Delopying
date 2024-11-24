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
            steps {
                // Builds the Docker image on the attached Docker server
                sh 'docker -H tcp://18.208.155.27:2375 build -t static-website-nginx:develop-${BUILD_ID} .'
            }
        }

        stage('Run Container') {
            steps {
                // Stops and removes the existing container, then runs a new one on the attached Docker server
                sh 'docker -H tcp://18.208.155.27:2375 stop develop-container || true && docker -H tcp://18.208.155.27:2375 rm develop-container || true'
                sh 'docker -H tcp://18.208.155.27:2375 run --name develop-container -d -p 8081:80 static-website-nginx:develop-${BUILD_ID}'
            }
        }

        stage('Test Website') {
            steps {
                // Tests if the website is accessible
                sh 'curl -I http://18.208.155.27:8081'
            }
        }

        stage('Push Image') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'dockerhub-auth', usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD')]) {
                    sh '''
                        docker -H tcp://18.208.155.27:2375 login -u $USERNAME -p $PASSWORD
                        docker -H tcp://18.208.155.27:2375 tag static-website-nginx:develop-${BUILD_ID} $USERNAME/static-website-nginx:latest
                        docker -H tcp://18.208.155.27:2375 tag static-website-nginx:develop-${BUILD_ID} $USERNAME/static-website-nginx:develop-${BUILD_ID}
                        docker -H tcp://18.208.155.27:2375 push $USERNAME/static-website-nginx:latest
                        docker -H tcp://18.208.155.27:2375 push $USERNAME/static-website-nginx:develop-${BUILD_ID}
                    '''
                }
            }
        }
    }
}
