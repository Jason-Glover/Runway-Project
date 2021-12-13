#!/bin/sh
FLASK_APP_NAME=flask-aws-storage
REGION=us-west-2

if [ -d $FLASK_APP_NAME ]
then
  echo "Removing $FLASK_APP_NAME"
  rm -rvf $FLASK_APP_NAME
fi
git clone git@github.com:dianephan/$FLASK_APP_NAME.git
cp Dockerfile $FLASK_APP_NAME/
cp requirements.txt $FLASK_APP_NAME/
cd $FLASK_APP_NAME
docker build -t img-mgr .
