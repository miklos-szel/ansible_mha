#!/bin/bash
#
#       sets hostname from AWS tags
#       rpizzi@blackbirdit.com
#

source /root/.bashrc_extra
instance_id=$(wget -qO- http://169.254.169.254/latest/meta-data/instance-id)
if [ "$instance_id" = "" ]
then
        echo "error acquiring instance-id"
        exit 1
fi
az=$(wget -qO- http://169.254.169.254/latest/meta-data/placement/availability-zone)
if [ "$az" = "" ]
then
        echo "error acquiring AZ"
        exit 1
fi
# kludge - it appears nodegroups is stripping AZ information from FQDN.
# it should be "west-2b" not "west-2"...
# mimic'ing the broken behaviour...
az=${az%?}
IFS="
"
for row in $(ec2-describe-tags --filter resource-id=$instance_id)
do
        tag=$(echo $row | cut -f 4)
        value=$(echo $row | cut -f 5)
        case "$tag" in
                'Env') env=${value,,};;
                'Name') name=$value;;
        esac
done
if [ "$env" = "" -o "$name" = "" ]
then
        echo "error acquiring tags"
        exit 1
fi
hostname="$name-$instance_id.$az"
sed -e "s/\(\".*\"\)/\"$hostname\"/" -i /etc/sysconfig/network
hostname $hostname
exit 0
