# Build awscli, sqlite and terraform
FROM silarsis/infra-util-installer as installer

# Build our actual image
FROM amazonlinux:latest
RUN yum update -y -q \
    # Basics I want everywhere
    && yum install -y -q yum-utils less vim groff unzip python3 git tar jq sudo \
    # Security tooling
    && yum install -y -q nmap \
    && yum clean all
RUN amazon-linux-extras install docker epel
# Useful python modules
RUN python3 -m pip install boto3 mypy typing_extensions pdbpp types-urllib3 c7n awswrangler python-owasp-zap-v2.4 zapcli
# Set python3 as the default python
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3.7 1 \
    && update-alternatives --install /usr/bin/pip pip /usr/bin/pip3.7 1 \
    && sed -i 's|/usr/bin/python$|/usr/bin/python2|' /usr/bin/yum \
    && sed -i 's|/usr/bin/python$|/usr/bin/python2|' /usr/libexec/urlgrabber-ext-down
# Install packages from installer
COPY --from=installer /usr/local/aws-cli /usr/local/aws-cli
COPY --from=installer /aws-cli-bin /usr/local/bin
COPY --from=installer /sqlite/sqlite3 /usr/bin/sqlite3
COPY --from=installer /sqlite/.libs/libsqlite3.so.0.8.6 /usr/lib64/libsqlite3.so.0.8.6
COPY --from=installer /terraform /usr/bin/terraform
COPY --from=installer /zap /zap
COPY --from=installer /zap/webswing /zap/webswing
COPY login.sh /usr/bin/login.sh
RUN mkdir /var/run/.aws
# Setup the user
RUN useradd --create-home --shell /bin/bash kevin.littlejohn
RUN echo "kevin.littlejohn ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
USER kevin.littlejohn
WORKDIR /home/kevin.littlejohn
RUN mkdir .vnc
RUN ln -s /var/run/.aws ~/.aws \
    && echo 'alias login=". /usr/bin/login.sh"' >> ~/.bashrc \
    && echo 'echo ". login <accountname> <rolename> for AWS login"' >> ~/.bashrc \
    && echo 'echo "~/.aws/aliases.sh on the host can be used to extend the list of aliases if needed"' >> ~/.bashrc \
    && echo '[[ -x ~/.aws/aliases.sh ]] && . ~/.aws/aliases.sh && alias | grep login' >> ~/.bashrc
# Configure git
RUN git config --global push.default simple \
    && git config --global user.name "Kevin Littlejohn" \
    && git config --global user.email "kevin@littlejohn.id.au"
