#!/usr/bin/env bash

export PATH=$PATH:/usr/local/bin

export DEBIAN_FRONTEND="noninteractive"
export PATH="$PATH:/usr/local/bin"

# install unzip and curl
echo "Installing dependencies ..."
apt-get update
apt-get -y install haproxy
apt-get -y install jq
wget -qO - https://www.mongodb.org/static/pgp/server-5.0.asc | sudo apt-key add -
echo "deb [ arch=amd64,arm64 ] http://repo.mongodb.com/apt/ubuntu bionic/mongodb-enterprise/5.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-enterprise.list
apt-get update
sudo apt-get install -y mongodb-enterprise


## add hosts to /etc/hosts
cat /vagrant/haproxy/host_enc >> /etc/hosts



# copy haproxy config file
echo "Copy haproxy config file"
cp /vagrant/haproxy/haproxy.cfg /etc/haproxy/haproxy.cfg
cp /vagrant/mongod/mongod.cfg /etc/mongod.conf

# copy certs for kmip 
mkdir /etc/mongo_kmip
cp /vagrant/certs/ca.pem /etc/mongo_kmip/ca.pem
cat /vagrant/certs/cert.pem /vagrant/certs/key.pem > /etc/mongo_kmip/client.pem

mv /vagrant/certs /tmp

systemctl daemon-reload
systemctl restart haproxy.service
sudo systemctl enable mongod
sudo systemctl start mongod

