from flask import Flask, jsonify
from subprocess import check_output, STDOUT, CalledProcessError
from time import gmtime, strftime
import os

def create_app(config=None):
    app = Flask(__name__)

    app.config.update(dict(DEBUG=True))
    app.config.update(config or {})

    @app.route('/')
    def hello():
        msg_header = "<h3>Hello Tree!</h3>"
        msg_date = strftime("%H:%M:%S", gmtime())
        with open('app_version.txt', 'r') as app_ver_file:
          app_ver = app_ver_file.read()
          app_ver = app_ver.strip()
        with open('commit_id.txt', 'r') as commit_id_file:
          commit_id = commit_id_file.read()
          commit_id = commit_id.strip()
        master_msg = "<br/>{0}<br/>version: {1}<br/>commit: {2}<br/>date: {3}".format(msg_header, app_ver, commit_id, msg_date)
        return master_msg

    @app.route('/health')
    @app.route('/public/health')
    def health():
        msg_date = strftime("%Y-%m-%d %H:%M:%S", gmtime())
        with open('app_version.txt', 'r') as app_ver_file:
          app_ver = app_ver_file.read()
          app_ver = app_ver.strip()
        with open('commit_id.txt', 'r') as commit_id_file:
          commit_id = commit_id_file.read()
          commit_id = commit_id.strip()
        return jsonify(
            version=app_ver,
            healthy=True,
            connection_status=True,
            commit=commit_id,
            uptime=msg_date
        )

    @app.route('/onboarding')
    def onboarding():
        return jsonify(
            status="success",
            message="Onboarding service is ready",
            timestamp=strftime("%Y-%m-%d %H:%M:%S", gmtime())
        )

    @app.route('/offboarding')
    def offboarding():
        return jsonify(
            status="success",
            message="Offboarding service is ready",
            timestamp=strftime("%Y-%m-%d %H:%M:%S", gmtime())
        )

    @app.route('/iostat')
    def iostat():
        cmd = ['iostat']
        try:
            result = check_output(cmd, stderr=STDOUT).decode('utf-8')
        except CalledProcessError as e:
            result = e.output.decode('utf-8')
        except FileNotFoundError as e:
            result = 'Command Not Found'
        return result

    return app

if __name__ == "__main__":
    # Use environment variable for port, default to 8080 for non-root environments
    port = int(os.environ.get("PORT", 8080))
    app = create_app()
    app.run(host="0.0.0.0", port=port)
