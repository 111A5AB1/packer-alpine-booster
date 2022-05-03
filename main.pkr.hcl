
locals {
  alpine_extended = "https://dl-cdn.alpinelinux.org/alpine/v3.15/releases/x86_64/alpine-extended-3.15.4-x86_64.iso"
  alpine_virt     = "https://dl-cdn.alpinelinux.org/alpine/v3.15/releases/x86_64/alpine-virt-3.15.4-x86_64.iso"
  firmware        = "/usr/share/ovmf/OVMF.fd"

  floppy_files = [
    "floppy/answers",
    "floppy/grub_40",
    "floppy/install"
  ]
  boot_wait         = "1s"
  boot_key_interval = "20ms"
  boot_command = [
    "<enter><wait6s>",

    # Login as root...
    "root<enter><wait0.5s>",

    # Mount floppy and run our setup script...
    "mount -t vfat -o shortname=lower /dev/fd0 /media/floppy<enter><wait0.5s>",
    "sh /media/floppy/install<enter><wait15s>",

    # Re-mount root partition and efi
    "mount /dev/vda2 /mnt<enter><wait0.2s>",
    "mount /dev/vda1 /mnt/boot/efi<enter><wait0.2s>",

    # "Patch" Grub to add menu entries
    "sh /media/floppy/grub_40<enter><wait0.2s>",

    # Setup chroot environment
    "mount -t proc none /mnt/proc<enter><wait0.2s>",
    "mount -o bind /dev /mnt/dev<enter><wait0.2s>",
    "mount -o bind /sys /mnt/sys<enter><wait0.2s>",

    # Chroot into install
    "chroot /mnt<enter><wait0.2s>",

    # Add boost + "edge" kernel from Alpine packages
    "apk add booster linux-edge<enter><wait2s>",

    # Finished with build...
    "exit<enter><wait0.2s>",
    "umount /mnt/boot/efi<enter><wait0.2s>",
    "umount /mnt<enter><wait0.2s>",
    "poweroff<enter>"
  ]

  communicator = "none"
}

build {
  sources = [
    "source.qemu.alpine_extended",
    "source.qemu.alpine_virt"
  ]
}

source "qemu" "alpine_extended" {
  iso_url      = local.alpine_extended
  iso_checksum = "file:${local.alpine_extended}.sha256"
  firmware     = local.firmware

  floppy_files      = local.floppy_files
  boot_wait         = local.boot_wait
  boot_key_interval = local.boot_key_interval
  boot_command      = local.boot_command

  communicator = local.communicator

  shutdown_command = "echo 'packer' | sudo -S shutdown -P now"

  vm_name = "ext"
  output_directory           = "out-ext"
}

source "qemu" "alpine_virt" {
  iso_url      = local.alpine_virt
  iso_checksum = "file:${local.alpine_virt}.sha256"
  firmware     = local.firmware

  floppy_files      = local.floppy_files
  boot_wait         = local.boot_wait
  boot_key_interval = local.boot_key_interval
  boot_command      = local.boot_command

  communicator = local.communicator

  shutdown_command = "echo 'packer' | sudo -S shutdown -P now"

  vm_name = "virt"
  output_directory           = "out-virt"
}