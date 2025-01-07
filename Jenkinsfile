pipeline {
    agent any

    environment {
        AWS_ACCOUNT_ID = '888958595564'
        AWS_REGION = 'us-east-1'
        ECR_REPOSITORY = 'jobsync-repo'
        APP_NAME = 'jobsync'
        S3_BUCKET = 'jobsync-artifacts'
        POSTGRES_USER = 'admin'
        POSTGRES_PASSWORD = credentials('admin') // Use Jenkins credentials
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
                    def dockerImage = docker.build("${APP_NAME}:${versionTag}", "./docker")
                }
            }
        }

        stage('Push Docker Image to AWS ECR') {
            steps {
                script {
                    // Authenticate Docker with AWS ECR
                    sh "aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

                    // Tag and push the Docker image
                    sh "docker tag ${APP_NAME}:${versionTag} ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPOSITORY}:${versionTag}"
                    sh "docker push ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPOSITORY}:${versionTag}"
                }
            }
        }

        stage('Upload WAR File to S3 with Versioning') {
            steps {
                script {
                    // Rename the WAR file with the version tag
                    def warFileName = "${APP_NAME}-${versionTag}.war"
                    sh "mv target/Mock.war target/${warFileName}"

                    // Upload the WAR file to S3
                    sh "aws s3 cp target/${warFileName} s3://${S3_BUCKET}/artifacts/"
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
                            # Pull the Docker image from ECR
                            aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com
                            docker pull ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPOSITORY}:${versionTag}

                            # Stop and remove the existing container (if any)
                            docker stop ${APP_NAME} || true
                            docker rm ${APP_NAME} || true

                            # Run the new container
                            docker run -d --name ${APP_NAME} -p 8081:8081 ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPOSITORY}:${versionTag}
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