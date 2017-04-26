sudo apt-get -y install libcurl4-openssl-dev
cd /usr/local
wget http://download.newrelic.com/agent_sdk/nr_agent_sdk-v0.16.2.0-beta.x86_64.tar.gz -O /tmp/nr.tgz
sudo tar --strip-components=1 -zxvf /tmp/nr.tgz
sudo ldconfig
rm /tmp/nr.tgz
echo "LICENSE KEY:"
read LIC
echo "APP NAME:"
read APPNAME
echo "LANG (Swift):"
read LANG
echo "LANG VERSION (3.1):"
read LANGVER
FILE=/tmp/newrelic.service
echo "[Unit]" > $FILE
echo "Description=New Relic Collector Client Daemon" >> $FILE
echo "[Service]" >> $FILE
echo "Type=simple" >> $FILE
echo "WorkingDirectory=/tmp" >> $FILE
echo "ExecStart=/usr/local/bin/newrelic-collector-client-daemon" >> $FILE
echo "Restart=always" >> $FILE
echo "PIDFile=/var/run/newrelic.pid" >> $FILE
echo "Environment=NEWRELIC_LICENSE_KEY=$LIC" >> $FILE
echo "Environment=NEWRELIC_APP_NAME=$APPNAME" >> $FILE
echo "Environment=NEWRELIC_APP_LANGUAGE=$LANG" >> $FILE
echo "Environment=NEWRELIC_APP_LANGUAGE_VERSION=$LANGVER" >> $FILE
SVC=/usr/local/etc/newrelic.service
sudo mv $FILE /usr/local/etc
sudo chmod go-rwx $SVC
sudo systemctl disable $SVC >> /dev/null
sudo systemctl disable newrelic >> /dev/null
sudo systemctl enable $SVC
sudo systemctl start newrelic
