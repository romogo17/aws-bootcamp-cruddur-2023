from datetime import datetime, timedelta, timezone
from aws_xray_sdk.core import xray_recorder

from opentelemetry import trace

tracer = trace.get_tracer("user.activities")

# try:
#   xray_recorder.current_segment()
# except:
#   xray_recorder.begin_segment('user.activities')

class UserActivities:
  def run(user_handle):
    with tracer.start_as_current_span("user-activities-mock-data"):
      model = {
        'errors': None,
        'data': None
      }

      now = datetime.now(timezone.utc).astimezone()

      if user_handle == None or len(user_handle) < 1:
        model['errors'] = ['blank_user_handle']
      else:
        now = datetime.now()
        results = [{
          'uuid': '248959df-3079-4947-b847-9e0892d1bab4',
          'handle':  'Andrew Brown',
          'message': 'Cloud is fun!',
          'created_at': (now - timedelta(days=1)).isoformat(),
          'expires_at': (now + timedelta(days=31)).isoformat()
        }]
        model['data'] = results

      # xray ---
      # subsegment = xray_recorder.begin_subsegment('user-activities-mock-data')
      # metadata = {
      #   "app.now": now.isoformat(),
      #   "app.result_length": len(model['data'])
      # }
      # subsegment.put_metadata('key', metadata, 'namespace')
      # xray_recorder.end_subsegment()

      span = trace.get_current_span()
      span.set_attribute("app.user_handle", user_handle)

      return model