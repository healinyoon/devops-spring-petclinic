FROM openjdk:8-jdk
MAINTAINER healin.yoon@gmail.com

RUN useradd -u 1000 appuser
USER appuser
COPY --chown=appuser:appuser ./spring-petclinic/target ./target
WORKDIR /
ENTRYPOINT java -Dspring.profiles.active=mysql -jar target/*.jar
