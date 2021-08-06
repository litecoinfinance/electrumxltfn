OS Ubuntu 18.04


Prepare::

  sudo -s

  apt-get update && apt-get upgrade

  apt-get install python3-setuptools python3-multidict python3.7 python3.7-dev libleveldb-dev python3-setuptools python3-multidict gcc g++ libsnappy-dev zlib1g-dev libbz2-dev libgflags-dev build-essential python3-pip git

  python3.7 -m pip install aiohttp pylru plyvel Cython uvloop quark_hash

  git clone https://github.com/mraksoll4/electrumxltfn /opt/electrumxltfn

  cd /opt/electrumxltfn

  mkdir -p db

  groupadd -r electrumxltfn

  useradd -r -m -d /var/lib/electrumxltfn -k /dev/null -s /bin/false -g electrumxltfn electrumxltfn

  chown electrumxltfn:electrumxltfn /opt/electrumxltfn/db

  cp contrib/systemd/electrumxltfn.service /etc/systemd/system/

  ln -sf /opt/electrumxltfn/electrumxltfn_server.py /usr/local/bin/electrumxltfn_server.py

  ln -sf /opt/electrumxltfn/electrumxltfn.conf /etc/electrumxltfn.conf

Create SSL certificat::

  mkdir -p ssl

  cd ssl

  openssl genrsa -out server.key 2048
  openssl req -new -key server.key -out server.csr
  openssl x509 -req -days 1825 -in server.csr -signkey server.key -out server.crt

Give access to ssl folser and cert::

  chown -R electrumxltfn:electrumxltfn /opt/electrumxltfn/ssl

  cd ..

Create and edit config::

  nano /opt/electrumxltfn/electrumxltfn.conf

Config Example::

  COIN = LitecoinFinance
  DB_DIRECTORY = /opt/electrumxltfn/db
  DAEMON_URL = http://RPCUSER:RPCPASSWORD@IP:RPCPORT/
  SERVICES = tcp://:30001,rpc://:8001,ssl://:30002
  EVENT_LOOP_POLICY = uvloop
  PEER_DISCOVERY = self
  INITIAL_CONCURRENT = 50
  COST_SOFT_LIMIT = 10000
  COST_HARD_LIMIT = 100000
  BANDWIDTH_UNIT_COST = 10000
  SSL_CERTFILE = /opt/electrumxltfn/ssl/server.crt
  SSL_KEYFILE = /opt/electrumxltfn/ssl/server.key

Give access to config::

  chown root:electrumxltfn /opt/electrumxltfn/electrumxltfn.conf
  chmod 640 /opt/electrumxltfn/electrumxltfn.conf

Install server::

  python3.7 setup.py install


Start::

  systemctl start electrumxltfn

Stop::

  systemctl stop electrumxltfn

Autorun::

  systemctl enable electrumxltfn

Logs::

  journalctl -u electrumxltfn -f
