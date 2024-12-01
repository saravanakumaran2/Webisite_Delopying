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
            sshagent(['docker-server']) {
                steps {
                    sh 'docker build -t static-website-nginx:develop-${BUILD_ID} .'
                }
            }
        }

        stage('Run Container') {
            sshagent(['docker-server']) {
                steps {
                    sh 'docker stop develop-container || true && docker rm develop-container || true'
                    sh 'docker run --name develop-container -d -p 8081:80 static-website-nginx:develop-${BUILD_ID}'
                }
            }
        }

        stage('Test Website') {
            sshagent(['docker-server']) {
                steps {
                    sh 'curl -I http://54.160.146.79:8081'
                }
            }
        }
        
        
        stage('Push Image') {
            sshagent(['docker-server']) {
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
}
