# Requirements

## Debian 10
tbd

## Fedora
tbd

# Build

```
./build.sh
```

This will create a rootfs folder with all needed files

# Execute

sysrepod, sysrepod-plugin and netopeer2-server has to be executed with prvileges rights.

```
source env.sh
netopeer2-server
```

You can execute each daemon in a seperate window/terminal and see the log/debug information:


Terminal 2 as root
```
source env.sh
netopeer2-server -d -v 2
```

Terminal 3 as user
```
source env.sh
netopeer2-cli
```
