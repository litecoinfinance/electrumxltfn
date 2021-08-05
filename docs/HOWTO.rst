.. _HOWTO:

=====
HOWTO
=====

Prerequisites
=============

**ElectrumXLTFN** should run on any flavour of unix.  I have run it
successfully on MacOS and DragonFlyBSD.  It won't run out-of-the-box
on Windows, but the changes required to make it do so should be
small - pull requests are welcome.

================ ========================
Package          Notes
================ ========================
Python3          ElectrumXLTFN uses asyncio.  Python version >= 3.7 is
                 **required**.
`aiohttp`_       Python library for asynchronous HTTP.  Version >=
                 2.0 required.
`pylru`_         Python LRU cache package.
DB Engine        A database engine package is required; two are
                 supported (see `Database Engine`_ below).
================ ========================

Some coins need an additional package, typically for their block hash
functions. For example, `x11_hash`_ is required for DASH. Scrypt coins
require a Python interpreter compiled and/or linked with OpenSSL 1.1.0
or higher.

You **must** to be running a non-pruning bitcoin daemon with::

  txindex=1

set in its configuration file.  If you have an existing installation
of bitcoind and have not previously set this you will need to reindex
the blockchain with::

  bitcoind -reindex

which can take some time.

While not a requirement for running ElectrumXLTFN, it is intended to be
run with supervisor software such as Daniel Bernstein's
`daemontools`_, Gerrit Pape's `runit`_ package or :command:`systemd`.
These make administration of secure unix servers very easy, and I
strongly recommend you install one of these and familiarise yourself
with them.  The instructions below and sample run scripts assume
``daemontools``; adapting to ``runit`` should be trivial for someone
used to either.

When building the database from the genesis block, ElectrumXLTFN has to
flush large quantities of data to disk and its DB.  You will have a
better experience if the database directory is on an SSD than on an
HDD.  Currently to around height 611,600 of the Bitcoin blockchain the
final size of the leveldb database, and other ElectrumXLTFN file metadata
comes to just over 46.9GB (43.7 GiB).  LevelDB needs a bit more for
brief periods, and the block chain is only getting longer, so I would
recommend having at least 70-80GB of free space before starting.

Database Engine
===============

You can choose from LevelDB and RocksDB to store transaction
information on disk.  The time taken and DB size is not significantly
different.  We tried to support LMDB but its history write performance
was much worse.

You will need to install one of:

+ `plyvel <https://plyvel.readthedocs.io/en/latest/installation.html>`_ for LevelDB.

  Included as part of a regular pip or ``setup.py`` installation of ElectrumXLTFN.
+ `python-rocksdb <https://pypi.python.org/pypi/python-rocksdb>`_ for RocksDB

  ``pip3 install python-rocksdb`` or use the rocksdb extra install option to ElectrumXLTFN.
+ `pyrocksdb <http://pyrocksdb.readthedocs.io/en/v0.4/installation.html>`_ for an unmaintained version that doesn't work with recent releases of RocksDB

Running
=======

Install the prerequisites above.

Check out the code from Github::

    git clone https://github.com/spesmilo/electrumxltfn.git
    cd electrumxltfn

You can install with::

    pip3 install .

There are many extra Python dependencies available to fit the needs of your
system or coins. For example, to install the RocksDB dependencies and a faster
JSON parsing library::

    pip3 install .[rocksdb,ujson]

see setup.py's ``extra_requires`` for a complete list.

You can also run the code from the source tree or a copy of it.


You should create a standard user account to run the server under;
your own is probably adequate unless paranoid.  The paranoid might
also want to create another user account for the daemontools logging
process.  The sample scripts and these instructions assume it is all
under one account which I have called ``electrumxltfn``.

Next create a directory where the database will be stored and make it
writeable by the ``electrumxltfn`` account.  I recommend this directory
live on an SSD::

    mkdir /path/to/db_directory
    chown electrumxltfn /path/to/db_directory


Process limits
--------------

You must ensure the ElectrumXLTFN process has a large open file limit.
During sync it should not need more than about 1,024 open files.  When
serving it will use approximately 256 for LevelDB plus the number of
incoming connections.  It is not unusual to have 1,000 to 2,000
connections being served, so I suggest you set your open files limit
to at least 2,500.

Note that setting the limit in your shell does *NOT* affect ElectrumXLTFN
unless you are invoking ElectrumXLTFN directly from your shell.  If you
are using :command:`systemd`, you need to set it in the
:file:`.service` file (see `contrib/systemd/electrumxltfn.service`_).


