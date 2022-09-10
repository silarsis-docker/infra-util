# infra-util

Utility container for infrastructure work

Dockerfile created with standard stuff I want in there.

Run it with `docker run --rm --mount source=$HOME/.aws,target=/home/kevin.littlejohn/.aws,type=bind -e AWS_PROFILE -it infra-util:latest`

Snippet for use in vscode:

```json
{
    "image": "silarsis/infra-util:latest",
	"name": "infra-util",
	"mounts": [
		"source=/var/run/docker.sock,target=/var/run/docker-host.sock,type=bind",
		"source=${localEnv:HOME}/.aws,target=/var/run/.aws,type=bind,consistency=cached",
		"source=/tmp/.X11-unix,target=/tmp/.X11-unix,type=bind",
		"source=${localEnv:HOME}/.ssh,target=/var/run/.ssh,type=bind,consistency=cached"
	],
    "containerEnv": {
        "AWS_PROFILE": "${localEnv:AWS_PROFILE}",
		"AWS_CONFIG_FILE": "/var/run/.aws/config",
		"AWS_SHARED_CREDENTIALS_FILE": "/var/run/.aws/credentials",
		"DISPLAY": "${localEnv:DISPLAY}",
		"WORKSPACE_FOLDER": "${containerWorkspaceFolder}"
    },
	"runArgs": ["--net=host"],
}
```

Note, this vscode snippet enables aws credential sharing with host, ssh config sharing with host, and X11.

