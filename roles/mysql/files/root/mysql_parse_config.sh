#!/bin/bash
#set -x
custom_cfg=$1
master_cfg=/etc/my.cnf
option_list="/root/mysql_option_list_55.txt"
if [ "$custom_cfg" == "" ]
then
        echo -e "No parameter! \n Usage: $0 custom-config"
        exit 2
fi
if [ ! -f "$custom_cfg" ]
then
        echo "no such file"
        exit 3
fi

function validate_option {
        local option=$1;
        match=$(grep -c "^${option}$" ${option_list} )
        if [ $match != 1 ]
        then
                echo "no such MySQL option \"${remove}\". Abort!"
                exit 2
        fi
}

IFS="
"
add_list=$( grep  -E '^[a-z]' ${custom_cfg} |sed  -e  's/[^a-zA-Z0-9_=\-]//g' )
#remove the option from the existing my.cnf
for add in  $add_list
do
        option=$( echo ${add}|cut -d "=" -f 1| sed 's/\-/_/g')
        value=$( echo ${add}|cut -d "=" -f 2)
        validate_option ${option}
        echo "add/replace  \"${option}\" with value $value"
        sed  -i "/^${option}[^a-z_\-]/d" ${master_cfg}

done
#add the extra options
for add in  $add_list
do
        option=$( echo ${add}|cut -d "=" -f 1| sed 's/\-/_/g')
        value=$( echo ${add}|cut -d "=" -f 2)
        sed -i "s/^#custom: extra options/&\n${option}=\t${value}/" ${master_cfg}

done

for remove in $( grep  -E '^-' ${custom_cfg} |sed -e 's/^-//g' -e  's/-/\_/g' -e 's/[^a-z_]//g' )
do
        validate_option ${remove}
        echo "removing \"${remove}\" from the master config[${master_cfg}] if exists"
#we don't want to remove slow_query_log_file when removing  slow_query_log
        sed  -i "/^${remove}[^a-z_\-]/d" ${master_cfg}
        sed -i "s/^#custom: removed options/&\n#${remove}/" ${master_cfg}
done
exit 0
