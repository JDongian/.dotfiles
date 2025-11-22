{ device ? "/dev/nvme0n1", ... }:
{
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        inherit device;
        content = {
          type = "gpt";
          partitions = {
            # EFI Boot Partition
            ESP = {
              priority = 1;
              size = "1G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "defaults" "umask=0077" ];
              };
            };

            # Encrypted Root Partition
            root = {
              size = "100%";
              content = {
                type = "luks";
                name = "cryptroot";
                # Interactive password prompt during install
                settings = {
                  # Enable TRIM for SSD performance
                  allowDiscards = true;
                };
                content = {
                  type = "filesystem";
                  format = "ext4";
                  mountpoint = "/";
                  mountOptions = [ "defaults" "noatime" ];
                };
              };
            };
          };
        };
      };
    };
  };
}
