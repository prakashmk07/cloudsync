pipeline {
    agent any

    environment {
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
                    env.VERSION_TAG = "${BUILD_ID}-${new Date().format('yyyyMMddHHmmss')}"
                    echo "Generated Version Tag: ${env.VERSION_TAG}"
                    
                    sh 'ls -la target/'
                    sh 'mkdir -p docker && cp target/Mock.war docker/'
                    sh "docker build -t ${DOCKER_HUB_REPO}:${env.VERSION_TAG} ./docker"
                }
            }
        }

        stage('Push Docker Image to Docker Hub') {         
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'docker-hub-creds', 
                    usernameVariable: 'DOCKER_USER', 
                    passwordVariable: 'DOCKER_PASS'
                )]) {
                    script {
                        sh """
                            docker login -u \$DOCKER_USER --password-stdin <<< \$DOCKER_PASS
                            docker tag ${DOCKER_HUB_REPO}:${env.VERSION_TAG} \$DOCKER_USER/${DOCKER_HUB_REPO}:${env.VERSION_TAG}
                            docker push \$DOCKER_USER/${DOCKER_HUB_REPO}:${env.VERSION_TAG}
                        """
                    }
                }
            }
        }

        stage('Deploy to EC2') {
            steps {
                withCredentials([
                    sshUserPrivateKey(
                        credentialsId: 'deployment-server',
                        keyFileVariable: 'SSH_KEY_FILE'
                    ),
                    usernamePassword(
                        credentialsId: 'docker-hub-creds',
                        usernameVariable: 'DOCKER_USER',
                        passwordVariable: 'DOCKER_PASS'
                    )
                ]) {
                    script {
                        sh """
                            chmod 400 \$SSH_KEY_FILE
                            ssh -o StrictHostKeyChecking=no -i \$SSH_KEY_FILE ${EC2_SSH_USER}@${EC2_INSTANCE_IP} "
                                # Docker Hub login
                                echo \$DOCKER_PASS | docker login -u \$DOCKER_USER --password-stdin

                                # Deployment commands
                                docker pull \$DOCKER_USER/${DOCKER_HUB_REPO}:${env.VERSION_TAG}
                                docker stop ${APP_NAME} || true
                                docker rm ${APP_NAME} || true
                                docker run -d \\
                                    --name ${APP_NAME} \\
                                    -p 8081:8081 \\
                                    \$DOCKER_USER/${DOCKER_HUB_REPO}:${env.VERSION_TAG}

                                # Verify deployment
                                sleep 10
                                curl -s localhost:8081 || echo 'Application not responding'
                            "
                        """
                    }
                }
            }
        }
    }

    post {
        success {
            emailext body: 'The build and deployment succeeded!', 
                     subject: 'Build Success', 
                     to: 'prakashmurugaiya07@gmail.com'
        }
        failure {
            emailext body: "The build or deployment failed. Please check the Jenkins logs for details.", 
                     subject: 'Build Failure', 
                     to: 'prakashmurugaiya07@gmail.com'
        }
    }
}
