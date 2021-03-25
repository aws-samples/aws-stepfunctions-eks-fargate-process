FROM amazoncorretto:11
WORKDIR /

ADD ./target/eks-stepfunction-java-app-1.0-SNAPSHOT.jar /app.jar

EXPOSE 8080

CMD ["java", "-jar", "app.jar"]
