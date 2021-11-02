#!/bin/bash

#############################################################################
# Provide a preconfigured Curity Identity Server for running the code example
#############################################################################

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
cp ./license.json deployment/haapi/license.json
./deployment/haapi/start.sh
if [ $? -ne 0 ]; then
  echo 'Problem encountered deploying the Curity Identity Server'
  exit
fi

#
# Inform the user of the Curity Identity Server URL, to be copied to configuration
#
IDENTITY_SERVER_BASE_URL=$(cat './deployment/haapi/output.txt')
echo "Curity Identity Server is running at $IDENTITY_SERVER_BASE_URL"
