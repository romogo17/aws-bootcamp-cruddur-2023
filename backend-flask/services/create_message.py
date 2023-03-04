import uuid
from datetime import datetime, timedelta, timezone

from opentelemetry import trace

tracer = trace.get_tracer("create.message")

class CreateMessage:
  def run(message, user_sender_handle, user_receiver_handle):
    with tracer.start_as_current_span("create-message-mock-data"):
      model = {
        'errors': None,
        'data': None
      }
      if user_sender_handle == None or len(user_sender_handle) < 1:
        model['errors'] = ['user_sender_handle_blank']

      if user_receiver_handle == None or len(user_receiver_handle) < 1:
        model['errors'] = ['user_reciever_handle_blank']

      if message == None or len(message) < 1:
        model['errors'] = ['message_blank'] 
      elif len(message) > 1024:
        model['errors'] = ['message_exceed_max_chars'] 

      if model['errors']:
        # return what we provided
        model['data'] = {
          'display_name': 'Andrew Brown',
          'handle':  user_sender_handle,
          'message': message
        }
      else:
        now = datetime.now(timezone.utc).astimezone()
        model['data'] = {
          'uuid': uuid.uuid4(),
          'display_name': 'Andrew Brown',
          'handle':  user_sender_handle,
          'message': message,
          'created_at': now.isoformat()
        }
      span = trace.get_current_span()
      span.set_attribute("app.user_sender_handle", user_sender_handle)
      span.set_attribute("app.user_receiver_handle", user_receiver_handle)
      return model