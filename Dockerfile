# Build awscli, sqlite and terraform
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
    && curl https://releases.hashicorp.com/terraform/1.2.8/terraform_1.2.8_linux_${ARCH}.zip -o /terraform.zip \
    && unzip /terraform.zip
# RUN yum install -y -q golang
# RUN go install github.com/multiprocessio/dsq@latest

# Build OWASP ZAP - stolen from https://github.com/zaproxy/zaproxy/blob/main/docker/Dockerfile-stable
FROM openjdk:8-jdk-alpine AS zap-builder
WORKDIR /zap
RUN apk add --no-cache curl wget xmlstarlet bash
# Download and expand the latest stable release
RUN wget -qO- https://raw.githubusercontent.com/zaproxy/zap-admin/master/ZapVersions.xml | xmlstarlet sel -t -v //url |grep -i Linux | wget --content-disposition -i - -O - | tar zxv && \
	mv ZAP*/* . && \
	rm -R ZAP*
# Update add-ons
RUN uname -p
RUN if [[ `uname -p` = "aarch64" || `uname -p` = "arm64" ]]; then echo "arm64 does not work yet"; else ./zap.sh -cmd -silent -addonupdate; fi
# Copy them to installation directory
RUN cp /root/.ZAP/plugin/*.zap plugin/ || :
# Setup Webswing
ENV WEBSWING_VERSION 22.1.3
ARG WEBSWING_URL=""
RUN if [ -z "$WEBSWING_URL" ] ; \
	then curl -s -L  "https://dev.webswing.org/files/public/webswing-examples-eval-${WEBSWING_VERSION}-distribution.zip" > webswing.zip; \
	else curl -s -L  "$WEBSWING_URL-${WEBSWING_VERSION}-distribution.zip" > webswing.zip; fi && \
	unzip webswing.zip && \
	rm webswing.zip && \
	mv webswing-* webswing && \
	# Remove Webswing bundled examples
	rm -Rf webswing/apps/

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
# Install OWASP zap from zap-builder
RUN useradd -d /home/zap -m -s /bin/bash zap
RUN echo zap:zap | chpasswd
RUN mkdir /zap && chown zap:zap /zap
WORKDIR /zap
#Change to the zap user so things get done as the right person (apart from copy)
USER zap
RUN mkdir /home/zap/.vnc
# Copy stable release
COPY --from=zap-builder /zap .
COPY --from=zap-builder /zap/webswing /zap/webswing
# Back to our own scheduled content
USER root
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
    && echo 'echo "~/.aws/aliases.sh on the host can be used to extend the list of aliases if needed"' >> ~/.bashrc \
    && echo '[[ -x ~/.aws/aliases.sh ]] && . ~/.aws/aliases.sh && alias | grep login' >> ~/.bashrc
# Configure git
RUN git config --global push.default simple \
    && git config --global user.name "Kevin Littlejohn" \
    && git config --global user.email "kevin@littlejohn.id.au"
