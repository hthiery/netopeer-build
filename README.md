# Requirements

## Debian 10/11

apt install cmake libpcre2-dev libssh-dev

## Fedora
tbd

# Build

```
./build.sh
```

This will create a rootfs folder with all needed files

# Execute

Terminal 1 as root

netopeer2-server has to be executed with prvileges rights.
```
source env.sh
netopeer2-server -d -v 2
```

# CLI

Terminal 2 as root
```
source env.sh
netopeer2-cli
```

```
> connect --host localhost --login root
Interactive SSH Authentication
Type your password:
Password:
>
```


# Troubleshooting

When netopeer2-server cannot be started increase the verbose level and set to debug mode:

```
netopeer2-server -d -v 2
```

## fs.protected_regular


```
[ERR]: SR: Failed to open mod shared memory (Permission denied).
[ERR]: SR: Caused by kernel parameter "fs.protected_regular", which must be "0" (currently "2").
[ERR]: NP: Connecting to sysrepo failed (System function call failed).
[ERR]: NP: Server init failed.
[INF]: NP: Server terminated.
```

From Linux kernel version 4.19 on it’s possible to disallow opening FIFOs or
regular files not owned by the user in world writable sticky directories.
This setting would have prevented vulnerabilities found in different user
space programs the last couple of years. This protection is activated
automatically if you use systemd version 241 or higher with Linux 4.19
or higher. If your kernel supports this feature but you are not using
systemd 241, you can activate it yourself by setting the right sysctl settings:

To change this temporarely use:

```
echo 0 > /proc/sys/fs/protected_regular
```
