#!/bin/bash

CONFIG_FILE="/etc/letsencrypt_container_service.conf"

# Check for the existence of the configuration file
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "Error: Configuration file $CONFIG_FILE not found."
    exit 1
fi

# Load settings from the configuration file
source "$CONFIG_FILE"

# Check that the variables are set
if [[ -z "$BASE_DIR" || -z "$CERTBOT_IMAGE" || -z "$DOMAIN" ]]; then
    echo "Error: The configuration file is missing required parameters."
    exit 1
fi

# Run certbot with the given parameters
podman run -it --rm \
    -u 55002:55002 \
    -v "$BASE_DIR/cloudflare.ini:/cloudflare.ini:Z" \
    -v "$BASE_DIR/etc/letsencrypt/:/etc/letsencrypt:Z" \
    -v "$BASE_DIR/var/lib/letsencrypt:/var/lib/letsencrypt:Z" \
    -v "$BASE_DIR/var/log:/var/log:Z" \
    "$CERTBOT_IMAGE" renew \
    --dns-cloudflare \
    --dns-cloudflare-credentials /cloudflare.ini

# Path to certificates
CERT_DIR="$BASE_DIR/etc/letsencrypt/live/$DOMAIN"
PEM_FILE="$BASE_DIR/etc/letsencrypt/ejabberd/ejabberd.pem"

# Check that the certificates were received
if [[ -f "$CERT_DIR/fullchain.pem" && -f "$CERT_DIR/privkey.pem" ]]; then
    # Create a directory for ejabberd if it doesn't exist
    mkdir -p "$BASE_DIR/etc/letsencrypt/ejabberd"

    # Combine the certificate and key into one file
    cat "$CERT_DIR/fullchain.pem" "$CERT_DIR/privkey.pem" > "$PEM_FILE"

    echo "Certificate successfully created: $PEM_FILE"
else
    echo "Error: Certificates not found for $DOMAIN."
fi

