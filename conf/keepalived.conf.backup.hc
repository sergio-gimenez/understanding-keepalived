vrrp_script check_nginx {
  script /usr/local/bin/nginx_healthcheck.sh  # Replace with the actual path of your script
  interval 10 # Interval in seconds between script execution
  weight 2 # Weight assigned to the script (used in VRRP priority calculation)
}

vrrp_instance VI_1 {
  state BACKUP
  interface eth0
  virtual_router_id 55
  priority 100
  advert_int 1
  unicast_src_ip 192.168.200.52
  unicast_peer {
    192.168.200.20
  }

  authentication {
    auth_type PASS
    auth_pass e^Ho6HWa
  }

  virtual_ipaddress {
    192.168.200.130/24
  }

  track_script {
    check_nginx
  }
}