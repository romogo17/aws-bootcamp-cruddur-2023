from lib.ddb import Ddb
from lib.db import db

from flask import current_app as app
from opentelemetry import trace

tracer = trace.get_tracer("messages")


class Messages:
    def run(message_group_uuid, cognito_user_id):
        with tracer.start_as_current_span("messages-run"):
            model = {"errors": None, "data": None}

            sql = db.template("users", "uuid_from_cognito_user_id")
            my_user_uuid = db.query_value(sql, {"cognito_user_id": cognito_user_id})

            app.logger.info(f"UUID: {my_user_uuid}")

            ddb = Ddb.client()
            data = Ddb.list_messages(ddb, message_group_uuid)
            app.logger.info(f"list_messages: {data}")

            model["data"] = data
            return model
