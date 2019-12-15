import boto3
import configparser,os
import logging
from botocore.exceptions import ClientError

config = configparser.ConfigParser()
AWS_PROFILE = "default"
config.read(os.path.expanduser("~/.aws/credentials"))
access_id = config.get(AWS_PROFILE, "aws_access_key_id")
access_key = config.get(AWS_PROFILE, "aws_secret_access_key")
# Create SQS client
sqs = boto3.client('sqs',
                    aws_access_key_id = access_id,
                    aws_secret_access_key = access_key
)

queue_url = 'https://sqs.eu-west-1.amazonaws.com/094529590173/streaming-app_raj_raw'

def send_sqs_message(sqs_queue_url, msg_body):
    """

    :param sqs_queue_url: String URL of existing SQS queue
    :param msg_body: String message body
    :return: Dictionary containing information about the sent message. If
        error, returns None.
    """

    # Send the SQS message
    sqs_client = boto3.client('sqs')
    try:
        msg = sqs_client.send_message(QueueUrl=sqs_queue_url,
                                      MessageBody=msg_body)
    except ClientError as e:
        logging.error(e)
        return None
    return msg


def main():
    """Exercise send_sqs_message()"""

    # Assign this value before running the program
    sqs_queue_url = queue_url

    # Set up logging
    logging.basicConfig(level=logging.INFO,
                        format='%(levelname)s: %(asctime)s: %(message)s')

    # Send some SQS messages
    for i in range(1, 6):
        msg_body = f'{{"row" : {i} , "name" : "raj", "age" : 34}}'
        msg = send_sqs_message(sqs_queue_url, msg_body)
        if msg is not None:
            logging.info(f'Sent SQS message ID: {msg["MessageId"]}')


if __name__ == '__main__':
    main()