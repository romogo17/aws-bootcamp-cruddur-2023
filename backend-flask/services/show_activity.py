from datetime import datetime, timedelta, timezone

from opentelemetry import trace

tracer = trace.get_tracer("show.activity")

class ShowActivities:
  def run(activity_uuid):
    with tracer.start_as_current_span("show-activity-mock-data"):
      now = datetime.now(timezone.utc).astimezone()
      results = [{
        'uuid': '68f126b0-1ceb-4a33-88be-d90fa7109eee',
        'handle':  'Andrew Brown',
        'message': 'Cloud is fun!',
        'created_at': (now - timedelta(days=2)).isoformat(),
        'expires_at': (now + timedelta(days=5)).isoformat(),
        'replies': {
          'uuid': '26e12864-1c26-5c3a-9658-97a10f8fea67',
          'handle':  'Worf',
          'message': 'This post has no honor!',
          'created_at': (now - timedelta(days=2)).isoformat()
        }
      }]
      return results