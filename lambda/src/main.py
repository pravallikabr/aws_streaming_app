
import boto3
import os,json, uuid, datetime


try:
    BUCKET_NAME = os.environ['bucket_name']
    PREFIX = os.environ['bucket_prefix']
    TOPIC_ARN = os.environ['topic_arn']
    SNS_CLIENT = boto3.client('sns')
    S3_CLIENT = boto3.client('s3')
except KeyError as error:
    print(
        "Failed to retrive ENV variables for boto3 initialisation. "
        "KeyError Exception: [%s]", error)

def handler(event, context):
    publish_to_s3(event)
    publish_to_sns(event)


def publish_to_sns(event):
    try:
        for record in event['Records']:
            message_body = record['body']

            SNS_CLIENT.publish(TargetArn=TOPIC_ARN,
                               Message=message_body,
                               MessageStructure='string')
    except Exception as e:
        print(
            "Raw Lambda failed to publish to SNS. "
            f"ClientError Exception:{e}")
    except KeyError as e:
        if str(error) == "'body'":
            print("KeyError Exception: not found in record:")
        print("KeyError Exception: not found in event.")


def publish_to_s3(event):
    try:
        event_records: str = None
        file_name = str(uuid.uuid4())
        partion_format = 'year=%Y/month=%m/day=%d/hour=%H'
        partition = datetime.datetime.now(
            datetime.timezone.utc).strftime(partion_format)
        key_in_timestamp = PREFIX + "/" + partition + "/" + file_name
        for record in event['Records']:
            body = record['body']
            if not event_records:
                event_records = body
            else:
                event_records = event_records + '\n' + body

        S3_CLIENT.put_object(Body=event_records,
                             Key=key_in_timestamp,
                             Bucket=BUCKET_NAME)
    except Exception as e:
        print(
            "Raw lambda failed to upload file to S3:"
            "ClientError Exception: Stack trace:")
        raise
    except KeyError as e:
        if str(error) == "'body'":
            print("KeyError Exception: not found in record:")
            raise
        print("KeyError Exception: not found in event.")
        raise
