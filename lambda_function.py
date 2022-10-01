import json
import boto3
import os

def lambda_handler(event, context):
    # TODO implement
    
    client = boto3.client('dynamodb')
    
    table_name = os.getenv('DYNAMODB_TABLE')
    
    response = client.update_item(
        ExpressionAttributeValues = {
            ':val': {
                'N': '1',
            },
        },
        Key = {
            'visitor_type': {
                'S': 'web',
            },
        },
        TableName = table_name,
        UpdateExpression = 'SET visitor_count = visitor_count + :val',
    )
    
    return {
        'response': json.dumps(response),
    }