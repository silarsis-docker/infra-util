FROM amazonlinux:latest as installer
RUN yum update -y \
    && yum install -y unzip \
    && yum clean all
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/awscliv2.zip" \
    && unzip /awscliv2.zip \
    && rm -f /awscliv2.zip \
    && ./aws/install --bin-dir /aws-cli-bin/

FROM amazonlinux:latest
RUN yum update -y \
    && yum install -y less vim groff unzip python3 git tar \
    && yum clean all
RUN amazon-linux-extras install docker
# Install aws-cli v2
COPY --from=installer /usr/local/aws-cli /usr/local/aws-cli
COPY --from=installer /aws-cli-bin /usr/local/bin
# Setup the user
RUN useradd --create-home --shell /bin/bash kevin.littlejohn
USER kevin.littlejohn
WORKDIR /home/kevin.littlejohn
# Configure git
RUN git config --global push.default simple \
    && git config --global user.name "Kevin Littlejohn" \
    && git config --global user.email "kevin@littlejohn.id.au"
