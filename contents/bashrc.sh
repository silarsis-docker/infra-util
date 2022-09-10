# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
        . /etc/bashrc
fi

# Fix git
[[ -v WORKSPACE_FOLDER ]] && git config --global --add safe.directory ${WORKSPACE_FOLDER}

# Fix docker
sudo /usr/local/bin/fix_docker.sh

# Fix X11
. /usr/local/bin/fix_x11.sh

# User specific aliases and functions
alias login=". /usr/local/bin/login.sh"
echo ". login <accountname> <rolename> for AWS login"
echo "~/.aws/aliases.sh on the host can be used to extend the list of aliases if needed"
echo "cat /CONTENTS.md for tips on what's available on here"
[[ -x ~/.aws/aliases.sh ]] && . ~/.aws/aliases.sh && alias | grep login
echo