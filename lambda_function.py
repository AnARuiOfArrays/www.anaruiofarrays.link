import json
import boto3
import os

def lambda_handler(event, context):

    client = boto3.client('dynamodb')
    
    table = os.getenv('DYNAMODB_TABLE')
    
    get_item_response = client.get_item(
        TableName = table,
        Key = {
            'visitor_type': {
                'S': 'web',
            },
        },
        ProjectionExpression= 'visitor_count',
    )
    print(get_item_response)
    
    update_item_response = client.update_item(
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
        ReturnValues = 'UPDATED_NEW',
        TableName = table,
        UpdateExpression = 'SET visitor_count = visitor_count + :val',
    )
    print(update_item_response)
    
    """
    Test value should equal true because old value should be less than new value
    """
    print(get_item_response['Item']['visitor_count']['N'] + " < " + 
    update_item_response['Attributes']['visitor_count']['N'])
    
    assert (get_item_response['Item']['visitor_count']['N'] < 
    update_item_response['Attributes']['visitor_count']['N']) == True

    
    """
    Test value should equal false because new value should not be less than old value
    """
    print(update_item_response['Attributes']['visitor_count']['N'] + " < " + 
    get_item_response['Item']['visitor_count']['N'])
    assert (update_item_response['Attributes']['visitor_count']['N'] < 
    get_item_response['Item']['visitor_count']['N']) == False
    
    return {
        'statusCode': 200,
        'headers': {
            'Access-Control-Allow-Origin': 'https://www.anaruiofarrays.link'
        },
        'body': json.dumps(update_item_response['Attributes']['visitor_count']['N']),
    }
