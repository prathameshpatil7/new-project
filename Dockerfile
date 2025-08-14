# Stage 1: Build the application using a Maven base image
# This stage compiles your Java code and packages it into a .war file.
FROM maven:3.8.5-openjdk-11 AS build
WORKDIR /app
COPY . .
RUN mvn clean package -DskipTests

# Stage 2: Create the final, lightweight image using a Tomcat base image
# This stage takes the .war file from the previous stage and puts it into Tomcat.
FROM tomcat:9.0-jdk17-corretto
# Remove the default Tomcat applications to keep the image clean
RUN rm -rf /usr/local/tomcat/webapps/*
# Copy the .war file created in the 'build' stage into Tomcat's webapps directory
COPY --from=build /app/target/petclinic.war /usr/local/tomcat/webapps/

# The application will run on port 8080 inside the container
EXPOSE 8080

# This is the command that starts the Tomcat server when the container runs
CMD ["catalina.sh", "run"]
