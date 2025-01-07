# **JobsSync CI/CD Pipeline**

This document provides step-by-step instructions to set up a **CI/CD pipeline** for the **JobsSync application** using **Jenkins, Maven, Docker, AWS ECR, and S3**. The pipeline includes **auto-versioning** for WAR files in S3 and Docker images.

---

## **Table of Contents**
1. [Prerequisites](#prerequisites)
2. [Pipeline Overview](#pipeline-overview)
3. [Step-by-Step Setup](#step-by-step-setup)
   - [Step 1: Set Up Jenkins](#step-1-set-up-jenkins)
   - [Step 2: Create a Jenkins Pipeline](#step-2-create-a-jenkins-pipeline)
   - [Step 3: Create the Jenkinsfile](#step-3-create-the-jenkinsfile)
   - [Step 4: Set Up Docker](#step-4-set-up-docker)
   - [Step 5: Set Up AWS ECR and S3](#step-5-set-up-aws-ecr-and-s3)
   - [Step 6: Run the Pipeline](#step-6-run-the-pipeline)
   - [Step 7: Deploy the Application](#step-7-deploy-the-application)
4. [Pipeline Flow](#pipeline-flow)
5. [Troubleshooting](#troubleshooting)
6. [Contact](#contact)

---

## **Prerequisites**
Before starting, ensure you have the following:
1. **Git Repository**: Hosted on GitHub, GitLab, or Bitbucket.
2. **Jenkins**: Installed and running on your local machine or server.
3. **Maven**: Installed and configured on the Jenkins server.
4. **Docker**: Installed on the Jenkins server.
5. **AWS Account**: With access to **ECR** and **S3**.
6. **PostgreSQL**: Available for testing and deployment.

---

## **Pipeline Overview**
The CI/CD pipeline performs the following steps:
1. **Checkout Code**: Pull the latest code from the Git repository.
2. **Build with Maven**: Compile the code and generate a WAR file.
3. **Run Unit Tests**: Execute unit tests using Maven.
4. **Build Docker Image**: Create a Docker image for the application.
5. **Push Docker Image to AWS ECR**: Upload the Docker image to AWS Elastic Container Registry.
6. **Upload WAR File to S3**: Upload the WAR file to an S3 bucket with versioning enabled.
7. **Deploy to EC2**: Deploy the Docker image to an EC2 instance.

---

## **Step-by-Step Setup**

### **Step 1: Set Up Jenkins**
1. **Install Jenkins**:
   - Download and install Jenkins from the [official website](https://www.jenkins.io/download/).
   - Follow the installation instructions for your operating system.

2. **Install Required Plugins**:
   - Go to **Manage Jenkins** → **Manage Plugins** → **Available**.
   - Install the following plugins:
     - Git
     - Maven Integration
     - Docker
     - AWS ECR
     - Email Extension

3. **Configure Global Tools**:
   - Go to **Manage Jenkins** → **Global Tool Configuration**.
   - Set up:
     - **JDK**: Install JDK 8 (or the version specified in your `pom.xml`).
     - **Git**: Ensure Git is installed and configured.
     - **Maven**: Install Maven (e.g., version 3.8.6).

4. **Configure AWS Credentials**:
   - Go to **Manage Jenkins** → **Manage Credentials**.
   - Add your AWS credentials (Access Key ID and Secret Access Key).

---

### **Step 2: Create a Jenkins Pipeline**
1. **Create a New Pipeline Job**:
   - Go to **Jenkins Dashboard** → **New Item**.
   - Enter a name (e.g., `JobsSync-Pipeline`) and select **Pipeline**.
   - Click **OK**.

2. **Configure the Pipeline**:
   - In the pipeline configuration, scroll down to the **Pipeline** section.
   - Select **Pipeline script from SCM**.
   - Choose **Git** as the SCM.
   - Enter your Git repository URL (e.g., `https://github.com/your-repo/jobsync.git`).
   - Specify the branch (e.g., `main`).
   - Set the script path to `Jenkinsfile`.

3. **Save the Pipeline**.

---

### **Step 3: Create the Jenkinsfile**
1. **Create a `Jenkinsfile`** in the root of your Git repository.
2. **Add the following content** to the `Jenkinsfile`:

```groovy
pipeline {
    agent any

    environment {
        AWS_ACCOUNT_ID = 'your-aws-account-id'
        AWS_REGION = 'your-aws-region'
        ECR_REPOSITORY = 'jobsync-repo'
        APP_NAME = 'jobsync'
        S3_BUCKET = 'jobsync-artifacts'
        POSTGRES_USER = 'jobsync_user'
        POSTGRES_PASSWORD = 'jobsync_password'
        POSTGRES_DB = 'jobsync_db'
        EC2_INSTANCE_IP = 'your-ec2-instance-ip'
        EC2_SSH_USER = 'ec2-user'
        EC2_SSH_KEY = 'path/to/your/ssh/key.pem'
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
                    sh "aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
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
                    // SSH into the EC2 instance and deploy the Docker image
                    sshagent(['your-ssh-credentials-id']) {
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
            emailext body: 'The build succeeded!', subject: 'Build Success', to: 'your-email@example.com'
        }
        failure {
            emailext body: 'The build failed!', subject: 'Build Failure', to: 'your-email@example.com'
        }
    }
}
```

### **Step 4: Set Up Docker**
1. **Create a `Dockerfile`** in a directory named `docker` in your project root:
   ```dockerfile
   # Use an official Tomcat image as the base image
   FROM tomcat:9.0

   # Copy the WAR file into the Tomcat webapps directory
   COPY Mock.war /usr/local/tomcat/webapps/

   # Expose port 8081
   EXPOSE 8081

   # Start Tomcat
   CMD ["catalina.sh", "run"]
   ```
2. **Buid and test**

    - Build the Docker image:
    ```
    docker build -t jobsync:latest ./docker
    ```
    - Run the Docker container:
    ```
    docker run -d --name jobsync -p 8081:8081 jobsync:latest
    ```
    - Access the application at:
    ```
    http://localhost:8081
    ```
### **Step 5: Set Up AWS ECR and S3**
1. **Create an ECR Repository:**
    - Go to **AWS ECR** → **Create Repository**
    - Name the repository (e.g., `jobsync-repo`)

2. **Create an S3 Bucket:**

    - Go to **AWS S3** → **Create Bucket**
    - Name the bucket (e.g., `jobsync-artifacts`).
    - Enable Versioning for the bucket.

---

### **Step 6: Set Up EC2 Instance**
1. **Launch an EC2 Instance:**
    - Go to **AWS EC2** → **Launch Instance.**
    - Choose an Amazon Linux 2 AMI.
    - Configure the instance (e.g., `t2.micro`).
    - Add a security group that allows SSH (port 22) and HTTP (port 8081) access.
    - Launch the instance and download the SSH key pair (`.pem` file).

2. **Install Docker on EC2:**
    - SSH into the EC2 instance:
    ```
    ssh -i path/to/your/key.pem ec2-user@<ec2-instance-ip>
    ```
    - Install Docker:
    ```
    sudo yum update -y
    sudo amazon-linux-extras install docker -y
    sudo service docker start
    sudo usermod -a -G docker ec2-user
    ```

3. **Configure AWS CLI on EC2:**
    - Install AWS CLI:
    ```
    sudo yum install aws-cli -y
    ```
    - Configure AWS credentials:
    ```
    aws configure
    ```

---

### **Step 7: Run the Pipeline**
1. **Trigger the Pipeline:**
    - Manually trigger the pipeline by clicking Build Now in Jenkins.
    - Alternatively, configure the pipeline to trigger automatically on Git pushes (using webhooks).
    
2. **Monitor the Pipeline**
    - Check the pipeline logs in real-time to monitor progress.
    - Verify that:
        - **The WAR file is uploaded to S3 with a unique version tag.**
        - **The Docker image is pushed to AWS ECR with a unique version tag.**
        - **The application is deployed to the EC2 instance.**
---

### **Step 8: Deploy to EC2**
1. **Access the Application:**
    - Open your browser and go to:
    ```
    http://<ec2-instance-ip>:8081
    ```
---
### **Pipeline Flow**

1. Developer pushes code to the Git repository.
2. Jenkins triggers the pipeline:
    - Builds the WAR file using Maven.
    - Runs unit tests.
    - Builds and pushes the Docker image to AWS ECR with a unique version tag.
    - Uploads the WAR file to S3 with a unique version tag.
    - Deploys the Docker image to the EC2 instance.
3. Application is accessible on the EC2 instance.

---

### **Troubleshooting**

- **Jenkins Build Fails:**
    - Check the Jenkins console output for errors.
    - Ensure all required plugins are installed.
- **Docker Build Fails:**
    - Verify the `Dockerfile` is correct.
    - Ensure Docker is installed and running on the Jenkins server.
- **AWS ECR Push Fails:**
    - Verify AWS credentials are correctly configured in Jenkins.
    - Ensure the ECR repository exists.
- **EC2 Deployment Fails:**
    - Verify the EC2 instance is running and accessible via SSH.
    - Ensure Docker is installed and running on the EC2 instance.

---

### **Contact**
For any questions or issues, please contact:
- ***Terukula Sai***: `codesai127.0.0.1@gmail.com`