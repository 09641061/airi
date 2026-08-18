# Filesystem, Storage, and Networking Layers

## 5. Filesystem and storage layer

Location: `hosts/<host-name>/` for machine facts and
`modules/hosts/<scope>/system/storage/` for reusable policy.

This layer manages storage layout and persistence.

Typical responsibilities:

- filesystems and mount points;
- encrypted devices;
- swap;
- RAID or volume management;
- disk layout policy;
- persistence and impermanence policy;
- storage-related scheduled maintenance.

Host-specific device identifiers belong in the host directory. Reusable mount
or persistence policy belongs in a module.

## 6. Networking layer

Location: `modules/hosts/<scope>/system/networking/`.

The networking layer manages communication and network policy.

Typical responsibilities:

- host names;
- firewall policy;
- DNS;
- NetworkManager or equivalent networking;
- VPNs;
- routing;
- wireless policy;
- Tailscale or similar network integration.

The networking layer may configure connectivity required by a service, but the
service daemon itself belongs in the services layer.
