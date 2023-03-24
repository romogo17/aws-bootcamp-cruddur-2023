from opentelemetry import trace
from flask import current_app as app

from lib.ddb import Ddb
from lib.db import db

tracer = trace.get_tracer("message.groups")


class MessageGroups:
    def run(cognito_user_id):
        with tracer.start_as_current_span("message-groups-run"):
            model = {"errors": None, "data": None}

            sql = db.template("users", "uuid_from_cognito_user_id")
            my_user_uuid = db.query_value(sql, {"cognito_user_id": cognito_user_id})

            app.logger.info(f"UUID: {my_user_uuid}")

            ddb = Ddb.client()
            data = Ddb.list_message_groups(ddb, my_user_uuid)
            app.logger.info(f"list_message_groups: {data}")

            model["data"] = data
            return model
