# Make sure scripts are defined before the vrrp_instance block, otherwise keepalived was
# complaining about the scripts not being found.
# Note that By default the scripts will be executed by user keepalived_script if that user exists, or if not by root,
# but for each script the user/group under which it is to be executed can be specified.
vrrp_script check_nginx {
  script /usr/local/bin/nginx_healthcheck.sh  # Replace with the actual path of your script
  interval 5 # Interval in seconds between script execution
  weight 100 # Weight assigned to the script. If successfull, the priority will be increased by this value, if not, it will be decreased
}

vrrp_instance VI_1 { # Instance name of keepalived 
  state MASTER # Default state when this instance come up (the other option is BACKUP)
  interface eth0 # Interface that keepalived is listening at
  virtual_router_id 55 # Can be whatever. Must mach across instances
  priority 50 # Determines who is the master. The BACKUP should have lower priority
  advert_int 1 # Advertisement interval
  unicast_src_ip 192.168.200.20 # This machine itself 
  unicast_peer {
    192.168.200.52 # The other node 
  }

  authentication { # Authentication between peers. Password must be shared
    auth_type PASS
    auth_pass e^Ho6HWa # Maximum 8 characters
  }

  virtual_ipaddress {
    192.168.200.130/24
  }

  track_script { # 0 Means successfull, 1 means failure
    check_nginx 
  }
}