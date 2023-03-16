import os
import psycopg2
from aws_lambda_powertools import Logger
from aws_lambda_powertools.utilities.typing import LambdaContext

logger = Logger()

@logger.inject_lambda_context
def lambda_handler(event: dict, context: LambdaContext):
    user = event['request']['userAttributes']
    logger.info(user)

    user_display_name  = user['name']
    user_email         = user['email']
    user_handle        = user['preferred_username']
    user_cognito_id    = user['sub']

    try:
      sql = """
        INSERT INTO public.users (
            display_name,
            email,
            handle,
            cognito_user_id
        )
        VALUES(%s,%s,%s,%s)
      """
      conn = psycopg2.connect(os.getenv('CONNECTION_URL'))
      cur = conn.cursor()
      cur.execute(sql, (
        user_display_name,
        user_email,
        user_handle,
        user_cognito_id
      ))
      conn.commit()

    except (Exception, psycopg2.DatabaseError) as error:
      logger.error(error)

    finally:
      if conn is not None:
        cur.close()
        conn.close()
        logger.debug('database connection closed')

    return event