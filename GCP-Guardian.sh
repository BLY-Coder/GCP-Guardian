#!/bin/bash

# Colors
BLUE='\033[1;34m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No color

# Disable confirmation prompts
export CLOUDSDK_CORE_DISABLE_PROMPTS=1

# Scan options
run_all=false
run_bigquery=false
run_storage=false
run_ip=false
run_check_unauth_storage=false
run_list_projects=false
run_secrets=false
project=""
iam_file=""
secrets_file="secrets.txt"

# Output file names
permissions_file="bqpermissions.txt"
storage_file="gcpstorage.txt"
ip_file="ips.txt"
unauth_permissions_file="unauthpermissions.txt"
projects_file="projects.txt"

# Function to enumerate BigQuery
enumerate_bigquery() {
  echo -e "${BLUE}Enumerating BigQuery...${NC}"
  for p in $(gcloud projects list --format="value(projectId)");do
  	for i in $(bq ls --project_id $p 2>/dev/null | grep -v "datasetId"); do
    		if [ "$i" != "----------------------" ]; then
      			bq show --format=pretty $p:$i >> "$permissions_file" 2>/dev/null
    		fi
  	done
  done
  echo -e "${GREEN}BigQuery scan has completed.${NC}"
}

# Function to enumerate Cloud Storage
enumerate_storage() {
  echo -e "${BLUE}Enumerating Cloud Storage...${NC}"
  for i in $(gcloud projects list --sort-by=projectId | cut -d ' ' -f1 | grep -v "PROJECT_ID"); do
    gsutil ls -p "$i" >> "$storage_file"
  done
  echo -e "${GREEN}Cloud Storage scan has completed.${NC}"
}

# Function to enumerate public IP addresses of VMs
enumerate_ip() {
  echo -e "${BLUE}Enumerating public IP addresses...${NC}"
  # Get the list of projects
  projects=$(gcloud projects list --format="value(projectId)")

  # Iterate over each project
  for project in $projects; do
    echo -e "${YELLOW}Project: $project${NC}"
    echo "=============================="

    # Get the list of VM instances in the project
    instances=$(gcloud compute instances list --project $project --format="value(name,networkInterfaces[0].accessConfigs[0].natIP)")

    # Iterate over each VM instance
    while IFS= read -r line; do
      instance=$(echo "$line" | awk '{print $1}')
      ip=$(echo "$line" | awk '{print $2}')

      # Save the information to the output file only if the IP is not empty
      if [[ -n $ip ]]; then
        echo "Project: $project - IP: $ip" >> "$ip_file"
      fi
    done <<< "$instances"

    echo ""
  done

  echo -e "${GREEN}Enumeration of public IP addresses has completed.${NC}"
}

# Function to check for unauthorized storage permissions
check_unauth_storage() {
  echo -e "${BLUE}Checking for unauthorized storage permissions...${NC}"
  while IFS= read -r storage; do
    storage_name=$(basename "$storage")
    echo "Storage name: $storage_name"
    echo "=============================="
    permissions=$(curl -s "https://www.googleapis.com/storage/v1/b/$storage_name/iam/testPermissions?permissions=storage.buckets.delete&permissions=storage.buckets.get&permissions=storage.buckets.getIamPolicy&permissions=storage.buckets.setIamPolicy&permissions=storage.buckets.update&permissions=storage.objects.create&permissions=storage.objects.delete&permissions=storage.objects.get&permissions=storage.objects.list&permissions=storage.objects.update")
    if [[ $permissions == *"\"permissions\": ["* ]]; then
      echo "Storage name: $storage_name" >> "$unauth_permissions_file"
      echo "$permissions" >> "$unauth_permissions_file"
    fi
    echo ""
  done < <(grep -o "gs://[^[:space:]]*" "$storage_file")

  echo -e "${GREEN}Check for unauthorized storage permissions has completed.${NC}"
}

# Function to list all existing projects
list_projects() {
  echo -e "${BLUE}Listing projects...${NC}"
  gcloud projects list --format="value(projectId)" > "$projects_file"
  echo -e "${GREEN}The list of projects has been stored in $projects_file.${NC}"
}

