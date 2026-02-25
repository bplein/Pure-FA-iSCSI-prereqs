# Pure-FA-iSCSI-prereqs
 Install prerequisites for iSCSI with Pure FlashArray.
 Note: This is to facilitate installation in a clean lab environment.
 The scripts will destroy any exiting configuration files!!!

 `rhel7-fa-iscsi-setup.sh` has been tested in my lab.
 
 `rhel8-fa-iscsi-setup.sh` has NOT YET been tested in my lab.
 
You can run these from the master node in a px-deploy environment with the following script:

```
#!/usr/bin/env bash
for node in $(k get nodes| grep worker | awk '{print$1}')
    do
        ssh $node "echo "Trying ${node}" \
                     && curl -L https://raw.githubusercontent.com/bplein/Pure-FA-iSCSI-prereqs/refs/heads/main/rhel8-fa-iscsi-setup.sh | bash \
                     && echo "Finished ${node}" "
        echo "---"
    done
```
