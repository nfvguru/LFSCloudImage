GIT_OK=git
SSL_OK=libssl-dev
COFFEE_OK=coffeescript
if dpkg --get-selections | grep -q "^$GIT_OK[[:space:]]*install$" >/dev/null; then
  echo "$GIT_OK is already installed"
  else
  echo installing git
  sudo apt-get --yes --force-yes install git
fi
if dpkg --get-selections | grep -q "^$SSL_OK[[:space:]]*install$" >/dev/null; then
  echo "$SSL_OK is already installed"
  else
  echo installing libssl-dev
  sudo apt-get --yes --force-yes install libssl-dev
fi
if dpkg --get-selections | grep -q "^$COFFEE_OK[[:space:]]*install$" >/dev/null; then
  echo "$COFFEE_OK is already installed"
  else
  echo installing coffee script
  sudo apt-get --yes --force-yes install coffeescript
fi
if dpkg --get-selections | grep sysstat >/dev/null; then
  echo "sysstat is already installed"
  else
  echo installing sysstat
  sudo apt-get --yes --force-yes install sysstat
fi
echo Environment setup completed.
echo installing nvm
echo Download nvm through git
git clone git://github.com/creationix/nvm.git ~/.nvm && echo "Downloaded nvm" || echo "Download failure"
. ~/.nvm/nvm.sh
nvm install v0.6.19
which node
echo installing npm
curl https://npmjs.org/install.sh | sh
which npm
npm install
npm install node-uuid
npm install dirty
echo process completed.Launch app
