node {
    // Define environment variables
    env.DOCKER_HUB_USER = 'sai127001'
    env.DOCKER_HUB_REPO = 'jobssync'
    env.APP_NAME = 'jobsync'
    env.S3_BUCKET = 'jobsync-artifacts'
    env.POSTGRES_USER = 'admin'
    env.POSTGRES_PASSWORD = 'admin'
    env.POSTGRES_DB = 'jobsync_db'
    env.EC2_INSTANCE_IP = '18.234.126.246'
    env.EC2_SSH_USER = 'ec2-user'

    // Define versionTag as a global variable
    def versionTag = ""

    try {
        stage('Checkout Git') {
            checkout scm
        }

        stage('Build with Maven') {
            sh 'mvn clean package'
        }

        stage('Run Unit Tests') {
            sh 'mvn test'
        }

        stage('Build Docker Image') {
            // Generate a unique version tag (e.g., Jenkins build ID + timestamp)
            versionTag = "${env.BUILD_ID}-${new Date().format('yyyyMMddHHmmss')}"
            echo "Generated Version Tag: ${versionTag}"

            // Copy the WAR file to the Docker build context
            sh 'cp target/Mock.war docker/'

            // Build the Docker image with the version tag
            docker.build("${env.DOCKER_HUB_USER}/${env.DOCKER_HUB_REPO}:${versionTag}", "./docker")
        }

        stage('Push Docker Image to Docker Hub') {
            // Authenticate with Docker Hub using Jenkins credentials
            withCredentials([usernamePassword(credentialsId: 'docker-hub-creds', usernameVariable: 'DOCKER_HUB_USER', passwordVariable: 'DOCKER_HUB_PASSWORD')]) {
                sh '''
                    echo $DOCKER_HUB_PASSWORD | docker login -u $DOCKER_HUB_USER --password-stdin
                '''
            }

            // Push the Docker image to Docker Hub
            sh "docker push ${env.DOCKER_HUB_USER}/${env.DOCKER_HUB_REPO}:${versionTag}"
        }

        stage('Upload WAR File to S3 with Versioning') {
            // Rename the WAR file with the version tag
            def warFileName = "${env.APP_NAME}-${versionTag}.war"
            sh "mv target/Mock.war target/${warFileName}"

            // Upload the WAR file to S3
            withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-creds', accessKeyVariable: 'AWS_ACCESS_KEY_ID', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY']]) {
                sh "aws s3 cp target/${warFileName} s3://${env.S3_BUCKET}/artifacts/"
            }
        }

        stage('Deploy to EC2') {
            // Use withCredentials to inject the SSH private key
            withCredentials([sshUserPrivateKey(credentialsId: 'ec2-ssh-key', keyFileVariable: 'SSH_KEY_FILE')]) {
                sh """
                    # Set permissions for the SSH key file
                    chmod 600 ${SSH_KEY_FILE}

                    # SSH into the EC2 instance and deploy the Docker container
                    ssh -o StrictHostKeyChecking=no -i ${SSH_KEY_FILE} ${env.EC2_SSH_USER}@${env.EC2_INSTANCE_IP} << 'EOF'
                    # Pull the Docker image from Docker Hub
                    docker pull ${env.DOCKER_HUB_USER}/${env.DOCKER_HUB_REPO}:${versionTag}

                    # Stop and remove the existing container (if any)
                    docker stop ${env.APP_NAME} || true
                    docker rm ${env.APP_NAME} || true

                    # Run the new container
                    docker run -d --name ${env.APP_NAME} -p 8081:8081 ${env.DOCKER_HUB_USER}/${env.DOCKER_HUB_REPO}:${versionTag}
                    EOF
                """
            }
        }

        // Send success email
        emailext body: 'The build succeeded!', subject: 'Build Success', to: 'codesai127.0.0.1@gmail.com'
    } catch (Exception e) {
        // Send failure email
        emailext body: "The build failed: ${e.getMessage()}", subject: 'Build Failure', to: 'codesai127.0.0.1@gmail.com'
        throw e // Re-throw the exception to mark the build as failed
    }
}