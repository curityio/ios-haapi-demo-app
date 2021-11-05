#!/bin/bash

####################################################################################################
# Run the Curity Identity Server in Docker on the local computer, preconfigured for the code example
# Please ensure that the following resources are installed before running this script:
# - Docker Desktop
# - ngrok
# - The jq tool (brew install jq)
####################################################################################################

#
# By default the Curity Identity Server will use a dynamic NGROK base URL
# Set USE_NGROK to false and provide an IP address based URL otherwise
#
USE_NGROK=true
BASE_URL=https://192.168.0.2:8443

#
# First check prerequisites
#
if [ ! -f './license.json' ]; then
  echo 'Please copy a license.json file into the root folder of the code example'
  exit 1
fi

#
# Download mobile deployment resources
#
if [ ! -d 'deployment' ]; then
  git clone https://github.com/curityio/mobile-deployments deployment
  if [ $? -ne 0 ]; then
    echo 'Problem encountered downloading deployment resources'
    exit
  fi
fi

#
# Run the deployment script to get an NGROK URL and deploy the Curity Identity Server 
#
cp ./license.json deployment/resources/license.json
./deployment/start.sh "$USE_NGROK" "$BASE_URL" "haapi"
if [ $? -ne 0 ]; then
  echo 'Problem encountered deploying the Curity Identity Server'
  exit
fi

#
# Inform the user of the Curity Identity Server URL, to be copied to configuration
#
IDENTITY_SERVER_BASE_URL=$(cat './deployment/output.txt')
echo "Curity Identity Server is running at $IDENTITY_SERVER_BASE_URL"
