import os
import urllib.parse
import boto3

sns = boto3.client("sns")

def lambda_handler(event, context):
    record = event["Records"][0]
    events = record["eventName"] 
    bucket = record["s3"]["bucket"]["name"]
    key  = urllib.parse.unquote_plus(record["s3"]["object"]["key"])

    if "ObjectRemoved" in events:
        action     = "deleted"
        details = ""
    else:
        action     = "added"
        size  = record["s3"]["object"].get("size", 0)
        details = f"\nSize: {size} bytes"

    message = (
        f"File {action} in S3!\n\n"
        f"Bucket: {bucket}\n"
        f"File: {key}"
        f"{details}"
    )

    sns.publish(
        TopicArn=os.environ["SNS_TOPIC_ARN"],
        Subject=f"[S3] File {action}: {key}",
        Message=message,
    )

    return {"statusCode": 200}