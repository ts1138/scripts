#!/usr/bin/python

import boto3
import sys
import os
from datetime import datetime, timedelta, timezone

# Define the file to store the last used ASG name
LAST_RUN_FILE = ".last_asg_run"

def save_last_asg(asg_name):
    """Saves the last successfully used ASG name to a file."""
    try:
        with open(LAST_RUN_FILE, "w") as f:
            f.write(asg_name)
    except IOError as e:
        print(f"Warning: Could not save the last run ASG name: {e}")

def read_last_asg():
    """Reads the last used ASG name from the file if it exists."""
    if os.path.exists(LAST_RUN_FILE):
        try:
            with open(LAST_RUN_FILE, "r") as f:
                return f.read().strip()
        except IOError as e:
            print(f"Warning: Could not read the last run file: {e}")
    return None

def select_asg():
    """
    Prompts the user to search for and select an Auto Scaling Group.

    Returns:
        str: The name of the selected Auto Scaling Group, or None if selection is cancelled.
    """
    client = boto3.client('autoscaling')
    
    try:
        # Use a paginator to handle accounts with many ASGs
        paginator = client.get_paginator('describe_auto_scaling_groups')
        all_asgs = []
        for page in paginator.paginate():
            all_asgs.extend(page['AutoScalingGroups'])
        
        all_asg_names = [asg['AutoScalingGroupName'] for asg in all_asgs]

    except Exception as e:
        print(f"Error fetching Auto Scaling Groups: {e}")
        return None

    if not all_asg_names:
        print("No Auto Scaling Groups found in this account.")
        return None

    while True:
        try:
            search_term = input("Enter the ASG name (Ctrl+C to exit): ").strip()
            if not search_term:
                print("Search term cannot be empty.")
                continue

            # Find matching ASGs (case-insensitive search)
            matching_asgs = [name for name in all_asg_names if search_term.lower() in name.lower()]

            if not matching_asgs:
                print(f"No ASGs found matching '{search_term}'. Please try again.")
                continue

            print("\nMatching ASGs found:")
            for i, name in enumerate(matching_asgs, 1):
                print(f"  {i}. {name}")

            while True:
                selection = input(f"\nSelect an ASG (1-{len(matching_asgs)}): ").strip()
                try:
                    selection_index = int(selection) - 1
                    if 0 <= selection_index < len(matching_asgs):
                        return matching_asgs[selection_index]
                    else:
                        print("Invalid number. Please select from the list.")
                except ValueError:
                    print("Invalid input. Please enter a number.")
        
        except KeyboardInterrupt:
            print("\nSelection cancelled. Exiting.")
            return None


def list_instances(asg_name):
    """
    Lists EC2 instances in a given Auto Scaling Group, sorted by launch time.
    Instances older than 10 days are highlighted in red.
    """
    client = boto3.client('autoscaling')
    ec2_client = boto3.client('ec2')

    # Define ANSI color codes for terminal output
    RED = "\033[91m"
    ENDC = "\033[0m"

    try:
        # Get instance IDs and lifecycle state from ASG
        asg_response = client.describe_auto_scaling_groups(AutoScalingGroupNames=[asg_name])
        
        if not asg_response['AutoScalingGroups']:
            print(f"Error: Auto Scaling Group '{asg_name}' not found.")
            return
            
        instances_in_asg = asg_response['AutoScalingGroups'][0]['Instances']
        if not instances_in_asg:
            print(f"Auto Scaling Group '{asg_name}' has no running instances.")
            return
            
        # Create a map of instance IDs to their lifecycle state
        lifecycle_map = {i['InstanceId']: i['LifecycleState'] for i in instances_in_asg}
        instance_ids = list(lifecycle_map.keys())

        # Get instance details from EC2
        ec2_response = ec2_client.describe_instances(InstanceIds=instance_ids)

        # Print ASG and Output Header 
        print(f"\n--- Auto Scaling Group: {asg_name} ---")
        print(f"{'Instance Name':<20} | {'Instance ID':<20} | {'Lifecycle':<12} | {'Platform':<12} | {'Private IP':<15} | {'Launch Time'}")
        print("-" * 115)


        # Collect instance information
        instances_list = []

        for reservation in ec2_response['Reservations']:
            for instance in reservation['Instances']:
                instance_id = instance['InstanceId']
                launch_time = instance['LaunchTime']
                launch_time_str = launch_time.strftime('%m-%d-%Y %H:%M:%S')
                private_ip = instance.get('PrivateIpAddress', 'N/A')
                tag_name = next((tag['Value'] for tag in instance.get('Tags', []) if tag['Key'] == 'Name'), 'N/A')
                platform = instance.get('PlatformDetails', 'Linux/UNIX') # More reliable than 'Platform'
                lifecycle_state = lifecycle_map.get(instance_id, 'N/A') # Get state from our map

                # Append instance details to the list
                instances_list.append({
                    'tag_name': tag_name,
                    'instance_id': instance_id,
                    'lifecycle_state': lifecycle_state,
                    'platform': platform,
                    'private_ip': private_ip,
                    'launch_time': launch_time,
                    'launch_time_str': launch_time_str
                })

        # Sort instances by launch_time
        instances_list.sort(key=lambda x: x['launch_time'])

        # Get the current time (timezone-aware) to compare with launch times
        ten_days_ago = datetime.now(timezone.utc) - timedelta(days=10)

        # Print sorted instances
        for inst in instances_list:
            output_line = f"{inst['tag_name']:<20} | {inst['instance_id']:<20} | {inst['lifecycle_state']:<12} | {inst['platform']:<12} | {inst['private_ip']:<15} | {inst['launch_time_str']}"
            
            # Check if the instance launch time is older than 10 days and print in red if it is
            if inst['launch_time'] < ten_days_ago:
                print(f"{RED}{output_line}{ENDC}")
            else:
                print(output_line)

    except KeyboardInterrupt:
        print("\nOperation cancelled by user.")
    except Exception as e:
        print(f"An error occurred: {e}")


if __name__ == "__main__":
    # Check for the '-last' or '--last' command-line argument
    if len(sys.argv) > 1 and sys.argv[1] in ['-last', '--last']:
        last_asg = read_last_asg()
        if last_asg:
            print(f"Re-running with the last used ASG: {last_asg}")
            list_instances(last_asg)
        else:
            # If -last is used but no file exists, fall back to interactive mode
            print("No last run found. Starting interactive selection.")
            selected_asg = select_asg()
            if selected_asg:
                save_last_asg(selected_asg)
                list_instances(selected_asg)
    else:
        # Default interactive mode
        selected_asg = select_asg()
        if selected_asg:
            # Save the selection for the next '-last' run
            save_last_asg(selected_asg)
            list_instances(selected_asg)

    # Usage: 
    # 1. Login to the AWS account where the ASG is present (e.g., via aws configure)
    # 2. To run interactively: python ASGInfo.py
    # 3. To re-run with the last used ASG: python ASGInfo.py -last
