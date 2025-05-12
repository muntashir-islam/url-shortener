import json
import boto3
import os
import string
import random
import logging
from urllib.parse import urlparse

logger = logging.getLogger()
logger.setLevel(logging.INFO)

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.environ['TABLE_NAME'])

def generate_short_code(length=6):
    return ''.join(random.choices(string.ascii_letters + string.digits, k=length))

def lambda_handler(event, context):
    logger.info("Received event: %s", json.dumps(event))
    method = event.get('requestContext', {}).get('http', {}).get('method', '')

    if method == 'POST':
        try:
            body = json.loads(event.get('body', '{}'))
            long_url = body.get('url')
            if not long_url or not urlparse(long_url).scheme:
                return {"statusCode": 400, "body": json.dumps({"error": "Invalid URL"})}

            short_code = generate_short_code()
            table.put_item(Item={'short_code': short_code, 'long_url': long_url})

            domain = event['headers'].get('Host', 'example.com')
            short_url = f"https://{domain}/{short_code}"

            return {
                "statusCode": 200,
                "headers": {"Content-Type": "application/json"},
                "body": json.dumps({"short_url": short_url})
            }
        except Exception as e:
            logger.exception("Error during POST")
            return {"statusCode": 500, "body": json.dumps({"error": str(e)})}

    elif method == 'GET':
        try:
            path_params = event.get('pathParameters', {})
            short_code = path_params.get('short_code')

            if not short_code:
                return {"statusCode": 400, "body": json.dumps({"error": "Missing short code"})}

            response = table.get_item(Key={'short_code': short_code})
            if 'Item' in response:
                return {
                    "statusCode": 301,
                    "headers": {"Location": response['Item']['long_url']}
                }
            else:
                return {"statusCode": 404, "body": json.dumps({"error": "URL not found"})}
        except Exception as e:
            logger.exception("Error during GET")
            return {"statusCode": 500, "body": json.dumps({"error": str(e)})}

    else:
        return {"statusCode": 405, "body": json.dumps({"error": "Method not allowed"})}
