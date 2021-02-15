# IPFS Publisher
A tool to build a static site, publish it to IPFS and update the dnslink record.

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
  jwtToken: $PINATA_TOKEN
cloudflare:
  apiKey: $CLOUDFLARE_KEY
  zoneId: $CLOUDFLARE_ZONEID
```

Once you have the publish.yaml, you can just use `publish` to publish your site.

## Usage as GitHub Action
This repository can be used as an action for your GitHub Actions Workflow. Below is an example showing how to use this action to publish your site every time you push changes.
```
on: [push]

jobs:
  ipfs_publisher_job:
    runs-on: ubuntu-latest
    name: A job to publish the static site to IPFS
    steps:
    - id: checkout
      uses: actions/checkout@v2
      with:
        submodules: true
    - id: publish
      uses: sha224/ipfs-publisher@v1
      env:
        DEFAULT_BRANCH: master
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        PINATA_TOKEN: ${{ secrets.PINATA_TOKEN }}
        CLOUDFLARE_KEY: ${{ secrets.CLOUDFLARE_KEY }}
        CLOUDFLARE_ZONEID: ${{ secrets.CLOUDFLARE_ZONEID }}
```
This goes inside `.github/workflows/main.yml` in your repository. Remember to populate the secrets in your repository settings.

Note that hugo is the only command supported out of the box right now. However, if you are using something else, you can add a step to install your static site generator package.
