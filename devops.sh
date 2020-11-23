#!/bin/bash

# Application source code download and build
echo "**********************************************"
echo "**Application source code download and build**"
echo "**********************************************"
git clone https://github.com/spring-projects/spring-petclinic.git
cd spring-petclinic
./mvnw package

# Docker image build
echo "**********************"
echo "**Docker image build**"
echo "**********************"
cd ..
sudo docker build -t healinyoon/spring-petclinic:devops-spring-petclinic .
echo "*****************************"
echo "**Docker image build result**"
echo "*****************************"
sudo docker images | grep devops-spring-petclinic
