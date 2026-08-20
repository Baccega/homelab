/interface bridge
add name=bridge1
/interface vlan
add interface=bridge1 name=mgmt-vlan vlan-id=1
/interface ethernet switch
set drop-if-invalid-or-src-port-not-member-of-vlan-on-ports=\
    ether1,ether2,ether3,ether4,ether5,ether6,ether7,ether8,sfp9,sfp10,sfp11,sfp12
/interface list
add name=WAN
add name=LAN
/port
set 0 name=serial0
/interface bridge port
add bridge=bridge1 interface=ether1
add bridge=bridge1 interface=ether2
add bridge=bridge1 interface=ether3 pvid=40
add bridge=bridge1 interface=ether4 pvid=20
add bridge=bridge1 interface=ether5 pvid=40
add bridge=bridge1 interface=ether6 pvid=40
add bridge=bridge1 interface=ether7 pvid=20
add bridge=bridge1 interface=ether8 pvid=40
add bridge=bridge1 interface=sfp9 pvid=40
add bridge=bridge1 interface=sfp10 pvid=40
add bridge=bridge1 interface=sfp11 pvid=40
add bridge=bridge1 interface=sfp12 pvid=40
/interface bridge vlan
add bridge=bridge1 tagged=ether1 untagged=ether7,ether4 vlan-ids=20
add bridge=bridge1 tagged=ether1,ether2 vlan-ids=30
add bridge=bridge1 tagged=bridge1 untagged=ether1,ether2 vlan-ids=1
add bridge=bridge1 tagged=ether1,ether2 untagged=ether3,ether5,ether6,ether8,sfp9,sfp10,sfp11,sfp12 vlan-ids=40
/interface ethernet switch egress-vlan-tag
add tagged-ports=switch1-cpu vlan-id=1
add tagged-ports=ether1 vlan-id=20
add tagged-ports=ether1,ether2 vlan-id=30
add tagged-ports=ether1,ether2 vlan-id=40
/interface ethernet switch ingress-vlan-translation
add customer-vid=0 new-customer-vid=20 ports=ether4
add customer-vid=0 new-customer-vid=20 ports=ether7
add customer-vid=0 new-customer-vid=40 ports=ether3
add customer-vid=0 new-customer-vid=40 ports=ether5
add customer-vid=0 new-customer-vid=40 ports=ether6
add customer-vid=0 new-customer-vid=40 ports=ether8
add customer-vid=0 new-customer-vid=40 ports=sfp9
add customer-vid=0 new-customer-vid=40 ports=sfp10
add customer-vid=0 new-customer-vid=40 ports=sfp11
add customer-vid=0 new-customer-vid=40 ports=sfp12
add customer-vid=0 new-customer-vid=1 ports=ether1
add customer-vid=0 new-customer-vid=1 ports=ether2
/interface ethernet switch vlan
add ports=switch1-cpu,ether1,ether2 vlan-id=1
add ports=ether1,ether4,ether7 vlan-id=20
add ports=ether1,ether2 vlan-id=30
add ports=ether1,ether2,ether3,ether5,ether6,ether8,sfp10,sfp9,sfp12,sfp11 vlan-id=40
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
