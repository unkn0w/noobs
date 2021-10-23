#!/bin/bash
# Create ssh config for easy connection with mikr.us
# Autor: Radoslaw Karasinski
# Usage: you can pass following arguments:
#   --mikrus MIKRUS_NAME (i.e. 'X123')
#   --user USERNAME (i.e. 'root')
#   --port PORT_NUMBER (to configure connection for non mikr.us host)
#   --host HOSTNAME (to configure connection for non mikr.us host)
#   username@test.com (without param in front)

# some bash magic: https://brianchildress.co/named-parameters-in-bash/
while [ $# -gt 0 ]; do
    if [[ $1 == *"--"* ]]; then
        param="${1/--/}"
        declare "$param"="$2"
        shift 1
    else
        if [[ $1 == *"@"* ]]; then
          possible_ssh_param=$1
        fi
    fi
  shift
done

if [[ -n "$mikrus" && -n "$possible_ssh_param" ]]; then
    echo "ERROR: --mikrus and ssh-like argument ($possible_ssh_param) were given in the same time!"
    exit 1
fi

if [[ -n "$host" && -n "$possible_ssh_param" ]]; then
    echo "ERROR: --host and ssh-like argument ($possible_ssh_param) were given in the same time!"
    exit 2
fi

port="${port:-22}"
user="${user:-root}"

if [ -n "$mikrus" ]; then
    if ! [[ "$mikrus" =~ [a-q][0-9]{3}$ ]]; then
        echo "ERROR: --mikrus parameter is not valid!"
        exit 1
    fi

    port="$(( 10000 + $(echo $mikrus | grep -o '[0-9]\+') ))"

    key="$(echo $mikrus | grep -o '[^0-9]\+' )"
    declare -A hosts
    hosts["a"]="srv03"
    hosts["b"]="srv04"
    hosts["e"]="srv07"
    hosts["f"]="srv08"
    hosts["g"]="srv09"
    hosts["h"]="srv10"
    hosts["q"]="mini01"
    host="${hosts[$key]}"
    if [ -z "$host" ]; then
        echo "ERROR: Server hostname not known for key $key"
        exit 1
    fi
    host="$host.mikr.us"
fi

if [ -n "$possible_ssh_param" ]; then
    user="${possible_ssh_param%%@*}"
    host="${possible_ssh_param#*@}"
fi



if [ -z "$host" ]; then
    echo "ERROR: Host was not recognized by any known method (--mikrus or --host or by specifying user@host.com"
    exit 2
fi

echo "Following params will be used to generate ssh config: user:'$user', host:'$host', port:'$port'"
read -n 1 -s  -p "Press enter (or space) to continue or any other key to cancel." decision
echo ""
if [ -n "$decision" ]; then
    echo "No further changes"
    exit 0
fi


ssh_key_file="$HOME/.ssh/$user-$host-port-$port-rsa"
ssh-keygen -t rsa -b 4096 -f "$ssh_key_file" -C "$user@$host:$port"

header="$user-$host-$port"
touch ~/.ssh/config # just in case if file was not created in past
if ! grep -q "$header" ~/.ssh/config ; then
    echo "" >> ~/.ssh/config
    echo "Host $header" >> ~/.ssh/config
    echo "  HostName $host" >> ~/.ssh/config
    echo "  User $user" >> ~/.ssh/config
    echo "  Port $port" >> ~/.ssh/config
    echo "  IdentityFile $ssh_key_file" >> ~/.ssh/config
else
    echo "ERROR: '$header' already defined in ~/.ssh/config!"
    exit 3
fi

ssh-copy-id -i $ssh_key_file $header

echo ""
echo "ssh was properly configured!"
echo "Remmber, that you can use tab to use autofill to type connection string faster - type few first chars of Host (i.e. 'ssh ${header:0:8}', or even less) , then press tab."
