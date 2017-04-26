sudo apt-get -y update
sudo apt-get -y upgrade
sudo apt-get -y install libcurl4-openssl-dev
cd /usr/local
wget http://download.newrelic.com/agent_sdk/nr_agent_sdk-v0.16.2.0-beta.x86_64.tar.gz -O /tmp/nr.tgz
sudo tar --strip-components=1 -zxvf /tmp/nr.tgz
udo ldconfig
