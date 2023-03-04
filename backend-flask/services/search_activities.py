from datetime import datetime, timedelta, timezone

from opentelemetry import trace

tracer = trace.get_tracer("search.activities")

class SearchActivities:
  def run(search_term):
    with tracer.start_as_current_span("search-activities-mock-data"):
      model = {
        'errors': None,
        'data': None
      }

      now = datetime.now(timezone.utc).astimezone()
      span = trace.get_current_span()
      span.set_attribute("app.now", now.isoformat())

      if search_term == None or len(search_term) < 1:
        model['errors'] = ['search_term_blank']
      else:
        results = [{
          'uuid': '248959df-3079-4947-b847-9e0892d1bab4',
          'handle':  'Andrew Brown',
          'message': 'Cloud is fun!',
          'created_at': now.isoformat()
        }]
        model['data'] = results
      return model