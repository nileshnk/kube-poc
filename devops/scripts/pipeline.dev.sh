#!/bin/bash

# Variables initialization
services_list=("user-management" "media-management")

# Function to get the last commit hash
get_last_commit_hash() {
    git rev-parse HEAD 2>/dev/null
}

# Function to get the previous commit hash
get_prev_commit_hash() {
    git rev-parse HEAD~1 2>/dev/null
}

# Function to get the folder hash
get_folder_hash() {
    local folder_hash=0
    for file in $(find "$1" -type f); do
        # MacOS compatible format specifiers are "%z %m". For Linux compatibility use "%s %Y"
        # local file_stat=($(stat --format "%s %Y" "$file"))
        local file_stat=($(stat -f "%z %m" "$file"))
        local file_size="${file_stat[0]}"
        local file_mtime="${file_stat[1]}"
        local file_identifier="$((file_size ^ file_mtime))"
        folder_hash=$((folder_hash ^ file_identifier))
    done
    printf '%x' "$folder_hash"
}

# Function to check if a folder has changed
folder_changed() {
    local last_commit_hash="$(get_last_commit_hash)"
    local prev_commit_hash="$(get_prev_commit_hash)"
    if [ -z "$last_commit_hash" ] || [ -z "$prev_commit_hash" ]; then
        echo "Error: No Git repository found or not enough commits."
        return 1
    fi

    local current_folder_hash="$(get_folder_hash "$1")"

    local last_commit_with_same_hash=$(git rev-list -n 1 --grep "hash:$current_folder_hash" "$prev_commit_hash..$last_commit_hash" 2>/dev/null)
    [ "$last_commit_with_same_hash" != "$prev_commit_hash" ]
}

test_service() {
    echo $1
}

deploy_service() {
    echo -e "\nDeploying $1..."

    ls -la services/$1

    REGISTRY_URL="127.0.0.1:5555"
    LAST_COMMIT_ID="$(get_last_commit_hash)"

    docker build -t "$1-dev" --platform linux/amd64 services/$1
    docker tag "$1-dev:latest" "$REGISTRY_URL/$1-dev:latest"
    docker push "$REGISTRY_URL/$1-dev:latest"
    docker tag "$1-dev:latest" "$REGISTRY_URL/$1-dev:$LAST_COMMIT_ID"
    docker push "$REGISTRY_URL/$1-dev:$LAST_COMMIT_ID"

}

process_service_testing() {
    echo "Testing of the services will start now in the following order:"

    local modified_services=("$@")  # Capture all arguments as an array
    for service in "${modified_services[@]}"; do
        echo "Service: ${service}"
    done

    # Deploy each service one by one 
    for service in "${modified_services[@]}"; do
        test_service $service
    done

}

process_service_modifications() {
    local modified_services=("$@")  # Capture all arguments as an array
    
    # process testing if needed or after some conditions
    # process_service_testing "${modified_services[@]}"

    # Configure Deployment environment. E.g AWS setup or Kubernetes setup

    echo "Deployment of the services will start now in the following order:"

    for service in "${modified_services[@]}"; do
        echo "Service: ${service}"
    done

    # Deploy each service one by one 
    for service in "${modified_services[@]}"; do
        deploy_service $service
    done

}

process_package_modifications() {
    
    process_service_modifications "${services_list[@]}"

}

main() {
    local base_dir="$1"
    if [ ! -d "$base_dir" ]; then
        echo "Error: '$base_dir' is not a directory."
        return 1
    fi

    local last_commit_hash="$(get_last_commit_hash)"
    local prev_commit_hash="$(get_prev_commit_hash)"
    if [ -z "$last_commit_hash" ] || [ -z "$prev_commit_hash" ]; then
        echo "Error: No Git repository found or not enough commits."
        return 1
    fi

    for folder in "$base_dir"/*; do
        if [ -d "$folder" ]; then
            local folder_name=$(basename "$folder")
            if [[ "$folder_name" != "env" && "$folder_name" != "node_modules" && "$folder_name" != "devops" ]]; then
                if folder_changed "$folder"; then
                    echo "Checking in folder: $folder"
                    if [ "$folder" == "$base_dir/services" ]; then
                        declare -a changed_services
                        # pushing the inputs in array
                        while IFS= read -r line; do
                            changed_services+=("$line")
                        done < <(git diff --name-only "$prev_commit_hash" "$last_commit_hash" -- "$folder" 2>/dev/null | awk -F "/" '{sub(/^.*backend\//, ""); print $0}' | awk -F "/" '{print $2}' | uniq)

                        if [ ${#changed_services[@]} -eq 0 ]; then
                            echo "No services have been changed."
                        else
                            echo -e "These services will be redeployed: ${changed_services[*]} \n"
                            process_service_modifications "${changed_services[@]}"
                        fi                        

                    elif [ "$folder" == "$base_dir/packages" ]; then
                        local changed_package=$(git diff --name-only "$prev_commit_hash" "$last_commit_hash" -- "$folder" 2>/dev/null | awk -F "/" '{sub(/^.*backend\//, ""); print $0}' | awk -F "/" '{print $2}' | uniq)
                        if [ -n "$changed_package" ]; then
                            echo "Change in packages found! All services will be redeployed"
                            echo "Changed package: $changed_package"
                            
                            process_package_modifications
                            break
                        fi
                    fi
                    echo ""
                fi
            fi
        fi
    done
}

# Usage: main /path/to/base/directory
base_dir="${1:-$(pwd)}"
main "$base_dir"