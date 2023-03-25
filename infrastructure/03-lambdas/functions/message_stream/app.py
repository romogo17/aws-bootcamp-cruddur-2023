import boto3
from boto3.dynamodb.conditions import Key

from aws_lambda_powertools import Logger
from aws_lambda_powertools.utilities.typing import LambdaContext

dynamodb = boto3.resource(
  'dynamodb',
  region_name='us-east-1',
  endpoint_url="http://dynamodb.us-east-1.amazonaws.com"
)

logger = Logger()

@logger.inject_lambda_context
def lambda_handler(event: dict, context: LambdaContext):
  pk = event['Records'][0]['dynamodb']['Keys']['pk']['S']
  sk = event['Records'][0]['dynamodb']['Keys']['sk']['S']

  eventName = event['Records'][0]['eventName']
  if eventName == 'REMOVE':
    return

  logger.info(f"pk={pk}, sk={sk}")
  logger.info(f"event={event}")
  if pk.startswith('MSG#'):
    group_uuid = pk.replace("MSG#","")
    message = event['Records'][0]['dynamodb']['NewImage']['message']['S']
    logger.info(f"message_group_uuid={group_uuid}, message={message}")

    table_name = 'cruddur-messages'
    index_name = 'message-group-sk-index'
    table = dynamodb.Table(table_name)
    data = table.query(
      IndexName=index_name,
      KeyConditionExpression=Key('message_group_uuid').eq(group_uuid)
    )
    logger.info(f"response={data['Items']}")

    # recreate the message group rows with new SK value
    for i in data['Items']:
      delete_item = table.delete_item(Key={'pk': i['pk'], 'sk': i['sk']})
      logger.info(f"delete_item={delete_item}")

      response = table.put_item(
        Item={
          'pk': i['pk'],
          'sk': sk,
          'message_group_uuid':i['message_group_uuid'],
          'message':message,
          'user_display_name': i['user_display_name'],
          'user_handle': i['user_handle'],
          'user_uuid': i['user_uuid']
        }
      )
      logger.info(f"create_reponse={response}")