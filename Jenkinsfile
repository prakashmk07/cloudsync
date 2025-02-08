pipeline {
    agent any

    environment {
        DOCKER_HUB_USER = 'pdeveopsh'
        DOCKER_HUB_REPO = 'jobssync'
        APP_NAME = 'jobsync'
        EC2_INSTANCE_IP = '13.126.83.225' 
        EC2_SSH_USER = 'ubuntu'
    }

    stages {
        stage('Checkout Git') {
            steps {
                checkout scm
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
                    versionTag = "${env.BUILD_ID}-${new Date().format('yyyyMMddHHmmss')}"
                    echo "Generated Version Tag: ${versionTag}"
                    sh 'cp target/Mock.war docker/'
                    docker.build("${env.DOCKER_HUB_USER}/${env.DOCKER_HUB_REPO}:${versionTag}", "./docker")
                }
            }
        }

        stage('Push Docker Image to Docker Hub') {         
            steps {
                withCredentials([usernamePassword(credentialsId: 'docker-hub-creds', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                    sh '''
                        echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
                    '''
                }
                sh "docker push ${DOCKER_HUB_USER}/${DOCKER_HUB_REPO}:${versionTag}"
            }
        }

        stage('Deploy to EC2') {
            steps {
                withCredentials([sshUserPrivateKey(credentialsId: 'deployment-server', keyFileVariable: 'SSH_KEY_FILE')]) {
                    script {
                        sh """
                            # Set permissions for the SSH key file
                            chmod 400 ${SSH_KEY_FILE}

                            # SSH into the EC2 instance and deploy the Docker container
                            ssh -o StrictHostKeyChecking=no -i ${SSH_KEY_FILE} ${EC2_SSH_USER}@${EC2_INSTANCE_IP} '
                                # Log in to Docker inside the EC2 instance
                                echo "${DOCKER_PASS}" | docker login -u "${DOCKER_USER}" --password-stdin

                                # Pull the Docker image from Docker Hub
                                docker pull ${DOCKER_HUB_USER}/${DOCKER_HUB_REPO}:${versionTag}

                                # Stop and remove the existing container (if any)
                                docker stop ${APP_NAME} || true
                                docker rm ${APP_NAME} || true

                                # Run the new container
                                docker run -d --name ${APP_NAME} -p 8081:8081 ${DOCKER_HUB_USER}/${DOCKER_HUB_REPO}:${versionTag}

                                # Verify the container is running
                                sleep 10
                                docker ps --filter "name=${APP_NAME}" --format "{{.Status}}"
                            '
                        """
                    }
                }
            }
        }
    }

    post {
        success {
            emailext body: 'The build and deployment succeeded!', subject: 'Build Success', to: 'codesai127.0.0.1@gmail.com'
        }
        failure {
            emailext body: "The build or deployment failed. Please check the Jenkins logs for details.", subject: 'Build Failure', to: 'codesai127.0.0.1@gmail.com'
        }
    }
}
