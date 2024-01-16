#!/bin/bash

#     Purpose: deploy an HTTP/S Server (running on port 8080)
#        Date:
#      Status:
# Assumptions:
#        Todo: I need to update this script to allow it to be run frequently (and update assets, if needed)

# https://anywhere.eks.amazonaws.com/docs/osmgmt/artifacts/
EKSA_RELEASE_VERSION=$(curl -sL https://anywhere-assets.eks.amazonaws.com/releases/eks-a/manifest.yaml | yq ".spec.latestVersion")
# EKSA_RELEASE_VERSION=v0.18.0
BUNDLE_MANIFEST_URL=$(curl -sL https://anywhere-assets.eks.amazonaws.com/releases/eks-a/manifest.yaml | yq ".spec.releases[] | select(.version==\"$EKSA_RELEASE_VERSION\").bundleManifestUrl")

cd /var/www/html
[ -f index.html ] && { sudo mv index.html index.html.orig; }

sudo mkdir /var/www/html/hookos-$EKSA_RELEASE_VERSION
sudo ln -s /var/www/html/hookos-$EKSA_RELEASE_VERSION  /var/www/html/hookos-latest
cd /var/www/html/hookos-latest
echo "<HTML><BODY>I'm HERE</BODY></HTML>" | sudo tee index.html

# vmlinuz
sudo curl -O -J $(curl -s $BUNDLE_MANIFEST_URL | yq ".spec.versionsBundles[0].tinkerbell.tinkerbellStack.hook.vmlinuz.amd.uri")
# initramfs
sudo curl -O -J $(curl -s $BUNDLE_MANIFEST_URL | yq ".spec.versionsBundles[0].tinkerbell.tinkerbellStack.hook.initramfs.amd.uri")

# Bottlerocket Image
cd /var/www/html
curl -s $BUNDLE_MANIFEST_URL | yq ".spec.versionsBundles[].eksD.raw.bottlerocket.uri" | sudo tee manifest-$EKSA_RELEASE_VERSION.txt
sudo curl -O -J $(tail -1 manifest-$EKSA_RELEASE_VERSION.txt)
