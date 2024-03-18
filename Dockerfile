FROM  eclipse-temurin:18
ARG JAR_FILE=target/*.jar
COPY resources ./resources
COPY ${JAR_FILE} jira-1.0.jar
ENTRYPOINT ["java","-jar","/jira-1.0.jar", "--spring.profiles.active=prod"]