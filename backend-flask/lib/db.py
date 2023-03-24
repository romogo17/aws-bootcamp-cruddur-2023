import os
import re
import sys
from psycopg_pool import ConnectionPool
from flask import current_app as app


class Db:
    def __init__(self):
        self.init_pool()

    def template(self, *args):
        pathing = list(
            (
                app.root_path,
                "db",
                "sql",
            )
            + args
        )
        pathing[-1] = pathing[-1] + ".sql"

        template_path = os.path.join(*pathing)

        green = "\033[92m"
        no_color = "\033[0m"

        with open(template_path, "r") as f:
            template_content = f.read()
            app.logger.info(f"{green}Load SQL Template: {template_path}{no_color}")
        return template_content

    def init_pool(self):
        connection_url = os.getenv("CONNECTION_URL")
        self.pool = ConnectionPool(connection_url)

    # we want to commit data such as an insert
    # be sure to check for RETURNING in all uppercases
    def print_params(self, params):
        if len(params) == 0:
            return
        blue = "\033[94m"
        no_color = "\033[0m"
        param_list = [f"{key}: {value}" for key, value in params.items()]
        app.logger.info(params)
        param_msg = "\n".join(param_list)
        app.logger.info(f"{blue}SQL PARAMS---{no_color}\n{param_msg}\n")

    def print_sql(self, title, sql):
        cyan = "\033[96m"
        no_color = "\033[0m"
        app.logger.info(f"{cyan}SQL STATEMENT---[{title}]---{no_color}\n{sql}\n")

    def query_commit(self, sql, params={}):
        self.print_sql("commit with returning", sql)
        self.print_params(params)

        pattern = r"\bRETURNING\b"
        is_returning_id = re.search(pattern, sql)

        try:
            with self.pool.connection() as conn:
                cur = conn.cursor()
                cur.execute(sql, params)
                if is_returning_id:
                    returning_id = cur.fetchone()[0]
                conn.commit()
                if is_returning_id:
                    return returning_id
        except Exception as err:
            self.print_sql_err(err)

    # when we want to return a json object
    def query_array_json(self, sql, params={}):
        self.print_sql("array", sql)
        self.print_params(params)

        wrapped_sql = self.query_wrap_array(sql)
        with self.pool.connection() as conn:
            with conn.cursor() as cur:
                cur.execute(wrapped_sql, params)
                json = cur.fetchone()
                return json[0]

    # when we want to return an array of json objects
    def query_object_json(self, sql, params={}):
        self.print_sql("json", sql)
        self.print_params(params)
        wrapped_sql = self.query_wrap_object(sql)

        with self.pool.connection() as conn:
            with conn.cursor() as cur:
                cur.execute(wrapped_sql, params)
                json = cur.fetchone()
                if json is None:
                    "{}"
                else:
                    return json[0]

    def query_value(self, sql, params={}):
        self.print_sql("value", sql)
        self.print_params(params)
        with self.pool.connection() as conn:
            with conn.cursor() as cur:
                cur.execute(sql, params)
                json = cur.fetchone()
                return json[0]

    def query_wrap_object(self, template):
        sql = f"""
        (SELECT COALESCE(row_to_json(object_row),'{{}}'::json) FROM (
        {template}
        ) object_row);
        """
        return sql

    def query_wrap_array(self, template):
        sql = f"""
        (SELECT COALESCE(array_to_json(array_agg(row_to_json(array_row))),'[]'::json) FROM (
        {template}
        ) array_row);
        """
        return sql

    def print_sql_err(self, err):
        # get details about the exception
        err_type, err_obj, traceback = sys.exc_info()

        # get the line number when exception occured
        line_num = traceback.tb_lineno

        # print the connect() error
        app.logger.error("\npsycopg ERROR:", err, "on line number:", line_num)
        app.logger.error("psycopg traceback:", traceback, "-- type:", err_type)

        # print the pgcode and pgerror exceptions
        app.logger.error("pgerror:", err.pgerror)
        app.logger.error("pgcode:", err.pgcode, "\n")


db = Db()
