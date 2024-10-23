#!/bin/bash
apk add docker
rc-update add docker
service docker start
sleep 3
docker run hello-world
