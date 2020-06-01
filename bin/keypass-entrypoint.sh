#!/bin/bash

echo "INFO: keypass entrypoint start"

[[ "${KEYPASS_DB_HOST_VALUE}" == "" ]] && KEYPASS_DB_HOST_VALUE=localhost:3306
# Default MySQL host name
[[ "${KEYPASS_DB_HOST_NAME}" == "" ]] && KEYPASS_DB_HOST_NAME=localhost
# Default MySQL port 3306
[[ "${KEYPASS_DB_HOST_PORT}" == "" ]] && KEYPASS_DB_HOST_PORT=3306
# DB_TIMEOUT in seconds. Default to 60 seconds
[[ "${KEYPASS_DB_TIMEOUT}" == "" ]] && export KEYPASS_DB_TIMEOUT=60

# Check argument DB_HOST if provided
while [[ $# -gt 0 ]]; do
    PARAM=`echo $1`
    VALUE=`echo $2`
    case "$PARAM" in
        -dbhost)
            KEYPASS_DB_HOST_VALUE=$VALUE
            KEYPASS_DB_HOST_NAME="$(echo "${KEYPASS_DB_HOST_VALUE}" | awk -F: '{print $1}')"
            KEYPASS_DB_HOST_PORT="$(echo "${KEYPASS_DB_HOST_VALUE}" | awk -F: '{print $2}')"
            ;;
        *)
            echo "not found"
            # Do nothing
            ;;
    esac
    shift
    shift
done

echo "INFO: MySQL endpoint <${KEYPASS_DB_HOST_VALUE}>"
echo "INFO: KEYPASS_DB_HOST_NAME <${KEYPASS_DB_HOST_NAME}>"
echo "INFO: KEYPASS_DB_HOST_PORT <${KEYPASS_DB_HOST_PORT}>"

sed -i "s/mysql:\/\/localhost/mysql:\/\/${KEYPASS_DB_HOST_VALUE}/g" /opt/keypass/config.yml

# Wait until DB is up or exit if timeout
# Current time in seconds
STARTTIME=$(date +%s)
while ! tcping -t 1 ${KEYPASS_DB_HOST_NAME} ${KEYPASS_DB_HOST_PORT}
do
    [[ $(($(date +%s) - ${KEYPASS_DB_TIMEOUT})) -lt ${STARTTIME} ]] || { echo "ERROR: Timeout MySQL endpoint <${KEYPASS_DB_HOST_NAME}:${KEYPASS_DB_HOST_PORT}>" >&2; exit 3; }
    echo "INFO: Wait for MySQL endpoint <${KEYPASS_DB_HOST_NAME}:${KEYPASS_DB_HOST_PORT}>"
    sleep 2
done
java -jar /opt/keypass/keypass.jar db migrate /opt/keypass/config.yml

java -jar /opt/keypass/keypass.jar server /opt/keypass/config.yml
