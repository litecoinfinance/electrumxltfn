#!/bin/sh
###############
# run_electrumxltfn
###############

# configure electrumxltfn
export COIN=Bitcoin
export DAEMON_URL=http://rpcuser:rpcpassword@127.0.0.1
export NET=mainnet
export CACHE_MB=400
export DB_DIRECTORY=/home/username/.electrumxltfn/db
export SSL_CERTFILE=/home/username/.electrumxltfn/certfile.crt
export SSL_KEYFILE=/home/username/.electrumxltfn/keyfile.key
export BANNER_FILE=/home/username/.electrumxltfn/banner
export DONATION_ADDRESS=your-donation-address

# connectivity
export HOST=
export TCP_PORT=50001
export SSL_PORT=50002

# visibility
export REPORT_HOST=hostname.com
export RPC_PORT=8000

# run electrumxltfn
ulimit -n 10000
/usr/local/bin/electrumxltfn_server 2>> /home/username/.electrumxltfn/electrumxltfn.log >> /home/username/.electrumxltfn/electrumxltfn.log &

######################
# auto-start electrumxltfn
######################

# add this line to crontab -e
# @reboot /path/to/run_electrumxltfn.sh
