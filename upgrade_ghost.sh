#! /bin/bash

GHOST=/var/www/ghost
TMP=$(mktemp -d)

echo "Downloading latest Ghost ..."
curl -LOk https://ghost.org/zip/ghost-latest.zip

echo "Unzip ..."
unzip ghost-latest.zip -d $TMP

echo "Deleting obsolete files ..."
rm -fr $GHOST/core
rm -fr $GHOST/index.js
rm -fr $GHOST/node_modules
rm -fr $GHOST/*.json

echo "Copying new files ..."
cp -r $TMP/core $GHOST
cp -r $TMP/index.js $GHOST
cp -r $TMP/*.json $GHOST

echo "Creating tmp swap file"
dd if=/dev/zero of=$TMP/swapfile bs=1024 count=1024k
mkswap $TMP/swapfile
swapon $TMP/swapfile

echo "Installing ..."
CWD=$(pwd)
cd $GHOST
npm install --production
cd $CWD

echo "Cleaning ..."
rm -fr $TMP


