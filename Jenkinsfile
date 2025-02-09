pipeline {
    agent any

    environment {
        DOCKER_HUB_REPO = 'jobssync'  // Docker Hub repository name
        APP_NAME = 'jobsync'          // Application name
        EC2_INSTANCE_IP = '13.126.83.225'  // EC2 instance IP
        EC2_SSH_USER = 'ubuntu'       // SSH user for EC2
    }

    stages {
        // Stage 1: Checkout code from Git
        stage('Checkout Git') {
            steps {
                checkout scm  // Checkout code from the configured Git repository
            }
        }

        // Stage 2: Build the application with Maven
        stage('Build with Maven') {
            steps {
                sh 'mvn clean package'  // Build the Java application
            }
        }

        // Stage 3: Run unit tests
        stage('Run Unit Tests') {
            steps {
                sh 'mvn test'  // Run unit tests
            }
        }

        // Stage 4: Build Docker image
        stage('Build Docker Image') {
            steps {
                script {
                    // Generate a unique version tag for the Docker image
                    env.VERSION_TAG = "${BUILD_ID}-${new Date().format('yyyyMMddHHmmss')}"
                    echo "Generated Version Tag: ${env.VERSION_TAG}"

                    // Copy the WAR file to the Docker directory
                    sh 'ls -la target/'
                    sh 'mkdir -p docker && cp target/Mock.war docker/'

                    // Build the Docker image
                    sh "docker build -t ${DOCKER_HUB_REPO}:${env.VERSION_TAG} ./docker"
                }
            }
        }

        // Stage 5: Push Docker image to Docker Hub
        stage('Push Docker Image to Docker Hub') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'docker-hub-creds',  // Docker Hub credentials
                    usernameVariable: 'DOCKER_USER',    // Docker Hub username
                    passwordVariable: 'DOCKER_PASS'     // Docker Hub password
                )]) {
                    script {
                        sh """
                            # Log in to Docker Hub
                            docker login -u \$DOCKER_USER --password-stdin <<< \$DOCKER_PASS

                            # Tag the Docker image with the Docker Hub username
                            docker tag ${DOCKER_HUB_REPO}:${env.VERSION_TAG} \$DOCKER_USER/${DOCKER_HUB_REPO}:${env.VERSION_TAG}

                            # Push the Docker image to Docker Hub
                            docker push \$DOCKER_USER/${DOCKER_HUB_REPO}:${env.VERSION_TAG}
                        """
                    }
                }
            }
        }

        // Stage 6: Deploy to EC2 instance
        stage('Deploy to EC2') {
            steps {
                withCredentials([
                    // SSH key for accessing the EC2 instance
                    sshUserPrivateKey(
                        credentialsId: 'deployment-server',  // SSH credentials ID
                        keyFileVariable: 'SSH_KEY_FILE'      // SSH key file variable
                    ),
                    // Docker Hub credentials for pulling the image on EC2
                    usernamePassword(
                        credentialsId: 'docker-hub-creds',  // Docker Hub credentials
                        usernameVariable: 'DOCKER_USER',    // Docker Hub username
                        passwordVariable: 'DOCKER_PASS'     // Docker Hub password
                    )
                ]) {
                    script {
                        sh """
                            # Set permissions for the SSH key
                            chmod 400 \$SSH_KEY_FILE

                            # SSH into the EC2 instance and deploy the application
                            ssh -o StrictHostKeyChecking=no -i \$SSH_KEY_FILE ${EC2_SSH_USER}@${EC2_INSTANCE_IP} "
                                # Log in to Docker Hub
                                echo \$DOCKER_PASS | docker login -u \$DOCKER_USER --password-stdin

                                # Pull the latest Docker image
                                docker pull \$DOCKER_USER/${DOCKER_HUB_REPO}:${env.VERSION_TAG}

                                # Stop and remove the existing container (if any)
                                docker stop ${APP_NAME} || true
                                docker rm ${APP_NAME} || true

                                # Run the new Docker container
                                docker run -d \\
                                    --name ${APP_NAME} \\
                                    -p 8081:8081 \\
                                    \$DOCKER_USER/${DOCKER_HUB_REPO}:${env.VERSION_TAG}

                                # Verify the deployment
                                sleep 10  # Wait for the application to start
                                curl -s localhost:8081 || echo 'Application not responding'
                            "
                        """
                    }
                }
            }
        }
    }

    // Post-build actions
    post {
        success {
            // Send an email notification on success
            emailext body: 'The build and deployment succeeded!', 
                     subject: 'Build Success', 
                     to: 'prakashmurugaiya07@gmail.com'
        }
        failure {
            // Send an email notification on failure
            emailext body: "The build or deployment failed. Please check the Jenkins logs for details.", 
                     subject: 'Build Failure', 
                     to: 'prakashmurugaiya07@gmail.com'
        }
    }
}
