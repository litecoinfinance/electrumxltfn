=========
ElectrumXLTFN
=========

.. image:: https://travis-ci.org/spesmilo/electrumxltfn.svg?branch=master
    :target: https://travis-ci.org/spesmilo/electrumxltfn
.. image:: https://coveralls.io/repos/github/spesmilo/electrumxltfn/badge.svg
    :target: https://coveralls.io/github/spesmilo/electrumxltfn

This project is a fork of `kyuupichan/electrumxltfn <https://github.com/kyuupichan/electrumxltfn>`_.
The original author dropped support for Bitcoin, which we intend to keep.

ElectrumXLTFN allows users to run their own ElectrumLtfn server. It connects to your
full node and indexes the blockchain, allowing efficient querying of history of
arbitrary addresses. The server can be exposed publicly, and joined to the public network
of servers via peer discovery. As of May 2020, a significant chunk of the public
ElectrumLtfn server network runs ElectrumXLTFN.

The current version is |release|.

Source Code
===========

The project is hosted on `GitHub
<https://github.com/spesmilo/electrumxltfn/>`_.  and uses `Travis
<https://travis-ci.org/spesmilo/electrumxltfn>`_ for Continuous
Integration.

Please submit an issue on the `bug tracker
<https://github.com/spesmilo/electrumxltfn/issues>`_ if you have found a
bug or have a suggestion to improve the server.

Authors and License
===================

Neil Booth wrote the vast majority of the code; see :ref:`Authors`.
Python version at least 3.7 is required.

The code is released under the `MIT Licence
<https://github.com/spesmilo/electrumxltfn/LICENCE>`_.

Getting Started
===============

See :ref:`HOWTO`.

There is also an `installer`_ available that simplifies the
installation on various Linux-based distributions, and a `Dockerfile`_
available .

.. _installer: https://github.com/bauerj/electrumxltfn-installer
.. _Dockerfile: https://github.com/lukechilds/docker-electrumxltfn

Documentation
=============

.. toctree::

   features
   changelog
   HOWTO
   environment
   protocol
   peer_discovery
   rpc-interface
   architecture
   authors

Indices and tables
==================

* :ref:`genindex`
* :ref:`search`
