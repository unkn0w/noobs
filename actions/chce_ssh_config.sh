#!/usr/bin/env bash
# Create ssh config for easy connection with mikr.us
# Autor: Radoslaw Karasinski, Artur 'stefopl' Stefanski
# Usage: you can pass following arguments:
#   --mikrus MIKRUS_NAME (i.e. 'name123')
#   --user USERNAME (i.e. 'root')
#   --port PORT_NUMBER (to configure connection for non mikr.us host)
#   --host HOSTNAME (to configure connection for non mikr.us host)
#   username@test.com (without param in front)

# Zaladuj biblioteke noobs
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/noobs_lib.sh" || exit 1

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
    msg_error "--mikrus and ssh-like argument ($possible_ssh_param) were given in the same time!"
    exit 1
fi

if [[ -n "$host" && -n "$possible_ssh_param" ]]; then
    msg_error "--host and ssh-like argument ($possible_ssh_param) were given in the same time!"
    exit 2
fi

port="${port:-22}"
user="${user:-root}"

if [ -n "$mikrus" ]; then
    if ! [[ "$mikrus" =~ ^[a-z]+[0-9]+$ ]]; then
        msg_error "--mikrus parameter is not valid!"
        exit 3
    fi

    number_part=$(echo "$mikrus" | grep -o '[0-9]\+')
    if [ -z "$number_part" ]; then
        msg_error "Could not extract number from mikrus name!"
        exit 4
    fi

    port=$((10000 + number_part))
    host="$mikrus.mikrus.xyz"
fi

if [ -n "$possible_ssh_param" ]; then
    user="${possible_ssh_param%%@*}"
    host="${possible_ssh_param#*@}"
fi

if [ -z "$host" ]; then
    msg_error "Host was not recognized by any known method (--mikrus or --host or by specifying user@host.com)."
    echo ""
    echo "Usage: you can pass following arguments:"
    echo "  --mikrus MIKRUS_NAME (i.e. 'X123')"
    echo "  --user USERNAME (i.e. 'root')"
    echo "  --port PORT_NUMBER (to configure connection for non mikr.us host)"
    echo "  --host HOSTNAME (to configure connection for non mikr.us host)"
    echo "  username@test.com (without param in front)"
    exit 5
fi

msg_info "Following params will be used to generate ssh config: user:'$user', host:'$host', port:'$port'"
read -n 1 -s  -p "Press enter (or space) to continue or any other key to cancel." decision
echo ""
if [ -n "$decision" ]; then
    msg_info "No further changes."
    exit 0
fi

if [ -n "$mikrus" ]; then
    ssh_key_file="$HOME/.ssh/mikrus-$mikrus-$user-$host-port-$port-rsa"
    header="mikrus-$mikrus-$user-$host-$port"
else
    ssh_key_file="$HOME/.ssh/$user-$host-port-$port-rsa"
    header="$user-$host-$port"
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
    msg_error "'$header' already defined in ~/.ssh/config!"
    exit 6
fi

ssh-copy-id -i "$ssh_key_file" $header

echo ""
msg_ok "ssh was properly configured!"
msg_info "Remember, that you can use tab to use autofill to type connection string faster - type few first chars of Host (i.e. 'ssh ${header:0:8}', or even less), then press tab."
