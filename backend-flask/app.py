from flask import Flask
from flask import request
from flask_cors import CORS, cross_origin
import os

# from lib.cognito_jwt_token import CognitoJwtToken, extract_access_token, TokenVerifyError

# HoneyComb =======================================================================
from opentelemetry import trace
from opentelemetry.instrumentation.flask import FlaskInstrumentor
from opentelemetry.instrumentation.requests import RequestsInstrumentor
from opentelemetry.exporter.otlp.proto.http.trace_exporter import OTLPSpanExporter
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor

# XRay ============================================================================
from aws_xray_sdk.core import xray_recorder
from aws_xray_sdk.ext.flask.middleware import XRayMiddleware

# Watchtower ======================================================================
# import watchtower
# import logging
# from time import strftime

# Configuring Logger to Use CloudWatch
# LOGGER = logging.getLogger(__name__)
# LOGGER.setLevel(logging.DEBUG)
# console_handler = logging.StreamHandler()
# cw_handler = watchtower.CloudWatchLogHandler(log_group='cruddur')
# LOGGER.addHandler(console_handler)
# LOGGER.addHandler(cw_handler)
# LOGGER.info("some message")

# Rollbar =========================================================================
import rollbar
import rollbar.contrib.flask
from flask import got_request_exception

from services.home_activities import *
from services.notifications_activities import *
from services.user_activities import *
from services.create_activity import *
from services.create_reply import *
from services.search_activities import *
from services.message_groups import *
from services.messages import *
from services.create_message import *
from services.show_activity import *
from services.users_short import *

# HoneyComb =======================================================================
# Initialize tracing and an exporter that can send data to Honeycomb
provider = TracerProvider()
processor = BatchSpanProcessor(OTLPSpanExporter())
provider.add_span_processor(processor)
trace.set_tracer_provider(provider)
tracer = trace.get_tracer(__name__)

# XRay ============================================================================
xray_url = os.getenv("AWS_XRAY_URL")
xray_recorder.configure(service="cruddur-backend-flask", dynamic_naming=xray_url)

app = Flask(__name__)

# AWS Cognito =====================================================================
# cognito_jwt_token = CognitoJwtToken(
#   user_pool_id=os.getenv("AWS_COGNITO_USER_POOL_ID"),
#   user_pool_client_id=os.getenv("AWS_COGNITO_USER_POOL_CLIENT_ID"),
#   region=os.getenv("AWS_DEFAULT_REGION")
# )

# HoneyComb =======================================================================
# Initialize automatic instrumentation with Flask
FlaskInstrumentor().instrument_app(app)
RequestsInstrumentor().instrument()

# XRay ============================================================================
XRayMiddleware(app, xray_recorder)

# Rollbar =========================================================================
rollbar_access_token = os.getenv("ROLLBAR_ACCESS_TOKEN")
rollbar.init(
    # access token
    rollbar_access_token,
    # environment name
    "production",
    # server root directory, makes tracebacks prettier
    root=os.path.dirname(os.path.realpath(__file__)),
    # flask already sets up logging
    allow_logging_basic_config=False,
)
# send exceptions from `app` to rollbar, using flask's signal system.
got_request_exception.connect(rollbar.contrib.flask.report_exception, app)

frontend = os.getenv("FRONTEND_URL")
backend = os.getenv("BACKEND_URL")
origins = [frontend, backend]
cors = CORS(
    app,
    resources={r"/api/*": {"origins": origins}},
    expose_headers=["location", "link", "Authorization"],
    allow_headers=["Content-Type", "if-modified-since", "traceparent", "Authorization"],
    methods="OPTIONS,GET,HEAD,POST",
)

# @app.after_request
# def after_request(response):
#     timestamp = strftime('[%Y-%b-%d %H:%M]')
#     LOGGER.error('%s %s %s %s %s %s', timestamp, request.remote_addr, request.method, request.scheme, request.full_path, response.status)
#     return response


@app.route("/api/health-check")
def health_check():
    return {"status": "ok"}, 200


