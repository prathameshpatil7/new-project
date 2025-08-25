# Stage 1: Build the application using a Maven base image
FROM maven:3.9.6-eclipse-temurin-17 AS build

WORKDIR /app

COPY . .

RUN mvn clean package -DskipTests

# Stage 2: Create the final, lightweight image using a Tomcat base image
FROM tomcat:9.0-jdk17-temurin

RUN rm -rf /usr/local/tomcat/webapps/*

COPY --from=build /app/target/petclinic.war /usr/local/tomcat/webapps/

# The application will run on port 8080 inside the container
EXPOSE 8080

CMD ["catalina.sh", "run"]
