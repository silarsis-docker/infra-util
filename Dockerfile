# Build awscli, sqlite and terraform
FROM silarsis/infra-util-installer as installer

# Build our actual image
FROM amazonlinux:latest
RUN yum update -y -q \
    # Basics I want everywhere
    && yum install -y -q yum-utils less vim groff unzip python3 git tar jq sudo bzip2 \
    && amazon-linux-extras install docker epel \
    # Security tooling
    && yum install -y -q nmap xmlstarlet java-latest-openjdk gmp openssl bzip2-libs libpcap \
    && yum clean all
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
COPY --from=installer /zap /opt/zap
COPY --from=installer /john/run /opt/john
COPY login.sh /usr/bin/login.sh
RUN chmod +x /usr/bin/login.sh
COPY CONTENTS.md /CONTENTS.md
RUN mkdir /var/run/.aws
# Setup the user
RUN useradd --create-home --shell /bin/bash kevin.littlejohn
RUN echo "kevin.littlejohn ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
COPY bashrc.sh /home/kevin.littlejohn/.bashrc
RUN chown kevin.littlejohn /home/kevin.littlejohn/.bashrc && chmod +x /home/kevin.littlejohn/.bashrc
USER kevin.littlejohn
WORKDIR /home/kevin.littlejohn
RUN mkdir .vnc
RUN ln -s /var/run/.aws ~/.aws 
RUN git clone --depth 1 https://github.com/danielmiessler/SecLists.git
# Configure git
RUN git config --global push.default simple \
    && git config --global user.name "Kevin Littlejohn" \
    && git config --global user.email "kevin@littlejohn.id.au"