@app.route("/api/message_groups", methods=["GET"])
def data_message_groups():
    cognito_username = request.headers.get("X-Cognito-Username", None)
    if cognito_username is not None:
        # authenicatied request
        app.logger.debug(f"data_message_groups: authenticated request for user={cognito_username}")
        model = MessageGroups.run(cognito_user_id=cognito_username)
        if model["errors"] is not None:
            return model["errors"], 422
        else:
            return model["data"], 200
    else:
        # unauthenicatied request
        return {}, 401


@app.route("/api/messages/<string:message_group_uuid>", methods=["GET"])
def data_messages(message_group_uuid):
    cognito_username = request.headers.get("X-Cognito-Username", None)
    if cognito_username is not None:
        # authenicatied request
        app.logger.debug(f"data_messages: authenticated request for user={cognito_username}")
        model = Messages.run(cognito_user_id=cognito_username, message_group_uuid=message_group_uuid)
        if model["errors"] is not None:
            return model["errors"], 422
        else:
            return model["data"], 200
    else:
        # unauthenicatied request
        return {}, 401


@app.route("/api/messages", methods=["POST", "OPTIONS"])
@cross_origin()
def data_create_message():
    cognito_username = request.headers.get("X-Cognito-Username", None)
    message = request.json["message"]
    user_receiver_handle = request.json.get("handle", None)
    message_group_uuid = request.json.get("message_group_uuid", None)
    if cognito_username is not None:
        # authenicatied request
        app.logger.debug(f"data_create_message: authenticated request for user={cognito_username}")

        if message_group_uuid is None:
            # Create for the first time
            model = CreateMessage.run(
                mode="create",
                message=message,
                cognito_user_id=cognito_username,
                user_receiver_handle=user_receiver_handle,
            )
        else:
            # Push onto existing Message Group
            model = CreateMessage.run(
                mode="update",
                message=message,
                cognito_user_id=cognito_username,
                message_group_uuid=message_group_uuid,
            )

        if model["errors"] is not None:
            return model["errors"], 422
        else:
            return model["data"], 200
    else:
        # unauthenicatied request
        return {}, 401


@app.route("/api/activities/home", methods=["GET"])
def data_home():
    # app.logger.debug(request.headers)
    cognito_username = request.headers.get("X-Cognito-Username", None)
    if cognito_username is not None:
        # authenicatied request
        app.logger.debug(f"data_home: authenticated request for user={cognito_username}")
        data = HomeActivities.run(cognito_user_id=cognito_username)
    else:
        # unauthenicatied request
        data = HomeActivities.run()
    return data, 200


@app.route("/api/activities/notifications", methods=["GET"])
def data_notifications():
    data = NotificationsActivities.run()
    return data, 200


@app.route("/api/activities/@<string:handle>", methods=["GET"])
def data_handle(handle):
    model = UserActivities.run(handle)
    if model["errors"] is not None:
        return model["errors"], 422
    else:
        return model["data"], 200


@app.route("/api/activities/search", methods=["GET"])
def data_search():
    term = request.args.get("term")
    model = SearchActivities.run(term)
    if model["errors"] is not None:
        return model["errors"], 422
    else:
        return model["data"], 200
    return


@app.route("/api/activities", methods=["POST", "OPTIONS"])
@cross_origin()
def data_activities():
    request.headers.get("X-Cognito-Username", None)
    user_handle = request.json["handle"]
    message = request.json["message"]
    ttl = request.json["ttl"]
    model = CreateActivity.run(message, user_handle, ttl)
    if model["errors"] is not None:
        return model["errors"], 422
    else:
        return model["data"], 200
    return


@app.route("/api/activities/<string:activity_uuid>", methods=["GET"])
def data_show_activity(activity_uuid):
    data = ShowActivity.run(activity_uuid=activity_uuid)
    return data, 200


@app.route("/api/activities/<string:activity_uuid>/reply", methods=["POST", "OPTIONS"])
@cross_origin()
def data_activities_reply(activity_uuid):
    user_handle = "andrewbrown"
    message = request.json["message"]
    model = CreateReply.run(message, user_handle, activity_uuid)
    if model["errors"] is not None:
        return model["errors"], 422
    else:
        return model["data"], 200
    return


@app.route("/api/users/@<string:handle>/short", methods=["GET"])
def data_users_short(handle):
    data = UsersShort.run(handle)
    return data, 200


if __name__ == "__main__":
    app.run(debug=True)
