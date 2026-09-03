FROM eclipse-temurin:21-jre-jammy
WORKDIR /app
RUN useradd --system --uid 10001 appuser
COPY target/railfleet-api-0.0.1-SNAPSHOT.jar app.jar
RUN chown -R appuser:appuser /app
USER 10001
EXPOSE 8080
ENTRYPOINT ["java","-XX:MaxRAMPercentage=75","-jar","app.jar"]