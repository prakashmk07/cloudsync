# Use an official Tomcat image as the base image
FROM tomcat:9.0

# Set the working directory inside the container
WORKDIR /usr/local/tomcat

# Copy the WAR file from the target directory to the Tomcat webapps directory
COPY ../target/Mock.war webapps/

# Expose port 8081
EXPOSE 8081

# Update the Tomcat server configuration to run on port 8081
RUN sed -i 's/port="8080"/port="8081"/' conf/server.xml

# Start Tomcat when the container starts
CMD ["catalina.sh", "run"]