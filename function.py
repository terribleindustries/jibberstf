import boto3
import os

# 185.199.108.153
# 185.199.109.153
# 185.199.110.153
# 185.199.111.153

github_ips = '185.199.108.153'

def change_record(ip_address):
    record_name = os.environ.get('RECORD_NAME')
    hosted_zone_id = os.environ.get('ZONE_ID')
    client = boto3.client('route53')
    client.change_resource_record_sets(
        HostedZoneId=hosted_zone_id,
        ChangeBatch={
            "Comment": "Automatic DNS update",
            "Changes": [
                {
                    "Action": "UPSERT",
                    "ResourceRecordSet": {
                        "Name": record_name,
                        "Type": "A",
                        "TTL": 180,
                        "ResourceRecords": [
                            {
                                "Value": ip_address
                            },
                        ],
                    }
                },
            ]
        }
    )

def update_record(state, instance_details):
    if state in ['pending', 'running']:
        # Switch to this instance
        change_record(instance_details['PublicIpAddress'])
    elif state in ['shutting-down', 'stopped', 'stopping', 'terminated']:
        # Switch to remote site
        change_record(github_ips)
    else:
        print('ERROR unknown state: {}'.format(state))
        exit(1)

# Example event:
# {
#    "id":"7bf73129-1428-4cd3-a780-95db273d1602",
#    "detail-type":"EC2 Instance State-change Notification",
#    "source":"aws.ec2",
#    "account":"123456789012",
#    "time":"2019-11-11T21:29:54Z",
#    "region":"us-east-1",
#    "resources":[
#       "arn:aws:ec2:us-east-1:123456789012:instance/i-abcd1111"
#    ],
#    "detail":{
#       "instance-id":"i-abcd1111",
#       "state":"pending"
#    }
# }

def my_handler(event, context):
    instance_id = event['detail']['instance-id']
    state = event['detail']['state']
    client = boto3.client('ec2')
    details = client.describe_instances(InstanceIds=[instance_id,])
    tags = details['Reservations'][0]['Instances'][0]['Tags']
    instance_details = details['Reservations'][0]['Instances'][0]
    for tag in tags:
        if tag['Key'] == 'movienight':
            update_record(state, instance_details)

