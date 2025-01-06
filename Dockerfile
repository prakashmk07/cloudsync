# Use an official Tomcat image as the base image
FROM tomcat:9.0

# Copy the WAR file into the Tomcat webapps directory
COPY Mock.war /usr/local/tomcat/webapps/

# Expose port 8081
EXPOSE 8081

# Start Tomcat
CMD ["catalina.sh", "run"]