#!/bin/bash

PINATA_API="https://api.pinata.cloud"
CLOUDFLARE_API="https://api.cloudflare.com/client/v4"

PUBLISH_FILE=publish.yaml

if [ ! -f "$PUBLISH_FILE" ]; then
    echo "Error: $PUBLISH_FILE not found"
    exit 1
fi

DOMAIN=$(cat $PUBLISH_FILE | yq e '.domain' - | envsubst)
DIR=$(cat $PUBLISH_FILE | yq e '.dir' - | envsubst)
COMMAND=$(cat $PUBLISH_FILE | yq e '.command' - | envsubst)
PINATA_TOKEN=$(cat $PUBLISH_FILE | yq e '.pinata.jwtToken' - | envsubst)
CLOUDFLARE_APIKEY=$(cat $PUBLISH_FILE | yq e '.cloudflare.apiKey' - | envsubst)
CLOUDFLARE_ZONEID=$(cat $PUBLISH_FILE | yq e '.cloudflare.zoneId' - | envsubst)

if [ "$COMMAND" != "null" ]; then
    ( "$COMMAND" )
fi

pin_name="site-$DOMAIN-dir"
old_hash=$(curl -s -X GET "$PINATA_API/data/pinList?metadata[name]=$pin_name" -H "Authorization: Bearer $PINATA_TOKEN" | jq -r '.rows[0].ipfs_pin_hash')

if [ "$old_hash" != "null" ]; then
    delete_status=$(curl -s -o /dev/null -w "%{http_code}" -X DELETE "$PINATA_API/pinning/unpin/$old_hash" -H "Authorization: Bearer $PINATA_TOKEN")
    if [ "$delete_status" = "200" ]; then
        echo "Old Content ($old_hash) has been unpinned"
    fi
fi

pushd $(dirname $DIR) > /dev/null
new_hash=$(curl -s -X POST "$PINATA_API/pinning/pinFileToIPFS" -H "Authorization: Bearer $PINATA_TOKEN" `echo $(find $(basename $DIR) -type f -exec echo "-F file=@{};filename={}" \;)` -F "pinataMetadata={\"name\": \"$pin_name\"}"| jq -r '.IpfsHash');
popd > /dev/null

if [ "$new_hash" != "null" ]; then
    echo "New Content ($new_hash) has been pinned"
    dnslink_record="_dnslink.$DOMAIN"
    dnslink_content="dnslink=/ipfs/$new_hash"
    dns_record_id=$(curl -s -X GET "$CLOUDFLARE_API/zones/$CLOUDFLARE_ZONEID/dns_records?name=$dnslink_record" -H "Authorization: Bearer $CLOUDFLARE_APIKEY" | jq -r ".result[0].id")
    if [ "$dns_record_id" != "null" ]; then
        update_success=$(curl -s -X PATCH "$CLOUDFLARE_API/zones/$CLOUDFLARE_ZONEID/dns_records/$dns_record_id" -d "{\"content\":\"$dnslink_content\"}" -H "Authorization: Bearer $CLOUDFLARE_APIKEY" | jq -r ".success")
        if [ "$update_success" = "true" ]; then
            echo "DNS record has been updated"
        else
            echo "DNS record could not be updated"
        fi
    else
        create_success=$(curl -s -X POST "$CLOUDFLARE_API/zones/$CLOUDFLARE_ZONEID/dns_records" -d "{\"type\": \"TXT\", \"name\": \"$dnslink_record\", \"content\": \"$dnslink_content\", \"ttl\": 1}" -H "Authorization: Bearer $CLOUDFLARE_APIKEY" | jq -r ".success")
        if [ "$create_success" = "true" ]; then
            echo "DNS record has been created"
        else
            echo "DNS record could not be created"
        fi
    fi
else
    echo "New Content could not be pinned"
fi
