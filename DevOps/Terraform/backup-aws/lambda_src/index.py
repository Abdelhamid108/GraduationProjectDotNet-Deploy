import boto3
import os

# Grab the region and instance ID from Lambda Environment Variables
REGION = os.environ.get('REGION', 'us-east-1')
INSTANCE_ID = os.environ.get('INSTANCE_ID')

ec2 = boto3.client('ec2', region_name=REGION)

def lambda_handler(event, context):
    if not INSTANCE_ID:
        return {'statusCode': 400, 'body': 'INSTANCE_ID environment variable is missing'}

    try:
        # 1. Check the current status of the instance
        response = ec2.describe_instances(InstanceIds=[INSTANCE_ID])
        
        # Extract the state name (e.g., 'running', 'stopped', 'pending', 'stopping')
        state = response['Reservations'][0]['Instances'][0]['State']['Name']
        
        # 2. Decide what to do based on the state
        if state == 'running':
            return {
                'statusCode': 200,
                'body': f'Instance {INSTANCE_ID} is already running. No action needed.'
            }
            
        elif state == 'stopped':
            # 3. Start the instance if it's strictly 'stopped'
            ec2.start_instances(InstanceIds=[INSTANCE_ID])
            return {
                'statusCode': 200,
                'body': f'Instance {INSTANCE_ID} was stopped and is now starting.'
            }
            
        else:
            # Handle transition states like 'pending' or 'stopping'
            return {
                'statusCode': 200,
                'body': f'Instance {INSTANCE_ID} is currently in a "{state}" state. Please wait.'
            }
            
    except Exception as e:
        print(f"Error checking or starting instance {INSTANCE_ID}: {str(e)}")
        return {
            'statusCode': 500,
            'body': 'Failed to process instance. Check CloudWatch logs for details.'
        }
