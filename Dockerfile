# syntax=docker/dockerfile:1
# Build a bunch of stuff we might want
FROM silarsis/infra-util-installer as installer

# Build our actual image
FROM amazonlinux:2.0.20230926.0
RUN yum update -y -q \
    # Basics I want everywhere
    && yum install -y -q yum-utils less vim groff unzip python3 git tar jq sudo bzip2 procps socat iputils \
        xorg-x11-server-utils wget p7zip \
    && amazon-linux-extras install docker epel \
    # Security tooling
    && yum install -y -q nmap xmlstarlet gmp openssl bzip2-libs libpcap bc checksec java-latest-openjdk java-latest-openjdk-devel \
         python3-devel openssl-devel libffi-devel gcc \
    && yum clean all
# Useful python modules - earlier unicorn for arm64 because it's currently broken otherwise
RUN if [[ `uname -p` = "aarch64" || `uname -p` = "arm64" ]]; then python3 -m pip install unicorn==1.0.3; fi \
    && python3 -m pip install boto3 mypy typing_extensions pdbpp types-urllib3 c7n awswrangler python-owasp-zap-v2.4 zapcli \
        pycryptodome pwntools
# Set python3 as the default python
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3.7 1 \
    && update-alternatives --install /usr/bin/pip pip /usr/bin/pip3.7 1 \
    && sed -i 's|/usr/bin/python$|/usr/bin/python2|' /usr/bin/yum \
    && sed -i 's|/usr/bin/python$|/usr/bin/python2|' /usr/libexec/urlgrabber-ext-down \
    && sed -i 's|/usr/bin/python$|/usr/bin/python2|' /usr/bin/repoquery
# Install packages from installer
# Network and general purpose tools
COPY --link --from=installer /usr/local/aws-cli /usr/local/aws-cli
COPY --link --from=installer /aws-cli-bin /usr/local/bin
COPY --link --from=installer /sqlite/sqlite3 /usr/bin/sqlite3
COPY --link --from=installer /sqlite/.libs/libsqlite3.so.0.8.6 /usr/lib64/libsqlite3.so.0.8.6
# Container-specific local scripts
COPY --link contents/login.sh /usr/local/bin/login.sh
COPY --link contents/fix_docker.sh /usr/local/bin/fix_docker.sh
COPY --link contents/fix_x11.sh /usr/local/bin/fix_x11.sh
COPY --link /contents/install.sh /usr/local/bin/install.sh
RUN chmod +x /usr/local/bin/login.sh /usr/local/bin/fix_docker.sh /usr/local/bin/fix_x11.sh /usr/local/bin/install.sh
COPY --link contents/CONTENTS.md /CONTENTS.md
RUN mkdir /var/run/.aws
# Setup the user - the specification of uid and gid is needed because the --link allows
# the bashrc copy to happen before the useradd, breaking things if you refer by name
RUN groupadd -g 1000 kevin.littlejohn \
    && useradd --create-home --shell /bin/bash -u 1000 -g 1000 kevin.littlejohn -G docker \
    && echo "kevin.littlejohn ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
COPY --link --chown=1000:1000 contents/bashrc.sh /home/kevin.littlejohn/.bashrc
RUN chmod +x /home/kevin.littlejohn/.bashrc
USER kevin.littlejohn
WORKDIR /home/kevin.littlejohn
RUN mkdir ~/.vnc \
    && ln -s /var/run/.aws ~/.aws \
    && ln -s /var/run/.ssh ~/.ssh
# Configure git
RUN git config --global push.default simple \
    && git config --global user.name "Kevin Littlejohn" \
    && git config --global user.email "kevin@littlejohn.id.au"
