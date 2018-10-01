FROM centos:centos7
RUN yum -y install java-1.8.0-openjdk-headless && yum -y clean all && mkdir /deployments
COPY todo-spring-be-0.0.1-SNAPSHOT.jar /deployments
RUN groupadd dev && useradd dev -g dev && chown -R dev:dev /deployments
USER dev
CMD ["java", "-showversion", "-jar", "/deployments/todo-spring-be-0.0.1-SNAPSHOT.jar"]