Using daemontools
-----------------

Next create a daemontools service directory; this only holds symlinks
(see daemontools documentation).  The :command:`svscan` program will
ensure the servers in the directory are running by launching a
:command:`supervise` supervisor for the server and another for its
logging process.  You can run :command:`svscan` under the *electrumxltfn*
account if that is the only one involved (server and logger) otherwise
it will need to run as root so that the user can be switched to
electrumxltfn.

Assuming this directory is called :file:`service`, you would do one
of::

    mkdir /service       # If running svscan as root
    mkdir ~/service      # As electrumxltfn if running svscan as that a/c

Next create a directory to hold the scripts that the
:command:`supervise` process spawned by :command:`svscan` will run -
this directory must be readable by the :command:`svscan` process.
Suppose this directory is called :file:`scripts`, you might do::

    mkdir -p ~/scripts/electrumxltfn

Then copy the all sample scripts from the ElectrumXLTFN source tree there::

    cp -R /path/to/repo/electrumxltfn/contrib/daemontools ~/scripts/electrumxltfn

This copies 3 things: the top level server run script, a :file:`log/`
directory with the logger :command:`run` script, an :file:`env/`
directory.

You need to configure the :ref:`environment variables <environment>`
under :file:`env/` to your setup.  ElectrumXLTFN server currently takes no
command line arguments; all of its configuration is taken from its
environment which is set up according to :file:`env/` directory (see
:manpage:`envdir` man page).  Finally you need to change the
:command:`log/run` script to use the directory where you want the logs
to be written by multilog.  The directory need not exist as
:command:`multilog` will create it, but its parent directory must
exist.

Now start the :command:`svscan` process.  This will not do much as the
service directory is still empty::

    svscan ~/service & disown

svscan is now waiting for services to be added to the directory::

    cd ~/service
    ln -s ~/scripts/electrumxltfn electrumxltfn

Creating the symlink will kick off the server process almost immediately.
You can see its logs with::

    tail -F /path/to/log/dir/current | tai64nlocal


Using systemd
-------------

This repository contains a sample systemd unit file that you can use
to setup ElectrumXLTFN with systemd. Simply copy it to
:file:`/etc/systemd/system`::

    cp contrib/systemd/electrumxltfn.service /etc/systemd/system/

The sample unit file assumes that the repository is located at
:file:`/home/electrumxltfn/electrumxltfn`. If that differs on your system, you
need to change the unit file accordingly.

You need to set a few :ref:`environment variables <environment>` in
:file:`/etc/electrumxltfn.conf`.

Now you can start ElectrumXLTFN using :command:`systemctl`::

    systemctl start electrumxltfn

You can use :command:`journalctl` to check the log output::

    journalctl -u electrumxltfn -f

Once configured you may want to start ElectrumXLTFN at boot::

    systemctl enable electrumxltfn

.. Warning:: systemd is aggressive in forcibly shutting down
   processes.  Depending on your hardware, ElectrumXLTFN can need several
   minutes to flush cached data to disk during initial sync.  You
   should set TimeoutStopSec to *at least* 10 mins in your
   :file:`.service` file.


Installing on Raspberry Pi 3
----------------------------

To install on the Raspberry Pi 3 you will need to update to the
``stretch`` distribution.  See the full procedure in
`contrib/raspberrypi3/install_electrumxltfn.sh`_.

See also `contrib/raspberrypi3/run_electrumxltfn.sh`_ for an easy way to
configure and launch electrumxltfn.


Sync Progress
=============

Time taken to index the blockchain depends on your hardware of course.
As Python is single-threaded most of the time only 1 core is kept
busy.  ElectrumXLTFN uses Python's :mod:`asyncio` to prefill a cache of
future blocks asynchronously to keep the CPU busy processing the chain
without pausing.

Consequently there will probably be only a minor boost in performance
if the daemon is on the same host.  It may even be beneficial to have
the daemon on a *separate* machine so the machine doing the indexing
has its caches and disk I/O tuned to that task only.

The :envvar:`CACHE_MB` environment variable controls the total cache
size ElectrumXLTFN uses; see :ref:`here <CACHE>` for caveats.

Here is my experience with the codebase of early 2017 (the current
codebase is faster), to given heights and rough wall-time.  The period
from heights 363,000 to 378,000 is the most sluggish::

                 Machine A     Machine B
  181,000          25m 00s      5m 30s
  283,500                       1h 00m
  321,800                       1h 40m
  357,000          12h 32m      2h 41m
  386,000          21h 56m      4h 25m
  414,200       1d 12h 29m      6h 30m
  447,168       2d 13h 20m      9h 47m

