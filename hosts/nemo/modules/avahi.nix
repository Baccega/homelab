# mDNS reflector so devices on one VLAN can discover services on others
# (e.g. Home Assistant on VLAN 20 discovering Apple TV on VLAN 40)
{
  config,
  lib,
  ...
}:
{
  services.avahi = {
    enable = true;
    reflector = true;
    # Only reflect on internal VLANs (not WAN)
    allowInterfaces = [ "vlan20" "vlan30" "vlan40" ];
  };
}
