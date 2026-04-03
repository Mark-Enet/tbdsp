import os

from flask import Flask
from flask_cors import CORS

from config import config
from routes.api import api_bp


def create_app(env=None):
    app = Flask(__name__)

    if env is None:
        env = os.environ.get("FLASK_ENV", "default")
    app.config.from_object(config[env])

    CORS(app)

    app.register_blueprint(api_bp)

    @app.route("/")
    def index():
        return {"message": "TBDSP API — use /api/domains or /api/schemas"}

    return app


if __name__ == "__main__":
    app = create_app()
    port = int(os.environ.get("PORT", 5000))
    app.run(host="0.0.0.0", port=port)
