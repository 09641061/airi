# Hardware and Boot Layers

## 3. Hardware layer

Location: `modules/hosts/<scope>/hardware/`.

The hardware layer describes physical devices and hardware-dependent behavior.

Typical responsibilities:

- GPU drivers and firmware;
- Bluetooth and wireless devices;
- audio hardware;
- CPU or platform-specific settings;
- power-management behavior;
- device-specific kernel modules;
- hardware-dependent graphical workarounds.

Hardware discovery output should remain separate from hand-written hardware
policy whenever possible.

Do not place general applications, user preferences, or unrelated networking
rules in this layer.

## 4. Boot and kernel layer

Location: `modules/hosts/<scope>/boot/`.

The boot layer controls how the system starts and which kernel behavior it uses.

Typical responsibilities:

- bootloader configuration;
- kernel package selection;
- initrd configuration;
- kernel modules and parameters;
- early-boot networking;
- boot-time security and recovery settings;
- low-level system tuning.

Filesystem declarations belong in the filesystem layer unless they are
unavoidably coupled to initrd or bootloader behavior.
