#!/bin/sh
yum install -y git jq
amazon-linux-extras install -y nginx1
pip3 install pipenv
echo "export PATH=\"\$PATH:/usr/local/bin"\" > localbin.sh
cd ~ec2-user/
cat > ~/.ssh/config << EOF
Host *
    StrictHostKeyChecking no
EOF
chmod 600 ~/.ssh/config
git clone https://github.com/spellingb/flask-aws-storage.git
cd flask-aws-storage
mkdir uploads
chown -R ec2-user:ec2-user .
cat > run.sh << EOF
#!/bin/sh
pipenv install
pipenv run pip3 install -r requirements.txt
REGION=\$(curl http://169.254.169.254/latest/meta-data/placement/region)
IID=\$(curl http://169.254.169.254/latest/meta-data/instance-id)
ENV=\$(aws --region \$REGION ec2 describe-tags --filters Name=resource-id,Values=\$IID | jq -r '.Tags[]|select(.Key == \"environment\")|.Value')
FLASK_ENV=\$ENV pipenv run flask run
EOF
chmod 755 run.sh
cat > /etc/systemd/system/imgmgr.service << EOF
[Unit]
Description=Image manager app
After=network.target
[Service]
User=ec2-user
WorkingDirectory=/home/ec2-user/flask-aws-storage
ExecStart=/home/ec2-user/flask-aws-storage/run.sh
Restart=always
[Install]
WantedBy=multi-user.target
EOF
sed -i s/lats-image-data/"${S3Bucket}"/ app.py
systemctl daemon-reload
systemctl start imgmgr
cat > /etc/nginx/conf.d/myapp.conf << EOF
server {
   listen 80;
   server_name localhost;
   client_max_body_size 10M;
   location / {
        proxy_set_header Host \$http_host;
        proxy_pass http://127.0.0.1:5000;
    }
}
EOF
systemctl restart nginx.service