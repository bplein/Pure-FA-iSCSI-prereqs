#!/usr/bin/env bash

###### Setup iscsi (rhel7)

##################
# Create udev rules 
# from example at support.purestorage.com
# OVERWRITES THE FILE
##################

cat << EOF > /etc/udev/rules.d/99-pure-storage.rules
# Recommended settings for Pure Storage FlashArray.
# Use none scheduler for high-performance solid-state storage for SCSI devices
ACTION=="add|change", KERNEL=="sd*[!0-9]", SUBSYSTEM=="block", ENV{ID_VENDOR}=="PURE", ATTR{queue/scheduler}="none"
ACTION=="add|change", KERNEL=="dm-[0-9]*", SUBSYSTEM=="block", ENV{DM_NAME}=="3624a937*", ATTR{queue/scheduler}="none"

# Reduce CPU overhead due to entropy collection
ACTION=="add|change", KERNEL=="sd*[!0-9]", SUBSYSTEM=="block", ENV{ID_VENDOR}=="PURE", ATTR{queue/add_random}="0"
ACTION=="add|change", KERNEL=="dm-[0-9]*", SUBSYSTEM=="block", ENV{DM_NAME}=="3624a937*", ATTR{queue/add_random}="0"

# Spread CPU load by redirecting completions to originating CPU
ACTION=="add|change", KERNEL=="sd*[!0-9]", SUBSYSTEM=="block", ENV{ID_VENDOR}=="PURE", ATTR{queue/rq_affinity}="2"
ACTION=="add|change", KERNEL=="dm-[0-9]*", SUBSYSTEM=="block", ENV{DM_NAME}=="3624a937*", ATTR{queue/rq_affinity}="2"

# Set the HBA timeout to 60 seconds
ACTION=="add|change", KERNEL=="sd*[!0-9]", SUBSYSTEM=="block", ENV{ID_VENDOR}=="PURE", ATTR{device/timeout}="60"
EOF

##################
# install pre-reqs
##################
yum --disablerepo=kubernetes install iscsi-initiator-utils device-mapper device-mapper-multipath -y

##################
# create multipath.conf
# OVERWRITES THE FILE
##################

cat << EOF > /etc/multipath.conf
  defaults {
       polling_interval      10
}
devices {
  device {
        vendor "PURE"
        product "FlashArray"
        fast_io_fail_tmo 10
        path_grouping_policy "group_by_prio"
        failback "immediate"
        prio "alua"
        hardware_handler "1 alua"
        max_sectors_kb 4096
    }
}
EOF
##################
# load dm-multipath and start multipathd service
modprobe -v dm-multipath
systemctl start multipathd.service
##################
