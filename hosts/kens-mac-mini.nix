{ lib, host, ... }:

{
  # Mac Mini: server-like behavior - prevent sleep but allow display off
  power.sleep = {
    computer = "never";     # Never sleep (pmset sleep 0)
    display = 15;           # Display off after 15 minutes
    harddisk = "never";     # Keep disks awake (pmset disksleep 0)
  };
}
