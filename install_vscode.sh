#!/bin/bash
MIRTE_SRC_DIR=/usr/local/src/mirte

cd $MIRTE_SRC_DIR
mkdir vscode
cd vscode
wget https://gist.githubusercontent.com/b01/0a16b6645ab7921b0910603dfb85e4fb/raw/ea48d972a176b90b3956de59eb7a43da9be86ec5/download-vs-code-server.sh
chmod +x download-vs-code-server.sh
sudo -u mirte $MIRTE_SRC_DIR/vscode/download-vs-code-server.sh

# For the website:
Wget -O vscode_cli.tar.gz https://az764295.vo.msecnd.net/stable/f1b07bd25dfad64b0167beb15359ae573aecd2cc/vscode_cli_alpine_arm64_cli.tar.gz
Tar -xvf vscode_cli.tar.gz
./code update

./code serve-web --port 8005 --host 0.0.0.0 --without-connection-token --accept-server-license-terms &
code_pid=$!
until [ "$(wget -qO- http://localhost:8005/ | wc --bytes )" -gt "1000" ]; do
    sleep 5
done
kill $code_pid

#  TODO: add system to start it!