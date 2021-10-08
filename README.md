# pkg-server

[![Release](https://github.com/mutablelogic/pkg-server/actions/workflows/release-arm.yaml/badge.svg)](https://github.com/mutablelogic/pkg-server/actions/workflows/release-arm.yaml)

This repository is used to package plugins for [go-server](https://github.com/mutablelogic/go-server/).
You can download the latest packages in the [releases](https://github.com/mutablelogic/pkg-server/releases)
section.

Presently packaging is performed for `armhf` (32-bit) and `arm64` on Linux in `.deb` (Debian and Ubuntu) 
format. Other packaging formats and architectures are possible.

The packages are currently:

  * `go-server-httpserver` - the server and plugins for HTTP serving;
  * `go-server-template` - dynamic file serving through templates;
  * `go-server-ldapauth` - authentication with LDAP;
  * `go-server-sqlite3` - sqlite3 database & file indexer plugins;
  * `go-server-mqtt` - mqtt client plugin;
  * `go-server-mdns` - mDNS (multicast DNS) client and server plugin;
  * `go-server-ddregister` - Dynamic DNS registration plugin.

## Installation location

The installation is located in `/opt/go-server`. The folders are:

  * `/opt/go-server/bin` The server binary;
  * `/opt/go-server/plugin` The plugins;
  * `/opt/go-server/etc` Configuration files, including `go-server.service` which is the systemctl file and
    `go-server.env` which can store environment variables for startup including any secrets. Edit the `.yaml`
    files (or remove them) to change the configuration;
  * `/opt/go-server/var` Contains ephermeral data;
  * `/opt/go-server/docs` Contains static files for file serving;
  * `/opt/go-server/templates` Contains template files for template rendering.

## Debian and Ubuntu installation

In order to download the packages for a release, you can use the [gh](https://github.com/cli/cli) command.
To list all the releases:

```bash
bash# gh release list --repo github.com/mutablelogic/pkg-server
```

Then you can install the packages in the latest release using 
the [dpkg](https://manpages.debian.org/dpkg) command:

```bash
bash# gh release download --repo github.com/mutablelogic/pkg-server --pattern '*.deb'
bash# sudo dpkg -i *.deb
```

You can remove packages and optionally purge configuration using (for example):

```bash
bash# sudo apt remove go-server-httpserver
bash# sudo apt purge go-server-httpserver
```

## Community & License

  * [File an issue or question](http://github.com/mutablelogic/pkg-server/issues) on github.
  * Licensed under Apache 2.0, please read that license about using and forking. The main conditions require preservation of copyright and license notices. Contributors provide an express grant of patent rights. Licensed works, modifications, and larger works may be distributed under different terms and without source code.
