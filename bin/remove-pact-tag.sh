#!/bin/bash
set -e

function main() {

version=$1
version=$2

validate "$version" "version"
validate "$tag" "tag"
validate "$GITHUB_USER_TOKEN" "GITHUB_USER_TOKEN"

echo ""
echo "You are about to remove pact tag '$tag' for version '$version'"
echo ""
read -p "Are you sure? " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
   exit 1
fi

echo ""
read -p "Are you really sure? " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
   exit 1
fi

url="https://api.github.com/repos/nhsx/sonar-ios/dispatches"
contentType="Content-Type: application/json"
payload="{\"event_type\": \"remove-tag\", \"client_payload\": {\"version\": \"$version\", \"tag\": \"$tag\"}}"

echo ""
echo "Dispatching event: $payload"
echo ""

curl -i -u "$GITHUB_USER_TOKEN" -H "$contentType" -d "$payload" "$url"

}

function validate() {
  if [[ -z "$1" ]]; then
    >&2 echo "Unable to find the '$2'." 
    
    usage
    
    exit 1
  fi	  
}

function usage() {
  echo ""
  echo "Usage: $0 <version>"
  echo ""
}

main "$1"

