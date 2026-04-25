/interface bridge
add name=bridge1 vlan-filtering=yes
/interface vlan
add interface=bridge1 name=mgmt-vlan vlan-id=1
/interface list
add name=WAN
add name=LAN
/port
set 0 name=serial0
/interface bridge port
add bridge=bridge1 interface=ether1
add bridge=bridge1 interface=ether2
add bridge=bridge1 interface=ether3
add bridge=bridge1 interface=ether4 pvid=20
add bridge=bridge1 interface=ether5
add bridge=bridge1 interface=ether6 pvid=40
add bridge=bridge1 interface=ether7 pvid=20
add bridge=bridge1 interface=ether8
add bridge=bridge1 interface=sfp9
add bridge=bridge1 interface=sfp10
add bridge=bridge1 interface=sfp11
add bridge=bridge1 interface=sfp12
/interface bridge vlan
add bridge=bridge1 tagged=ether1 untagged=ether7,ether4 vlan-ids=20
add bridge=bridge1 tagged=ether1,ether2 vlan-ids=30
add bridge=bridge1 tagged=bridge1 untagged=ether1,ether2 vlan-ids=1
add bridge=bridge1 tagged=ether1,ether2 untagged=ether6 vlan-ids=40
/interface list member
add interface=ether1 list=WAN
add interface=ether2 list=LAN
add interface=ether3 list=LAN
add interface=ether4 list=LAN
add interface=ether5 list=LAN
add interface=ether6 list=LAN
add interface=ether7 list=LAN
add interface=ether8 list=LAN
add interface=sfp9 list=LAN
add interface=sfp10 list=LAN
add interface=sfp11 list=LAN
add interface=sfp12 list=LAN
/ip address
add address=192.168.1.2/24 interface=mgmt-vlan network=192.168.1.0
/ip route
add dst-address=0.0.0.0/0 gateway=192.168.1.1
/ip service
set ftp disabled=yes
set telnet disabled=yes
set api disabled=yes
set api-ssl disabled=yes
/system clock
set time-zone-name=Europe/Vienna
/system routerboard settings
set enter-setup-on=delete-key
