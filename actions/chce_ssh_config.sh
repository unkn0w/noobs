#!/bin/bash
# Create ssh config for easy connection with mikr.us
# Autor: Radoslaw Karasinski, Artur 'stefopl' Stefanski
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

declare -A hosts=(
  ["e"]="srv07"
  ["f"]="srv08"
  ["g"]="srv09"
  ["h"]="srv10"
  ["i"]="srv11"
  ["j"]="srv12"
  ["k"]="srv14"
  ["l"]="srv15"
  ["m"]="srv16"
  ["n"]="srv17"
  ["o"]="srv18"
  ["p"]="srv19"
  ["r"]="srv20"
  ["s"]="srv21"
  ["t"]="srv22"
  ["u"]="srv23"
  ["w"]="srv24"
  ["z"]="srv25"
  ["x"]="maluch"
  ["y"]="maluch2"
  ["v"]="maluch3"
  ["a"]="srv26"
  ["b"]="srv27"
  ["c"]="srv29"
  ["d"]="srv28"
)

if [ -n "$mikrus" ]; then
    if ! [[ "$mikrus" =~ [a-z][0-9]{3}$ ]]; then
        echo "ERROR: --mikrus parameter is not valid!"
        exit 3
    fi

    port="$(( 10000 + $(echo $mikrus | grep -o '[0-9]\+') ))"

    key="$(echo $mikrus | grep -o '[^0-9]\+' )"

    url="https://mikr.us/serwery.txt"

    servers=""

    if command -v curl &> /dev/null; then
            http_code=$(curl -s -o /dev/null -w "%{http_code}" "$url")
            content_type=$(curl -sI "$url" | grep -i "Content-Type" | cut -d ' ' -f2)

            if [ "$http_code" == "200" ] && [[ "$content_type" == "text/"* ]]; then
                servers=$(curl -s "$url")
            fi
        elif command -v wget &> /dev/null; then
            http_code=$(wget --spider --server-response "$url" 2>&1 | grep "HTTP/" | awk '{print $2}')
            content_type=$(wget --spider --server-response "$url" 2>&1 | grep -i "Content-Type" | awk '{print $2}')

            if [ "$http_code" == "200" ] && [[ "$content_type" == "text/"* ]]; then
                servers=$(wget -q -O - "$url")
            fi
        else
            echo "ERROR: Neither 'curl' nor 'wget' were found."
            exit 1
        fi

    if [ -n "$servers" ]; then
        unset hosts
        declare -A hosts
        while IFS='=' read -r server value; do
            hosts["$server"]="$value"
        done <<< "$servers"
    else
      echo "Failed to download server list. Using hardcoded list."
    fi

    echo $hosts

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
    echo "ERROR: '$header' already defined in ~/.ssh/config!"
    exit 6
fi

ssh-copy-id -i "$ssh_key_file" $header

echo ""
echo "ssh was properly configured!"
echo "Remember, that you can use tab to use autofill to type connection string faster - type few first chars of Host (i.e. 'ssh ${header:0:8}', or even less), then press tab."