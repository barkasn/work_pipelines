FROM ubuntu:18.04
RUN apt-get update
RUN apt-get -y install default-jre wget
RUN wget https://github.com/COMBINE-lab/salmon/releases/download/v1.6.0/salmon-1.6.0_linux_x86_64.tar.gz
RUN tar xvzf salmon-1.6.0_linux_x86_64.tar.gz
RUN mkdir /opt/salmon
RUN mv salmon-1.6.0_linux_x86_64/* /opt/salmon/
