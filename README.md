# Understanding High Availability Mechanisms with Keepalived

This repo is highly inspired on the following article: [Meet keepalived - High Availability and Load Balancing in One](https://technotim.live/posts/keepalived-ha-loadbalancer/#installation).

## Pre-requisites

* Two nodes with linux (ubuntu in this case) and with static IP addresses.

* Install `keepalived` in both nodes:

    ```bash
    sudo apt update
    sudo apt install keepalived
    ```

## Setup

Add the following `keepalived.conf` file in the first node in `/etc/keepalived/keepalived.conf`. Files are located in the `keepalived` folder of this repository. Make sure they are renamed properly.

Node 1:

```conf
vrrp_instance VI_1 { # Instance name of keepalived 
  state MASTER # Default state when this instance come up (the other option is BACKUP)
  interface eth0 # Interface that keepalived is listening at
  virtual_router_id 55 # Can be whatever. Must mach across instances
  priority 150 # Determines who is the master. The BACKUP should have lower priority
  advert_int 1 # Advertisement interval
  unicast_src_ip 192.168.200.20 # This machine itself 
  unicast_peer {
    192.168.200.52 # The other node 
  }

  authentication { # Authentication between peers. Password must be shared
    auth_type PASS
    auth_pass e^Ho6HWa
  }

  virtual_ipaddress {
    192.168.200.130/24 # Pool of available adresses
  }
}
```

Node 2:

```conf
vrrp_instance VI_1 { # We want to keep the name of the instance 
  state BACKUP # Change to BACKUP
  interface eth0 # Interface that keepalived is listening at
  virtual_router_id 55 # Can be whatever. Must mach across instances
  priority 100 # Lower than the MASTER
  advert_int 1 # Advertisement interval
  unicast_src_ip 192.168.200.52 # This machine itself 
  unicast_peer {
    192.168.200.20 # The other node 
  }

  authentication { # Authentication between peers. Password must be shared
    auth_type PASS
    auth_pass e^Ho6HWa
  }

  virtual_ipaddress {
    192.168.200.130/24 # Pool of available adresses
  }
}
```

Now run in both servers the following command in order to enable HA in both servers.

```bash
sudo systemctl enable --now keepalived.service
```

From another machine, check that you can ping the virtual IP address (`192.168.200.130` in this case).

Now if you stop one server with the following command, the other one will take the virtual IP address.

```bash
sudo systemctl stop keepalived.service
```

Also, check the logs and will see how the other server takes the virtual IP address.

```bash
...
Jul 31 13:45:49 sergio05 Keepalived[25872]: Startup complete
Jul 31 13:45:49 sergio05 Keepalived_vrrp[25873]: (VI_1) Entering BACKUP STATE (init)
Jul 31 13:45:49 sergio05 systemd[1]: Started Keepalive Daemon (LVS and VRRP).
Jul 31 13:45:53 sergio05 Keepalived_vrrp[25873]: (VI_1) Entering MASTER STATE
Jul 31 13:45:58 sergio05 Keepalived_vrrp[25873]: (VI_1) Master received advert from 192.168.200.20 with higher priority 150, ours 100
Jul 31 13:45:58 sergio05 Keepalived_vrrp[25873]: (VI_1) Entering BACKUP STATE
```

## Healthcheck Setup 

Install nginx in both nodes (simply, using docker). Make sure you have [docker](https://docs.docker.com/engine/install/ubuntu/) and [docker-compose](https://gist.github.com/sergio-gimenez/c5910d112e677d81c8107344b560b73b) installed.

```bash
cd nginx
docker-compose up -d
```

Make sure to change the html content in order to know if you are using the nginx in node 1 or node 2.

Make sure you add the `keepalived_script` user in all nodes because by default, `keepalived` tries to run the healthcheck script as `keepalived` user, otherwise falls to `root` user (which btw is not recommended by them in their [official docs](https://manpages.debian.org/unstable/keepalived/keepalived.conf.5.en.html#SCRIPTS))

```bash
sudo adduser --system keepalived_script
```

If want to test healthcheck, go to the `/conf/2-node-setup` directory of this project and copy the `keepalived.conf.master.hc` and `keepalived.conf.backup.hc` into the `/etc/keepalived/keepalived.conf` file in node 1 and node 2 respectively. Make sure to rename them properly. Also, copy the healthcheck script into `/us/local/bin/healthcheck.sh` in both nodes. If you want to test it with three nodes, then just copy the three conf files in every node.

Log output should be something like that:

```bash
...
Aug 03 09:50:04 sergio01 Keepalived[280492]: NOTICE: setting config option max_auto_priority should result in better
keepalived performance
Aug 03 09:50:04 sergio01 Keepalived[280492]: Starting VRRP child process, pid=280493
Aug 03 09:50:04 sergio01 Keepalived[280492]: Startup complete
Aug 03 09:50:04 sergio01 Keepalived_vrrp[280493]: SECURITY VIOLATION - scripts are being executed but script_security
 not enabled.
Aug 03 09:50:04 sergio01 Keepalived_vrrp[280493]: (VI_1) Entering BACKUP STATE (init)
Aug 03 09:50:04 sergio01 systemd[1]: keepalived.service: Got notification message from PID 280493, but reception only
 permitted for main PID 280492
Aug 03 09:50:04 sergio01 systemd[1]: Started Keepalive Daemon (LVS and VRRP).
Aug 03 09:50:04 sergio01 Keepalived_vrrp[280493]: VRRP_Script(check_nginx) succeeded
Aug 03 09:50:04 sergio01 Keepalived_vrrp[280493]: (VI_1) Changing effective priority from 150 to 152
Aug 03 09:50:07 sergio01 Keepalived_vrrp[280493]: (VI_1) Entering MASTER STATE
```

## Priority Mechanics

### Two Node Set Up

Priority is essential to understand how `keepalived` works. Let's describe in a detailed way the workflow of this setup.

1. Initially, `p_n1 = 50` and `p_n2 = 1`. Node 1 is the master.
2. Nginx up in both nodes. Healtheck successful in both nodes. `p_n1 = 150` and `p_n2 = 100`. Node 1 is the master.
3. Let's say Node 1 (master) has some issues with `nginx` (you can kill container with a `docker-compose down`). Node 1 will stop responding to healthchecks, then will loose 100 points because the healthcheck script failed. Then, `p_n1 = 50` and `p_n2 = 100`. Node 2 is the master.

### Three Node Set Up

1. Initially, `p_n1 = 50`, `p_n2 = 1` and `p_n3 = 2`. Node 1 is the master.
2. Nginx is up in all nodes. Healthcheck successful in all nodes. `p_n1 = 150`, `p_n2 = 101` and `p_n3 = 102`. Node 1 is the master.
3. Let's ssay Node 1 (master) has some issues with `nginx` (you can kill container with a `docker-compose down`). Node 1 will stop responding to healthchecks, then will loose 100 points because the healthcheck script failed. Then, `p_n1 = 50`, `p_n2 = 101` and `p_n3 = 102`. Node 3 is the master.
4. Now, let's say Node 2 (master) has some issues with `nginx`. Node 2 will stop responding to healthchecks, then will loose 100 points. Then, `p_n1 = 50`, `p_n2 = 101` and `p_n3 = 2`. Node 2 is the master.