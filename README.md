
![Logo](https://raw.githubusercontent.com/BLY-Coder/GCP-Guardian/main/logo.png)

# GCP-Guardian

The GCP-Guardian is a script that allows you to scan your Google Cloud Platform (GCP) projects for potential security vulnerabilities and configuration issues. It provides various scanning options for BigQuery, Cloud Storage, public IP addresses, and unauthorized storage permissions. The script also allows you to list all existing projects and retrieve the IAM policy of a specific project.

## Prerequisites

- Bash (Bourne Again SHell)
- Google Cloud SDK (gcloud)
- curl
- jq

## Usage

1. Clone the repository or download the script file `gcp_security_scanner.sh` to your local machine.
2. Open a terminal and navigate to the directory where the script is located.
3. Run the script using the following command:

```bash
GCP-Guardian.sh -h
Usage: test.sh [-a] [-b] [-s] [-i] [-c] [-l] [-p project] [-x] [-h]
Options:
  -a: Run all scans (BigQuery, Cloud Storage, IP, and unauthorized storage permissions check)
  -b: Enumerate BigQuery
  -s: Enumerate Cloud Storage
  -i: Enumerate public IP addresses of VMs
  -c: Check for unauthorized storage permissions
  -l: List all projects
  -p project: Get IAM policy of a specific project
  -x: Enumerate secrets
  -h: Show this help menu
```
***All options save the outputs in files***
 ## Options

Replace `[options]` with one or more of the following options:

- `-a`: Run all scans (BigQuery, Cloud Storage, IP addresses, and unauthorized storage permissions).
- `-b`: Enumerate BigQuery datasets.
- `-s`: Enumerate Cloud Storage buckets.
- `-i`: Enumerate public IP addresses of VM instances.
- `-c`: Check for unauthorized storage permissions.
- `-l`: List all existing projects.
- `-p project_id`: Get the IAM policy of the specified project.

View the scan results and output displayed in the terminal.

## License

[MIT](https://choosealicense.com/licenses/mit/)

