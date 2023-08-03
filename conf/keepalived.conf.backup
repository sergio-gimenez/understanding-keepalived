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