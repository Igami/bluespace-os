#!/bin/bash

LIGHTBURN_URL=$(curl -s https://raw.githubusercontent.com/LightBurnSoftware/deployment/master/currentversion.json | jq -r '.unix64.file')
wget "$LIGHTBURN_URL" -O /tmp/lightburn.run
chmod +x /tmp/lightburn.run
/tmp/lightburn.run --quiet
rm /tmp/lightburn.run