import os

import click
from flask import Flask, g
from flask_cors import CORS

from config import config
from routes.api import api_bp


def create_app(env=None):
    app = Flask(__name__)

    if env is None:
        env = os.environ.get("APP_ENV", "default")
    app.config.from_object(config[env])

    CORS(app)

    app.register_blueprint(api_bp)

    @app.teardown_appcontext
    def _close_db(exc):  # noqa: F841
        db = g.pop("db", None)
        if db is not None:
            db.close()

    @app.cli.command("seed")
    @click.option("--schemas-dir", default=None, help="Override the schemas directory path.")
    def seed_command(schemas_dir):
        """Populate the metadata database from schema SQL files."""
        from seed import run_seed
        run_seed(schemas_dir)

    @app.route("/")
    def index():
        return {"message": "TBDSP API — use /api/domains or /api/schemas"}

    return app


if __name__ == "__main__":
    app = create_app()
    port = int(os.environ.get("PORT", 5000))
    app.run(host="0.0.0.0", port=port)
