#!/usr/bin/env bash

###### Setup iscsi (rhel8)

##################
# Create udev rules 
# from example at support.purestorage.com
# OVERWRITES THE FILE
##################

cat << EOF > /etc/udev/rules.d/99-pure-storage.rules
# Recommended settings for Pure Storage FlashArray.
# Use none scheduler for high-performance solid-state storage for SCSI devices
ACTION=="add|change", KERNEL=="sd*[!0-9]", SUBSYSTEM=="block", ENV{ID_VENDOR}=="PURE", OPTIONS="nowatch", ATTR{queue/scheduler}="none"
ACTION=="add|change", KERNEL=="dm-[0-9]*", SUBSYSTEM=="block", ENV{DM_NAME}=="3624a937*", OPTIONS="nowatch", ATTR{queue/scheduler}="none"

# Reduce CPU overhead due to entropy collection
ACTION=="add|change", KERNEL=="sd*[!0-9]", SUBSYSTEM=="block", ENV{ID_VENDOR}=="PURE", OPTIONS="nowatch", ATTR{queue/add_random}="0"
ACTION=="add|change", KERNEL=="dm-[0-9]*", SUBSYSTEM=="block", ENV{DM_NAME}=="3624a937*", OPTIONS="nowatch", ATTR{queue/add_random}="0"

# Spread CPU load by redirecting completions to originating CPU
ACTION=="add|change", KERNEL=="sd*[!0-9]", SUBSYSTEM=="block", ENV{ID_VENDOR}=="PURE", OPTIONS="nowatch", ATTR{queue/rq_affinity}="2"
ACTION=="add|change", KERNEL=="dm-[0-9]*", SUBSYSTEM=="block", ENV{DM_NAME}=="3624a937*", OPTIONS="nowatch", ATTR{queue/rq_affinity}="2"

# Set the HBA timeout to 60 seconds
ACTION=="add|change", KERNEL=="sd*[!0-9]", SUBSYSTEM=="block", ENV{ID_VENDOR}=="PURE", OPTIONS="nowatch", ATTR{device/timeout}="60"
EOF

##################
# install pre-reqs
##################

dnf install iscsi-initiator-utils device-mapper device-mapper-multipath -y


##################
# create multipath.conf
# OVERWRITES THE FILE
##################

cat << EOF > /etc/multipath.conf
defaults {
   user_friendly_names no
   enable_foreign "^$"
   polling_interval    10
}

devices {
   device {
       vendor                      "NVME"
       product                     "Pure Storage FlashArray"
       path_selector               "queue-length 0"
       path_grouping_policy        group_by_prio
       prio                        ana
       failback                    immediate
       fast_io_fail_tmo            10
       user_friendly_names         no
       no_path_retry               0
       features                    0
       dev_loss_tmo                60
   }
   device {
       vendor                   "PURE"
       product                  "FlashArray"
       path_selector            "service-time 0"
       hardware_handler         "1 alua"
       path_grouping_policy     group_by_prio
       prio                     alua
       failback                 immediate
       path_checker             tur
       fast_io_fail_tmo         10
       user_friendly_names      no
       no_path_retry            0
       features                 0
       dev_loss_tmo             600
   }
}

blacklist_exceptions {
       property "(SCSI_IDENT_|ID_WWN)"
}

blacklist {
     devnode "^pxd[0-9]*"
     devnode "^pxd*"
     device {
       vendor "VMware"
       product "Virtual disk"
     }
}
EOF
##################
# load dm-multipath and start multipathd service
modprobe -v dm-multipath
systemctl start multipathd.service
##################
# Apply the rules by reloading the UDEV rules
/sbin/udevadm control –R
##################
# enable and start iscsid service
systemctl enable iscsid
systemctl start iscsid
##################

