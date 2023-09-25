#!/bin/bash
# Create ssh config for easy connection with mikr.us
# Autor: Radoslaw Karasinski, Artur 'stefopl' Stefanski
# Usage: you can pass following arguments:
#   --mikrus MIKRUS_NAME (i.e. 'X123')
#   --user USERNAME (i.e. 'root')
#   --port PORT_NUMBER (to configure connection for non mikr.us host)
#   --host HOSTNAME (to configure connection for non mikr.us host)
#   username@test.com (without param in front)

# Read hosts from serwery.txt
declare -A hosts
while IFS='=' read -r key value; do
  hosts["$key"]="$value"
done < "../serwery.txt"

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
        exit 3
    fi

    port="$(( 10000 + $(echo $mikrus | grep -o '[0-9]\+') ))"

    key="$(echo $mikrus | grep -o '[^0-9]\+' )"
    host="${hosts[$key]}"
    if [ -z "$host" ]; then
        echo "ERROR: Server hostname not known for key '$key'."
        exit 4
    fi
    host="$host.mikr.us"
fi

if [ -n "$possible_ssh_param" ]; then
    user="${possible_ssh_param%%@*}"
    host="${possible_ssh_param#*@}"
fi

if [ -z "$host" ]; then
    echo "ERROR: Host was not recognized by any known method (--mikrus or --host or by specifying user@host.com)."
    echo ""
    echo "Usage: you can pass following arguments:"
    echo "  --mikrus MIKRUS_NAME (i.e. 'X123')"
    echo "  --user USERNAME (i.e. 'root')"
    echo "  --port PORT_NUMBER (to configure connection for non mikr.us host)"
    echo "  --host HOSTNAME (to configure connection for non mikr.us host)"
    echo "  username@test.com (without param in front)"
    exit 5
fi

echo "Following params will be used to generate ssh config: user:'$user', host:'$host', port:'$port'"
read -n 1 -s  -p "Press enter (or space) to continue or any other key to cancel." decision
echo ""
if [ -n "$decision" ]; then
    echo "No further changes."
    exit 0
fi

if [ -n "$mikrus" ]; then
    ssh_key_file="$HOME/.ssh/mikrus-$mikrus-$user-$host-port-$port-rsa"
    header="mikrus-$mikrus-$user-$host-$port"
else
    ssh_key_file="$HOME/.ssh/$user-$host-port-$port-rsa"
    header="$user-$host"
fi

ssh-keygen -t rsa -b 4096 -f "$ssh_key_file" -C "$USER@$HOSTNAME"

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
    exit 6
fi

ssh-copy-id -i $ssh_key_file $header

echo ""
echo "ssh was properly configured!"
echo "Remember, that you can use tab to use autofill to type connection string faster - type few first chars of Host (i.e. 'ssh ${header:0:8}', or even less), then press tab."