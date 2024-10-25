import json
import boto3
import requests
import os
from botocore.exceptions import ClientError

# AWS clients
ec2_client = boto3.client('ec2')
ssm_client = boto3.client('ssm')

# Environment Variables
SECURITY_GROUP_ID = os.getenv("SECURITY_GROUP_ID")
TOR_EXIT_URL = "https://check.torproject.org/exit-addresses"

def fetch_tor_exit_ips():
    response = requests.get(TOR_EXIT_URL)
    tor_ips = []
    
    for line in response.text.splitlines():
        if line.startswith("ExitAddress"):
            tor_ips.append(line.split()[1])
    
    return tor_ips

def update_security_group(tor_ips):
    try:
        # Get current rules in security group
        current_rules = ec2_client.describe_security_group_rules(
            Filters=[{'Name': 'group-id', 'Values': [SECURITY_GROUP_ID]}]
        )['SecurityGroupRules']
        
        # Revoke current TOR IPs to clear before adding new ones
        for rule in current_rules:
            if rule['CidrIpv4'] in tor_ips:
                ec2_client.revoke_security_group_ingress(
                    GroupId=SECURITY_GROUP_ID,
                    IpPermissions=[{
                        'IpProtocol': rule['IpProtocol'],
                        'FromPort': rule['FromPort'],
                        'ToPort': rule['ToPort'],
                        'IpRanges': [{'CidrIp': rule['CidrIpv4']}]
                    }]
                )
        
        # Authorize the new TOR IPs
        for ip in tor_ips:
            ec2_client.authorize_security_group_ingress(
                GroupId=SECURITY_GROUP_ID,
                IpPermissions=[{
                    'IpProtocol': '-1',  # Block all protocols
                    'IpRanges': [{'CidrIp': f"{ip}/32"}]
                }]
            )
        print(f"Updated security group {SECURITY_GROUP_ID} with TOR IPs.")
    
    except ClientError as e:
        print(f"Error updating security group: {e}")
        raise

def lambda_handler(event, context):
    # Fetch TOR exit IPs
    tor_ips = fetch_tor_exit_ips()
    
    # Update the security group with TOR IPs
    update_security_group(tor_ips)
    
    return {
        "statusCode": 200,
        "body": json.dumps("Security group updated with TOR exit nodes.")
    }

