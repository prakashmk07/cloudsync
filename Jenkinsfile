pipeline {
    agent any

    environment {
        DOCKER_HUB_USER = 'your-docker-hub-username' // Your Docker Hub username
        DOCKER_HUB_REPO = 'your-docker-hub-repo' // Your Docker Hub repository name
        APP_NAME = 'jobsync'
        POSTGRES_USER = 'admin'
        POSTGRES_PASSWORD = '#Sai9987886552'
        POSTGRES_DB = 'jobsync_db'
        EC2_INSTANCE_IP = '34.239.130.253'
        EC2_SSH_USER = 'ec2-user'
    }

    stages {
        stage('Checkout Git') {
            steps {
                git branch: 'master', url: 'https://github.com/SAI127001/JobsSync.git'
            }
        }

        stage('Build with Maven') {
            steps {
                sh 'mvn clean package'
            }
        }

        stage('Run Unit Tests') {
            steps {
                sh 'mvn test'
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    // Generate a unique version tag (e.g., Jenkins build ID + timestamp)
                    def versionTag = "${env.BUILD_ID}-${new Date().format('yyyyMMddHHmmss')}"

                    // Copy the WAR file to the Docker build context
                    sh 'cp target/Mock.war docker/'

                    // Build the Docker image with the version tag
                    def dockerImage = docker.build("${DOCKER_HUB_USER}/${DOCKER_HUB_REPO}:${versionTag}", "./docker")
                }
            }
        }

        stage('Push Docker Image to Docker Hub') {
            steps {
                script {
                    // Authenticate with Docker Hub
                    withCredentials([usernamePassword(credentialsId: 'docker-hub-creds', usernameVariable: 'DOCKER_HUB_USER', passwordVariable: 'DOCKER_HUB_PASSWORD')]) {
                        sh "echo ${DOCKER_HUB_PASSWORD} | docker login -u ${DOCKER_HUB_USER} --password-stdin"
                    }

                    // Push the Docker image to Docker Hub
                    sh "docker push ${DOCKER_HUB_USER}/${DOCKER_HUB_REPO}:${versionTag}"
                }
            }
        }

        stage('Deploy to EC2') {
            steps {
                script {
                    // Use SSH Agent Plugin to manage the SSH key
                    sshagent(['ec2-ssh-key']) {
                        sh """
                            ssh -o StrictHostKeyChecking=no -i ${EC2_SSH_KEY} ${EC2_SSH_USER}@${EC2_INSTANCE_IP} << 'EOF'
                            # Pull the Docker image from Docker Hub
                            docker pull ${DOCKER_HUB_USER}/${DOCKER_HUB_REPO}:${versionTag}

                            # Stop and remove the existing container (if any)
                            docker stop ${APP_NAME} || true
                            docker rm ${APP_NAME} || true

                            # Run the new container
                            docker run -d --name ${APP_NAME} -p 8081:8081 ${DOCKER_HUB_USER}/${DOCKER_HUB_REPO}:${versionTag}
                            EOF
                        """
                    }
                }
            }
        }
    }

    post {
        success {
            emailext body: 'The build succeeded!', subject: 'Build Success', to: 'codesai127.0.0.1@gmail.com'
        }
        failure {
            emailext body: 'The build failed!', subject: 'Build Failure', to: 'codesai127.0.0.1@gmail.com'
        }
    }
}