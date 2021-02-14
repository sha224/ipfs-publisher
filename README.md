# IPFS Publisher
A tool to publish a static site to IPFS

## Installation
Ensure that you have curl, jq and yq installed. Clone this repository and install it simply by doing:
```
cp publish.sh /usr/local/bin/publish
```

## Usage
This script assumes that you are using Pinata as the pinning service and Cloudflare to manage your DNS records. So, you will need the API Keys with the proper permissions from these services.

In your static site project's directory, create a new file and name it publish.yaml. For the API keys/tokens, you are encouraged to use bash environment variables (prepend a $ before the variable name within the yaml file). Use the following template to fill in your details in publish.yaml:
```
domain: YOUR_WEBSITE_DOMAIN_NAME
dir: PUBLIC_DIRECTORY_TO_BE_PUBLISHED
command: STATIC_SITE_GENERATOR_COMMAND
pinata:
    jwtToken: JWT_TOKEN_FROM_PINATA
cloudflare:
  apiKey: API_KEY_FROM_CLOUDFLARE
  zoneId: ZONE_ID_FROM_CLOUDFLARE
```

Once you have the publish.yaml, you can just use `publish` to publish your site.
