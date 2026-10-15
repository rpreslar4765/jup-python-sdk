## **Local Development**
If you want to make changes to the SDK and test it locally:

1. In this project's directory, install the package in editable mode by running:
   ```sh
   pip install -e .
   ```

2. To use this library in another project while making changes to it, install the package from its local path in that project:
   ```sh
   pip install -e /path/to/jup-python-sdk
   ```

   Replace `/path/to/jup-python-sdk` with the absolute or relative path to this project directory.

By installing in editable mode, any changes you make to the SDK will immediately reflect in your tests without needing to reinstall the package.

## Offline CI tests

`poetry run pytest --cov=jup_python_sdk` uses HTTPX mock transports. Tests need no
wallet, private key, network access, or funded account, and never submit a live
transaction. API errors propagate into failed assertions. Live examples remain
in `examples/` and must be run explicitly.

Docker CI targets the concrete Python Alpine image tags 3.18–3.21. The old
`python:3.11-alpineedge` tag is not a supported base image. Compose smoke tests
run each runtime service separately and propagate each exit status.
