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

  vrrp_script check_nginx {
    script "./nginx_health_check.sh"  # Replace with the actual path of your script
    interval 10  # Interval in seconds between script execution
    weight 2  # Weight assigned to the script (used in VRRP priority calculation)
  }

}
