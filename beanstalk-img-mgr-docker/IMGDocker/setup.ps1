$env:FLASK_APP_NAME = 'flask-aws-storage'
if ( test-path $env:FLASK_APP_NAME ) {
    echo "Removing $env:FLASK_APP_NAME"
    Remove-Item $env:FLASK_APP_NAME -Recurse -Force
}
#git clone "https://github.com/spellingb/flask-aws-storage.git"
git clone "git@github.com:Jason-Glover/$env:FLASK_APP_NAME.git"
cp .\Dockerfile $env:FLASK_APP_NAME/
cp .\requirements.txt $env:FLASK_APP_NAME
cd $env:FLASK_APP_NAME
docker build -t img-mgr .