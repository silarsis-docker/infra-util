# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
        . /etc/bashrc
fi

# Uncomment the following line if you don't like systemctl's auto-paging feature:
# export SYSTEMD_PAGER=

# User specific aliases and functions
alias login=". /usr/bin/login.sh"
echo ". login <accountname> <rolename> for AWS login"
echo "~/.aws/aliases.sh on the host can be used to extend the list of aliases if needed"
echo "cat /CONTENTS.md for tips on what's available on here"
[[ -x ~/.aws/aliases.sh ]] && . ~/.aws/aliases.sh && alias | grep login
