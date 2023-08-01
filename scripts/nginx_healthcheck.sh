#!/bin/bash

# Define the server URL
server_url="http://localhost:8080"

# Perform the health check using curl
response=$(curl -s -o /dev/null -w "%{http_code}" "$server_url")

# Check if curl encountered an error
if [ $? -ne 0 ]; then
    echo "0"
    exit 0
fi

if [ "$response" = "200" ]; then
    echo "1"
    exit 1
else
    echo "0"
    exit 0
fi
