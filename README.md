# 1. Prerequisites
Before starting, ensure you have the following:

1. Git Repository:

    Your JobsSync application code is hosted on a Git repository (e.g., GitHub, GitLab, Bitbucket).

2. Jenkins:

    Jenkins is installed and running on your local machine or server.

3. Maven:

    Maven is installed and configured on the Jenkins server.

4. Docker:

    Docker is installed on the Jenkins server.

5. AWS Account:

    You have an AWS account with access to ECR (Elastic Container Registry) and S3.

6. PostgreSQL:

    PostgreSQL is available for testing and deployment (can be run locally or in a Docker container).<br>


# 2. Step-by-Step CI/CD Pipeline Setup
### Step 1: Set Up Jenkins

1. Install Jenkins:

Follow the installation steps for your operating system (Windows, macOS, or Linux) as described earlier.

2. Install Required Plugins:

Go to Manage Jenkins → Manage Plugins → Available.

Install the following plugins:

Git

Maven Integration

Docker

AWS ECR

Email Extension

Configure Global Tools:

Go to Manage Jenkins → Global Tool Configuration.

Set up:

JDK: Install JDK 8 (or the version specified in your pom.xml).

Git: Ensure Git is installed and configured.

Maven: Install Maven (e.g., version 3.8.6).

Configure AWS Credentials:

Go to Manage Jenkins → Manage Credentials.

Add your AWS credentials (Access Key ID and Secret Access Key).