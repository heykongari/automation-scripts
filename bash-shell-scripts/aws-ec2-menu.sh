#!/bin/bash

# Define a function to check for existing key-pairs.
check_key_pair() {

    # list existing key-pairs (if any) in an array.
    mapfile -t pem_keys < <(find ~/.aws -type f -name "*.pem")

    # no key-pair found.
    if [[ ${#pem_keys[@]} -eq 0 ]]; then
        echo "No existing key-pair(s) found. Make sure .pem file is in ~/.aws/ directory."
        return
    fi

    # proceed automatically if there's only one key.
    if [[ ${#pem_keys[@]} -eq 1 ]]; then
        selected_key=$(basename "${pem_keys[0]}" .pem)
        echo "One key-pair found. Using $selected_key.pem"
        return
    fi

    # select a key if multiple keys found.
    echo "Choose a key to proceed: ${#pem_keys[@]}"
    select key in ${pem_keys[@]}; do
        if [[ -n "$key" ]]; then
            selected_key=$(basename "$key" .pem)
            echo "Using $selected_key.pem"
            break
        else
            echo "Invalid choice. Select a valid key number."
        fi
    done
}

# Define a function to create a new key-pair.
#!/bin/bash

create_key_pair() {

    echo "Creating a new key-pair..."
    # specify key-name and key-region.
    while true; do
        read -p "Enter a name: " KEY_NAME
        if [[ -n $KEY_NAME ]]; then
            break
        else
            echo "Input cannot be empty. Please enter a valid name."
        fi
    done
    read -p "Enter a region (default region is set to us-east-1): " KEY_REGION
    
    # ensure target directory exists.
    mkdir -p ~/.aws/

    # aws command to create a key pair.
    if [[ -n "$KEY_REGION" ]]; then
        aws ec2 create-key-pair \
        --key-name $KEY_NAME \
        --query "KeyMaterial" \
        --region $KEY_REGION \
        --output text > ~/.aws/"$KEY_NAME".pem
    else
        aws ec2 create-key-pair \
        --key-name $KEY_NAME \
        --query "KeyMaterial" \
        --output text > ~/.aws/"$KEY_NAME".pem
    fi

    # Change file permissions to read only. Mandatory.
    if [ $? -eq 0 ]; then
        chmod 400 ~/.aws/$KEY_NAME.pem
        echo "Key-pair $KEY_NAME created and saved to ~/.aws/$KEY_NAME.pem successfully."
    else
        echo "Failed to create key-pair."
        return 1
    fi
}

check_key_pair
create_key_pair
