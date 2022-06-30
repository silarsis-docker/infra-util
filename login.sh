#!/bin/bash
#
# Call this script with an account name and role name
# Source this rather than running it, so it exports the variables properly

ACCOUNT_NAME=$1
ROLE_NAME=$2

EXP=$(grep -l accessToken ~/.aws/sso/cache/* | xargs jq '.expiresAt' -r)
if [[ -z ${EXP} ]] || [[ ${EXP} < $(date --utc +"%Y-%m-0%dT%H:%M:%SZ") ]]; then
    aws sso login
fi

ACCESS_TOKEN=$(grep -l accessToken ~/.aws/sso/cache/* | xargs jq '.accessToken' -r)
if [[ -z ${ACCESS_TOKEN} ]]; then
    echo "Cannot find access token";
elif [[ -z ${ACCOUNT_NAME} ]]; then
    aws sso list-accounts --access-token=${ACCESS_TOKEN} | jq -r '.[][].accountName'
else
    ACCOUNT_ID=$(aws sso list-accounts --access-token=${ACCESS_TOKEN} | jq --arg ACCOUNT_NAME "${ACCOUNT_NAME}" -r '.[][] | select(.accountName==$ACCOUNT_NAME) | .accountId')
    if [[ -z ${ACCOUNT_ID} ]]; then
        echo "Cannot find account ID";
    elif [[ -z ${ROLE_NAME} ]]; then
        aws sso list-account-roles --account-id ${ACCOUNT_ID} --access-token ${ACCESS_TOKEN} | jq -r '.roleList[].roleName'
    else
        CREDS=$(aws sso get-role-credentials --account-id ${ACCOUNT_ID} --access-token ${ACCESS_TOKEN} --role-name ${ROLE_NAME})
        if [[ -z ${CREDS} ]]; then
            echo "Cannot get credentials";
        else
            export AWS_ACCESS_KEY_ID=$(echo ${CREDS} | jq -r '.roleCredentials.accessKeyId')
            export AWS_SECRET_ACCESS_KEY=$(echo ${CREDS} | jq -r '.roleCredentials.secretAccessKey')
            export AWS_SESSION_TOKEN=$(echo ${CREDS} | jq -r '.roleCredentials.sessionToken')
            echo "Done, if you sourced this the env variables are set"
        fi
    fi
fi