*Machine A*: a low-spec 2011 1.6GHz AMD E-350 dual-core fanless CPU,
8GB RAM and a DragonFlyBSD UFS filesystem on an SSD.  It requests
blocks over the LAN from a bitcoind on machine B.  :envvar:`DB_CACHE`
the default of 1,200.  LevelDB.

*Machine B*: a late 2012 iMac running Sierra 10.12.2, 2.9GHz quad-core
Intel i5 CPU with an HDD and 24GB RAM.  Running bitcoind on the same
machine.  :envvar:`DB_CACHE` set to 1,800.  LevelDB.

For chains other than bitcoin-mainnet synchronization should be much
faster.

.. note:: ElectrumXLTFN will not serve normal client connections until it
          has fully synchronized and caught up with your daemon.
          However LocalRPC connections are served at all times.


Terminating ElectrumXLTFN
=====================

The preferred way to terminate the server process is to send it the
``stop`` RPC command::

  electrumxltfn_rpc stop

or alternatively on Unix the ``INT`` or ``TERM`` signals.  For a
daemontools supervised process this can be done by bringing it down
like so::

    svc -d ~/service/electrumxltfn

ElectrumXLTFN will note receipt of the signals in the logs, and ensure the
block chain index is flushed to disk before terminating.  You should
be patient as flushing data to disk can take many minutes.

ElectrumXLTFN uses the transaction functionality, with fsync enabled, of
the databases.  I have written it with the intent that, to the extent
the atomicity guarantees are upheld by the DB software, the operating
system, and the hardware, the database should not get corrupted even
if the ElectrumXLTFN process if forcibly killed or there is loss of power.
The worst case should be having to restart indexing from the most
recent UTXO flush.

Once the process has terminated, you can start it up again with::

    svc -u ~/service/electrumxltfn

You can see the status of a running service with::

    svstat ~/service/electrumxltfn

:command:`svscan` can of course handle multiple services
simultaneously from the same service directory, such as a testnet or
altcoin server.  See the man pages of these various commands for more
information.


Understanding the Logs
======================

You can see the logs usefully like so::

    tail -F /path/to/log/dir/current | tai64nlocal

Here is typical log output on startup::

  INFO:BlockProcessor:switching current directory to /crucial/server-good
  INFO:BlockProcessor:using leveldb for DB backend
  INFO:BlockProcessor:created new database
  INFO:BlockProcessor:creating metadata diretcory
  INFO:BlockProcessor:software version: ElectrumXLTFN 0.10.2
  INFO:BlockProcessor:DB version: 5
  INFO:BlockProcessor:coin: Bitcoin
  INFO:BlockProcessor:network: mainnet
  INFO:BlockProcessor:height: -1
  INFO:BlockProcessor:tip: 0000000000000000000000000000000000000000000000000000000000000000
  INFO:BlockProcessor:tx count: 0
  INFO:BlockProcessor:sync time so far: 0d 00h 00m 00s
  INFO:BlockProcessor:reorg limit is 200 blocks
  INFO:Daemon:daemon at 192.168.0.2:8332/
  INFO:BlockProcessor:flushing DB cache at 1,200 MB
  INFO:Controller:RPC server listening on localhost:8000
  INFO:Prefetcher:catching up to daemon height 447,187...
  INFO:Prefetcher:verified genesis block with hash 000000000019d6689c085ae165831e934ff763ae46a2a6c172b3f1b60a8ce26f
  INFO:BlockProcessor:our height: 9 daemon: 447,187 UTXOs 0MB hist 0MB
  INFO:BlockProcessor:our height: 52,509 daemon: 447,187 UTXOs 9MB hist 14MB
  INFO:BlockProcessor:our height: 85,009 daemon: 447,187 UTXOs 12MB hist 31MB
  INFO:BlockProcessor:our height: 102,384 daemon: 447,187 UTXOs 15MB hist 47MB
  [...]
  INFO:BlockProcessor:our height: 133,375 daemon: 447,187 UTXOs 80MB hist 222MB
  INFO:BlockProcessor:our height: 134,692 daemon: 447,187 UTXOs 96MB hist 250MB
  INFO:BlockProcessor:flushed to FS in 0.7s
  INFO:BlockProcessor:flushed history in 16.3s for 1,124,512 addrs
  INFO:BlockProcessor:flush #1 took 18.7s.  Height 134,692 txs: 941,963
  INFO:BlockProcessor:tx/sec since genesis: 2,399, since last flush: 2,400
  INFO:BlockProcessor:sync time: 0d 00h 06m 32s  ETA: 1d 13h 03m 42s

