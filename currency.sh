#!/bin/bash

# Load environment variables from .env file
if [ -f ".env" ]; then
    source .env
else
    echo "Error: .env file not found"
    exit 1
fi

# File for logging changes and errors
LOG_FILE="currency.log"

# Directory where previous currency values are stored
STATE_DIR=".state"

# Colors for terminal output
GREEN="\e[32m"
RED="\e[31m"
YELLOW="\e[33m"
NC="\e[0m"

# Check if jq is installed (required for JSON parsing)
if ! command -v jq &> /dev/null; then
    echo -e "${RED}Error: jq is not installed${NC}"
    exit 1
fi

# Create directory for storing previous values (if not exists)
mkdir -p "$STATE_DIR"

# Function to request API data with retry mechanism
get_api_data() {
    local currency=$1	# Currency code (e.g., EUR)
    local attempt=1	# Current retry attempt
    local response	# API response

    # Retry loop
    while [ $attempt -le $RETRY_COUNT ]; do

	# Send request to API
        response=$(curl -s --fail "${API_URL}?valcode=${currency}&json")

	# If request succeeded and response is not empty
        if [ $? -eq 0 ] && [ -n "$response" ]; then
            echo "$response"
            return 0
        fi

	# Retry message
        echo -e "${YELLOW}Retry $attempt/$RETRY_COUNT for $currency...${NC}"
        sleep $RETRY_DELAY
        ((attempt++))
    done

    return 1
}

# Loop through all currencies from .env
for CURRENCY in $CURRENCIES; do

    echo -e "\nChecking $CURRENCY..."

    # File that stores last known rate for this currency 
    STATE_FILE="$STATE_DIR/${CURRENCY}.txt"

    # Get data from API
    response=$(get_api_data "$CURRENCY")

    # If API request failed → log and continue
    if [ $? -ne 0 ]; then
        echo -e "${RED}Error: API failed for $CURRENCY${NC}"
        echo "$(date) - ERROR: API failed for $CURRENCY" >> "$LOG_FILE"
        continue
    fi

    # Extract rate and date from JSON response
    rate=$(echo "$response" | jq -r '.[0].rate')
    date_rate=$(echo "$response" | jq -r '.[0].exchangedate')

    # Validate API response
    if [ "$rate" == "null" ] || [ -z "$rate" ]; then
        echo -e "${RED}Invalid response for $CURRENCY${NC}"
        continue
    fi

    # Load previous rate if exists
    if [ -f "$STATE_FILE" ]; then
        old_rate=$(cat "$STATE_FILE")
    else
        old_rate=""
    fi

    # Compare current rate with previous one
    if [ "$rate" != "$old_rate" ]; then
        echo -e "${GREEN}Updated!${NC}"
        echo "Currency: $CURRENCY"
        echo "Old: ${old_rate:-N/A}"
        echo "New: $rate"
        echo "Date: $date_rate"

        echo "$rate" > "$STATE_FILE"

        echo "$(date) - $CURRENCY changed: $old_rate -> $rate" >> "$LOG_FILE"
    else
	# No changes detected
        echo -e "${GREEN}No change${NC} ($rate)"
    fi

done
