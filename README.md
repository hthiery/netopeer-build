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
. ./env.sh
sysrepod
sysrepo-plugind
netopeer2-server
```

You can execute each daemon in a seperate window/terminal and see the log/debug information:

Terminal 1 as root
```
. ./env.sh
sysrepod -d -l 4
```

Terminal 2 as root
```
. ./env.sh
sysrepo-plugind -d -l 4
```

Terminal 3 as root
```
. ./env.sh
netopeer2-server -d -v 2
```

Terminal 4 as user
```
. ./env.sh
netopeer2-cli
```
