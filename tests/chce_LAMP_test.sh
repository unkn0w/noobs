#!/bin/bash

set -euxo pipefail

apt install curl
EXPECTED_RESPONSE="2 + 2 = 4"
RESPONSE=$(curl -Ss localhost)

if [ "$EXPECTED_RESPONSE" = "$RESPONSE" ]; then
    echo "Response test passed"
else
    echo "Wrong response from server. Expected $EXPECTED_RESPONSE, received $RESPONSE"
    exit 1
fi
