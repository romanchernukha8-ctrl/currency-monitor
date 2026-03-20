# Currency Monitor (Bash + API)
Simple Bash tool for monitoring currency exchange rates via API.

## Description
This project is a Bash-based tool for monitoring currency exchange rates using a public API.

It automatically checks exchange rates, compares them with previous values, and logs any changes.

## Features
- Fetches real-time currency data from API
- Supports multiple currencies
- Detects changes in exchange rates
- Retry mechanism for API failures
- JSON parsing using jq
- Logging of changes
- Configuration via .env file

## Technologies
- Bash
- curl
- jq
- Linux

## Project Structure

currency-monitor/
├── currency.sh
├── .env
├── .gitignore
├── README.md
├── .state/
└── currency.log


## How it works
1. The script sends a request to the API using curl
2. Parses JSON response using jq
3. Compares current rate with previous value
4. Logs changes if detected
5. Stores last known value in .state directory

## Usage

Make script executable:
```bash
chmod +x currency.sh
```md
Run the script:
```bash
./currency.sh
