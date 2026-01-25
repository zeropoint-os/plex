#!/bin/bash

# Test script for Plex container

# Get the IP address of the plex-main container
PLEX_IP=$(docker inspect plex-main --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' 2>/dev/null)

if [ -z "$PLEX_IP" ]; then
    echo "Error: plex-main container not found or not running"
    exit 1
fi

echo "Found plex-main at IP: $PLEX_IP"
echo "Testing Plex web endpoint..."
echo ""

# Simple health check - request the root endpoint
curl -sS --max-time 5 http://$PLEX_IP:32400/ || echo "Plex did not respond on port 32400"

echo ""
echo "Test complete!"
