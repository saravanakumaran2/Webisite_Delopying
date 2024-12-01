pipeline {
    agent any
    environment {
        REMOTE_SERVER = 'root@54.160.146.79'  // Remote server details
        REMOTE_PATH = '/opt/website_project'  // Directory on the server
        DOCKER_IMAGE_NAME = 'website_project'  // Docker image name
    }
    stages {
        stage('Checkout SCM') {
            steps {
                // Checkout code from Git repository
                checkout scm
            }
        }

        stage('Copy Files to Remote Server') {
            steps {
                // Use SSH agent to copy files to remote server
                sshagent(['docker-server']) {
                    sh '''
                    scp -r Dockerfile Jenkinsfile README.md assets error images index.html ${REMOTE_SERVER}:${REMOTE_PATH}/
                    '''
                }
            }
        }

        stage('Build Image') {
            steps {
                sshagent(['docker-server']) {
                    // Build the Docker image on the remote server
                    sh '''
                    ssh ${REMOTE_SERVER} << 'EOF'
                    cd ${REMOTE_PATH}
                    docker build -t ${DOCKER_IMAGE_NAME}:develop-${BUILD_NUMBER} .
                    EOF
                    '''
                }
            }
        }

        stage('Run Container') {
            steps {
                sshagent(['docker-server']) {
                    // Run the Docker container
                    sh '''
                    ssh ${REMOTE_SERVER} << 'EOF'
                    docker run -d -p 80:80 --name website_container ${DOCKER_IMAGE_NAME}:develop-${BUILD_NUMBER}
                    EOF
                    '''
                }
            }
        }

        stage('Test Website') {
            steps {
                // Test the website to ensure it's running
                sshagent(['docker-server']) {
                    sh '''
                    ssh ${REMOTE_SERVER} << 'EOF'
                    curl -s http://localhost | grep "Welcome"
                    EOF
                    '''
                }
            }
        }

        stage('Push Image') {
            steps {
                sshagent(['docker-server']) {
                    // Push the Docker image to a Docker registry (e.g., Docker Hub)
                    sh '''
                    ssh ${REMOTE_SERVER} << 'EOF'
                    docker push ${DOCKER_IMAGE_NAME}:develop-${BUILD_NUMBER}
                    EOF
                    '''
                }
            }
        }
    }
    post {
        failure {
            // Clean up the workspace if the build fails
            cleanWs()
        }
    }
}
