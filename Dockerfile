FROM amazonlinux:2 as installer
RUN yum update -y -q \
    && yum install -y -q unzip \
    && yum clean all
RUN uname -p
RUN ARCH=$(uname -p) \
    && echo $ARCH \
    && curl "https://awscli.amazonaws.com/awscli-exe-linux-${ARCH}.zip" -o "/awscliv2.zip" \
    && unzip -q /awscliv2.zip \
    && rm -f /awscliv2.zip \
    && ./aws/install --bin-dir /aws-cli-bin/
# RUN yum install -y -q golang
# RUN go install github.com/multiprocessio/dsq@latest

FROM amazonlinux:2

RUN yum update -y -q \
    && yum install -y -q yum-utils less vim groff unzip python3 git tar jq sudo \
    && yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo \
    && yum install -y -q terraform || /bin/true # Terraform not available for arm64 yet \
    && yum clean all
RUN amazon-linux-extras install docker epel
RUN python3 -m pip install boto3 mypy typing_extensions pdbpp types-urllib3 c7n
# Set python3 as the default python
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3.7 1 \
    && update-alternatives --install /usr/bin/pip pip /usr/bin/pip3.7 1
# Install aws-cli v2
COPY --from=installer /usr/local/aws-cli /usr/local/aws-cli
COPY --from=installer /aws-cli-bin /usr/local/bin
# Setup the user
RUN useradd --create-home --shell /bin/bash kevin.littlejohn

RUN echo "kevin.littlejohn ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
USER kevin.littlejohn
WORKDIR /home/kevin.littlejohn
# Configure git
RUN git config --global push.default simple \
    && git config --global user.name "Kevin Littlejohn" \
    && git config --global user.email "kevin@littlejohn.id.au"