# Function to enumerate secrets
enumerate_secrets() {
  echo -e "${BLUE}Enumerating secrets...${NC}"
  for project in $(gcloud projects list --format="value(projectId)" 2>/dev/null); do
    echo -e "${YELLOW}Project: $project${NC}"
    echo "=============================="
    secret=$(gcloud secrets list --project="$project" >> "$secrets_file" 2>/dev/null)
    echo "Enumerating secrets... output saved on $secrets_file"
    echo ""
  done
  echo -e "${GREEN}Secrets enumeration has completed.${NC}"
}

# Function to get IAM policy of a specific project
get_iam_policy() {
  echo -e "${BLUE}Getting IAM policy of project $project...${NC}"
  gcloud projects get-iam-policy "$project" > "$iam_file"
  echo -e "${GREEN}The IAM policy of project $project has been stored in $iam_file.${NC}"
}

# Parse arguments
if [ $# -eq 0 ]; then
  # No arguments provided, display help menu
  echo -e "${BLUE}Usage: $0 [-a] [-b] [-s] [-i] [-c] [-l] [-p project] [-x] [-h]${NC}"
  echo -e "${GREEN}Options:${NC}"
  echo -e "${YELLOW}  -a: Run all scans${NC}"
  echo -e "${YELLOW}  -b: Enumerate BigQuery${NC}"
  echo -e "${YELLOW}  -s: Enumerate Cloud Storage${NC}"
  echo -e "${YELLOW}  -i: Enumerate public IP addresses of VMs${NC}"
  echo -e "${YELLOW}  -c: Check for unauthorized storage permissions${NC}"
  echo -e "${YELLOW}  -l: List all projects${NC}"
  echo -e "${YELLOW}  -p project: Get IAM policy of a specific project${NC}"
  echo -e "${YELLOW}  -x: Enumerate secrets${NC}"
  echo -e "${YELLOW}  -h: Show this help menu${NC}"
  exit 0
fi

while getopts "absihclpx" opt; do
  case ${opt} in
    a)
      run_all=true
      ;;
    b)
      run_bigquery=true
      ;;
    s)
      run_storage=true
      ;;
    i)
      run_ip=true
      ;;
    c)
      run_check_unauth_storage=true
      ;;
    l)
      run_list_projects=true
      ;;
    p)
      project=$OPTARG
      iam_file="iam-${project}.txt"
      ;;
    x)
      run_secrets=true
      ;;
    h | *)
      # Display help menu
      echo -e "${BLUE}Usage: $0 [-a] [-b] [-s] [-i] [-c] [-l] [-p project] [-x] [-h]${NC}"
      echo -e "${GREEN}Options:${NC}"
      echo -e "${YELLOW}  -a: Run all scans${NC}"
      echo -e "${YELLOW}  -b: Enumerate BigQuery${NC}"
      echo -e "${YELLOW}  -s: Enumerate Cloud Storage${NC}"
      echo -e "${YELLOW}  -i: Enumerate public IP addresses of VMs${NC}"
      echo -e "${YELLOW}  -c: Check for unauthorized storage permissions${NC}"
      echo -e "${YELLOW}  -l: List all projects${NC}"
      echo -e "${YELLOW}  -p project: Get IAM policy of a specific project${NC}"
      echo -e "${YELLOW}  -x: Enumerate secrets${NC}"
      echo -e "${YELLOW}  -h: Show this help menu${NC}"
      exit 1
      ;;
  esac
done

# Run the selected scans
if $run_all; then
  run_bigquery=true
  run_storage=true
  run_ip=true
  run_check_unauth_storage=true
fi

if $run_bigquery; then
  enumerate_bigquery
fi

if $run_storage; then
  enumerate_storage
fi

if $run_ip; then
  enumerate_ip
fi

if $run_check_unauth_storage; then
  check_unauth_storage
fi

if $run_list_projects; then
  list_projects
fi

if $run_secrets; then
  enumerate_secrets
fi

if [[ -n $project ]]; then
  get_iam_policy
fi
