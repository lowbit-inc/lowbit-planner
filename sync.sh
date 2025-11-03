#!/bin/bash

git fetch -p -P
git pull
git add .
git commit -m "Updating - $(date +%Y-%m-%dT%H:%M:%S)"
git push
