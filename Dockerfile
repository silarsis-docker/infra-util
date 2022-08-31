FROM amazonlinux:latest as installer
# Update yum and install pre-reqs for builds
RUN yum update -y -q \
    # pre-reqs for sqlite
    && yum install -y -q tar gzip make gcc expectk readline-devel \
    # pre-req for aws-cli
    && yum install -y -q unzip \
    && yum clean all
RUN ARCH=$(uname -p) \
    && curl "https://awscli.amazonaws.com/awscli-exe-linux-${ARCH}.zip" -o "/awscliv2.zip" \
    && unzip -q /awscliv2.zip \
    && rm -f /awscliv2.zip \
    && ./aws/install --bin-dir /aws-cli-bin/
RUN curl -o /sqlite.tgz https://www.sqlite.org/src/tarball/sqlite.tar.gz?r=release \
    && tar zxf /sqlite.tgz \
    && cd sqlite \
    && ./configure \
    && make
RUN ARCH=$(if [[ `uname -p` = "aarch64" || `uname -p` = "arm64" ]]; then echo "arm64"; else echo "amd64"; fi) \
    && curl https://releases.hashicorp.com/terraform/1.2.4/terraform_1.2.4_linux_${ARCH}.zip -o /terraform.zip \
    && unzip /terraform.zip
# RUN yum install -y -q golang
# RUN go install github.com/multiprocessio/dsq@latest


FROM amazonlinux:latest
RUN yum update -y -q \
    && yum install -y -q yum-utils less vim groff unzip python3 git tar jq sudo \
    && yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo \
    && yum install -y -q terraform || /bin/true # Terraform not available for arm64 yet \
    && yum install nmap # security tools \
    && yum clean all
RUN amazon-linux-extras install docker epel
RUN python3 -m pip install boto3 mypy typing_extensions pdbpp types-urllib3 c7n awswrangler
# Set python3 as the default python
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3.7 1 \
    && update-alternatives --install /usr/bin/pip pip /usr/bin/pip3.7 1
# Install packages from installer
COPY --from=installer /usr/local/aws-cli /usr/local/aws-cli
COPY --from=installer /aws-cli-bin /usr/local/bin
COPY --from=installer /sqlite/sqlite3 /usr/bin/sqlite3
COPY --from=installer /sqlite/.libs/libsqlite3.so.0.8.6 /usr/lib64/libsqlite3.so.0.8.6
COPY --from=installer /terraform /usr/bin/terraform
COPY login.sh /usr/bin/login.sh
RUN mkdir /var/run/.aws
# Setup the user
RUN useradd --create-home --shell /bin/bash kevin.littlejohn
RUN echo "kevin.littlejohn ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
USER kevin.littlejohn
WORKDIR /home/kevin.littlejohn
RUN ln -s /var/run/.aws ~/.aws \
    && echo 'alias login=". /usr/bin/login.sh"' >> ~/.bashrc \
    && echo 'echo ". login <accountname> <rolename> for AWS login"' >> ~/.bashrc \
    && echo 'echo "~/.aws/aliases.sh can be used to extend the list of aliases if needed"' >> ~/.bashrc \
    && echo '[[ -x ~/.aws/aliases.sh ]] && . ~/.aws/aliases.sh && alias | grep login' >> ~/.bashrc
# Configure git
RUN git config --global push.default simple \
    && git config --global user.name "Kevin Littlejohn" \
    && git config --global user.email "kevin@littlejohn.id.au"
