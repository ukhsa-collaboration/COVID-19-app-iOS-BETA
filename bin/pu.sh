#!/bin/bash

# Original implementation: https://github.com/tsif/pu.sh

set -euo pipefail

# Required environment variables:
#
# - TEAMID
# - KEYID
# - SECRET
# - BUNDLEID
# - DEVICETOKEN

PAYLOAD=""

if [ -z "$1" ]
  then
    PAYLOAD="{\"aps\":{\"content-available\" : 1, \"foo\":\"bar\"}}"
  else 
    PAYLOAD=$(<$1)
fi

function base64URLSafe {
  openssl base64 -e -A | tr -- '+/' '-_' | tr -d =
}

function sign {
  printf "$1"| openssl dgst -binary -sha256 -sign "$SECRET" | base64URLSafe
}

time=$(date +%s)
header=$(printf '{ "alg": "ES256", "kid": "%s" }' "$KEYID" | base64URLSafe)
claims=$(printf '{ "iss": "%s", "iat": %d }' "$TEAMID" "$time" | base64URLSafe)
jwt="$header.$claims.$(sign $header.$claims)"

# Development server: api.sandbox.push.apple.com:443
#
# Production server: api.push.apple.com:443

ENDPOINT=https://api.sandbox.push.apple.com:443
URLPATH=/3/device/

URL=$ENDPOINT$URLPATH$DEVICETOKEN

curl -v \
   --http2 \
   --header "authorization: bearer $jwt" \
   --header "apns-topic: ${BUNDLEID}" \
   --header "apns-push-type: background" \
   --header "apns-priority: 5" \
   --data "${PAYLOAD}" \
   "${URL}"