Under normal operation these cache stats repeat once or twice a
minute.  UTXO flushes can take several minutes and look like this::

  INFO:BlockProcessor:our height: 378,745 daemon: 447,332 UTXOs 1,013MB hist 184MB
  INFO:BlockProcessor:our height: 378,787 daemon: 447,332 UTXOs 1,014MB hist 194MB
  INFO:BlockProcessor:flushed to FS in 0.3s
  INFO:BlockProcessor:flushed history in 13.4s for 934,933 addrs
  INFO:BlockProcessor:flushed 6,403 blocks with 5,879,440 txs, 2,920,524 UTXO adds, 3,646,572 spends in 93.1s, committing...
  INFO:BlockProcessor:flush #120 took 226.4s.  Height 378,787 txs: 87,695,588
  INFO:BlockProcessor:tx/sec since genesis: 1,280, since last flush: 359
  INFO:BlockProcessor:sync t ime: 0d 19h 01m 06s  ETA: 3d 21h 17m 52s
  INFO:BlockProcessor:our height: 378,812 daemon: 447,334 UTXOs 10MB hist 10MB

The ETA shown is just a rough guide and in the short term can be quite
volatile.  It tends to be a little optimistic at first; once you get
to height 280,000 is should be fairly accurate.

.. _SSL certificates:

Creating a self-signed SSL certificate
======================================

These instructions are based on those of the ``electrum-server``
documentation.

To run an SSL server you need to generate a self-signed certificate
using openssl.  Alternatively you could not set :envvar:`SSL_PORT` in
the environment and not serve over SSL, but this is not recommended.

Use the sample code below to create a self-signed cert with a
recommended validity of 5 years. You may supply any information for
your sign request to identify your server.  They are not currently
checked by the client except for the validity date.  When asked for a
challenge password just leave it empty and press enter::

    $ openssl genrsa -out server.key 2048
    $ openssl req -new -key server.key -out server.csr
    ...
    Country Name (2 letter code) [AU]:US
    State or Province Name (full name) [Some-State]:California
    Common Name (eg, YOUR name) []: electrum-server.tld
    ...
    A challenge password []:
    ...
    $ openssl x509 -req -days 1825 -in server.csr -signkey server.key -out server.crt

The :file:`server.crt` file goes in :envvar:`SSL_CERTFILE` and
:file:`server.key` in :envvar:`SSL_KEYFILE` in the server process's
environment.

Starting with Electrum 1.9, the client will learn and locally cache
the SSL certificate for your server upon the first request to prevent
man-in-the middle attacks for all further connections.

If your certificate is lost or expires on the server side, you will
need to run your server with a different server name and a new
certificate.  Therefore it's a good idea to make an offline backup
copy of your certificate and key in case you need to restore them.

Running on a privileged port
============================

You may choose to run electrumxltfn on a different port than 50001
/ 50002.  If you choose a privileged port ( < 1024 ) it makes sense to
make use of a iptables NAT rule.

An example, which will forward Port 110 to the internal port 50002 follows::

    iptables -t nat -A PREROUTING -p tcp --dport 110 -j DNAT --to-destination 127.0.0.1:50002

You can then set the port as follows and advertise the service externally on the privileged port::

    REPORT_SSL_PORT=110


.. _`contrib/systemd/electrumxltfn.service`: https://github.com/spesmilo/electrumxltfn/blob/master/contrib/systemd/electrumxltfn.service
.. _`daemontools`: http://cr.yp.to/daemontools.html
.. _`runit`: http://smarden.org/runit/index.html
.. _`aiohttp`: https://pypi.python.org/pypi/aiohttp
.. _`pylru`: https://pypi.python.org/pypi/pylru
.. _`x11_hash`: https://pypi.python.org/pypi/x11_hash
.. _`contrib/raspberrypi3/install_electrumxltfn.sh`: https://github.com/spesmilo/electrumxltfn/blob/master/contrib/raspberrypi3/install_electrumxltfn.sh
.. _`contrib/raspberrypi3/run_electrumxltfn.sh`: https://github.com/spesmilo/electrumxltfn/blob/master/contrib/raspberrypi3/run_electrumxltfn.sh
