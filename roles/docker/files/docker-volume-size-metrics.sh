#!/bin/bash -e

while read -r container_id; do
    container=$(docker inspect "$container_id")
    state=$(jq --raw-output .[].State.Status <(echo "$container"))

    if [[ $state = 'running' ]]; then

        name=$(jq --raw-output .[].Name <(echo "$container") | sed 's/\///g')
        id=$(jq --raw-output .[].Id <(echo "$container") | sed 's/\///g')

        while read -r volume_path; do
            volume_name=$(echo "$volume_path" | sed 's/\/var\/lib\/docker\/volumes\///' | sed 's/\/_data//')
            if [[ -n $volume_name ]]; then
                size=$(sudo du -sb "$volume_path" | cut -f 1)
                echo "docker_volume_fs_usage_bytes,container_name=${name},volume_name=${volume_name} container_id=\"${id}\",volume_path=\"${volume_path}\",size=${size}i"
            fi
        done <<< "$(jq -r '.[].Mounts[] | select( .Type == "volume" ) | .Source' <(echo "$container"))" # Returns a list of volume paths

    fi
done <<< "$(docker ps -aq)" # Returns a list of container IDs
