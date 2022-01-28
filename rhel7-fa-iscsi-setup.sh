#!/usr/bin/env bash

###### Setup iscsi (rhel7)

##################
# Create udev rules 
# from example at support.purestorage.com
# OVERWRITES THE FILE
##################

cat << EOF > /etc/udev/rules.d/99-pure-storage.rules
# Recommended settings for Pure Storage FlashArray.

# Use none scheduler for high-performance solid-state storage
ACTION=="add|change", KERNEL=="sd*[!0-9]", SUBSYSTEM=="block", ENV{ID_VENDOR}=="PURE", ATTR{queue/scheduler}="noop"

# Reduce CPU overhead due to entropy collection
ACTION=="add|change", KERNEL=="sd*[!0-9]", SUBSYSTEM=="block", ENV{ID_VENDOR}=="PURE", ATTR{queue/add_random}="0"

# Spread CPU load by redirecting completions to originating CPU
ACTION=="add|change", KERNEL=="sd*[!0-9]", SUBSYSTEM=="block", ENV{ID_VENDOR}=="PURE", ATTR{queue/rq_affinity}="2"

# Set the HBA timeout to 60 seconds
ACTION=="add", SUBSYSTEMS=="scsi", ATTRS{model}=="FlashArray      ", RUN+="/bin/sh -c 'echo 60 > /sys/$DEVPATH/device/timeout'"
EOF

##################
# install pre-reqs
##################
yum install iscsi-initiator-utils device-mapper device-mapper-multipath -y

##################
# create multipath.conf
# OVERWRITES THE FILE
##################

cat << EOF > /etc/multipath.conf
 defaults {
         polling_interval       10
}

devices {
        device {
               vendor                   "PURE"
               product                  "FlashArray"
               hardware_handler         "1 alua"
               path_selector            "queue-length 0"
               path_grouping_policy     group_by_prio
               prio                     alua
               path_checker             tur
               fast_io_fail_tmo         10
               failback                 immediate
               no_path_retry            0
               dev_loss_tmo             600
               }
}
EOF
##################
# load dm-multipath and start multipathd service
modprobe -v dm-multipath
systemctl start multipathd.service
##################