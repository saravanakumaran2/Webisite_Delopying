pipeline {
    agent any

    environment {
        DOCKER_IMAGE_NAME = 'website_image'
        DOCKER_REGISTRY = 'dockerhub'  // Name of the Docker registry (Docker Hub)
        REMOTE_SERVER = 'root@54.160.146.79'
        REMOTE_PATH = '/opt/website_project/'
        SSH_KEY = credentials('docker-server')  // SSH private key credential for accessing the Docker server
        DOCKERHUB_CREDENTIALS = credentials('dockerhub-auth')  // DockerHub credentials (username and password)
    }

    stages {
        stage('Checkout SCM') {
            steps {
                checkout scm
            }
        }

        stage('Copy Files to Remote Server') {
            steps {
                sshagent([SSH_KEY]) {
                    sh """
                        scp -r Dockerfile Jenkinsfile README.md assets error images index.html ${REMOTE_SERVER}:${REMOTE_PATH}
                    """
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                sshagent([SSH_KEY]) {
                    sh """
                        ssh ${REMOTE_SERVER} '
                            cd ${REMOTE_PATH} && 
                            docker build -t ${DOCKER_IMAGE_NAME}:${GIT_COMMIT} .'
                    """
                }
            }
        }

        stage('Run Container') {
            steps {
                sshagent([SSH_KEY]) {
                    sh """
                        ssh ${REMOTE_SERVER} '
                            docker run -d -p 80:80 ${DOCKER_IMAGE_NAME}:${GIT_COMMIT}'
                    """
                }
            }
        }

        stage('Test Website') {
            steps {
                script {
                    // You can add logic to test your website here, e.g., using curl to check if the site is up
                    def result = sh(script: 'curl -s -o /dev/null -w "%{http_code}" http://localhost', returnStdout: true).trim()
                    if (result != '200') {
                        error "Website test failed with status code: ${result}"
                    }
                }
            }
        }

        stage('Push Image to DockerHub') {
            steps {
                script {
                    withCredentials([usernamePassword(credentialsId: 'dockerhub-auth', passwordVariable: 'DOCKER_PASSWORD', usernameVariable: 'DOCKER_USERNAME')]) {
                        sh """
                            docker login -u ${DOCKER_USERNAME} -p ${DOCKER_PASSWORD}
                            docker tag ${DOCKER_IMAGE_NAME}:${GIT_COMMIT} ${DOCKER_USERNAME}/${DOCKER_IMAGE_NAME}:${GIT_COMMIT}
                            docker push ${DOCKER_USERNAME}/${DOCKER_IMAGE_NAME}:${GIT_COMMIT}
                        """
                    }
                }
            }
        }
    }

    post {
        always {
            cleanWs()  // Clean up workspace after the pipeline finishes
        }
        success {
            echo 'Pipeline completed successfully!'
        }
        failure {
            echo 'Pipeline failed.'
        }
    }
}
