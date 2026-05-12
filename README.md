# **Jup Python SDK**

A Python SDK designed for seamless interaction with the Jupiter Ultra API, the simplest and safest way to trade on Solana.<br>
With Ultra API, you don't need to manage or connect to any RPC endpoints, or deal with complex configurations.<br>
Everything from getting quotes to transaction execution happens directly through the API.<br>

Or as we like to say around here:<br>
**"RPCs are for NPCs."**

For a deeper understanding of the Ultra API, including its features and benefits, check out the [Ultra API Docs](https://dev.jup.ag/docs/ultra-api/).

## **Installation**

To install the SDK in your project, run:
```sh
pip install jup-python-sdk
```
## **Quick Start**

Below is a simple example that shows how to fetch and execute an Ultra order with the Jup Python SDK:
```python
from dotenv import load_dotenv
from jup_python_sdk.clients.ultra_api_client import UltraApiClient
from jup_python_sdk.models.ultra_api.ultra_order_request_model import UltraOrderRequest

load_dotenv()
client = UltraApiClient()

order_request = UltraOrderRequest(
   input_mint="So11111111111111111111111111111111111111112",  # WSOL
   output_mint="EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v",  # USDC
   amount=10000000,  # 0.01 WSOL
   taker=client._get_public_key(),
)

try:
   client_response = client.order_and_execute(order_request)
   signature = str(client_response["signature"])

   print("Order and Execute API Response:")
   print(f"  - Status: {client_response.get('status')}")
   if client_response.get("status") == "Failed":
      print(f"  - Code: {client_response.get('code')}")
      print(f"  - Error: {client_response.get('error')}")

   print(f"  - Transaction Signature: {signature}")
   print(f"  - View on Solscan: https://solscan.io/tx/{signature}")

except Exception as e:
   print("Error occurred while processing the swap:", str(e))
finally:
   client.close()
```

You can find additional code examples and advanced usage scenarios in the [examples](./examples) folder.
These examples cover every Ultra API endpoint and should help you get up and running quickly.

## **Setup Instructions**

Before using the SDK, please ensure you have completed the following steps:

1. **Environment Variables**:  
   Set up your required environment variables.  
   Example (base58 string or uint8 array supported):
   ```sh
   # Base58 format
   export PRIVATE_KEY=your_base58_private_key_here

   # OR as a uint8 array (advanced)
   export PRIVATE_KEY=[10,229,131,132,213,96,74,22,...]
   ```
   
> **Note**: `PRIVATE_KEY` can be either a base58-encoded string (default Solana format), or a uint8 array (e.g. `[181,99,240,...]`). The SDK will automatically detect and parse the format.

2. **Optional Configuration**:  
   Depending on your credentials and setup, you have a couple of options for initializing the `UltraApiClient`:

   - **Custom Private Key Environment Variable:**  
     By default, the SDK looks for your private key in an environment variable named `PRIVATE_KEY`.  
     If you use a different environment variable name, you can specify it explicitly:
     ```python
     from jup_python_sdk.clients.ultra_api_client import UltraApiClient

     client = UltraApiClient(private_key_env_var="YOUR_CUSTOM_ENV_VAR")
     ```
     This tells the SDK to read your private key from the environment variable you want.

   - **Using an API Key for Enhanced Access:**
     If you have an API key from [the Jupiter Portal](https://portal.jup.ag/onboard), you can pass it directly when creating the client:
     ```python
     from jup_python_sdk.clients.ultra_api_client import UltraApiClient

     client = UltraApiClient(api_key="YOUR_API_KEY")
     ```
     When you supply an API key, the library will call the `https://api.jup.ag/` API rather than the default `https://lite-api.jup.ag/` API.

## **Docker Support**

The SDK includes comprehensive Docker support with Alpine Linux for lightweight, secure containerized deployments.

### **Supported Alpine Versions**
- Alpine 3.18, 3.19, 3.20, 3.21 (default), and edge

### **Quick Start with Docker**

```bash
# Build the image
docker build -t jup-python-sdk .

# Run with environment file
echo "PRIVATE_KEY=your_base58_private_key_here" > .env
docker run -it --env-file .env jup-python-sdk

# Run an example
docker run --rm --env-file .env jup-python-sdk python examples/balances/main.py
```

### **Using Docker Compose**

```bash
# Build all Alpine versions
docker-compose build

# Test all versions
docker-compose up

# Start development environment
docker-compose up -d jup-sdk-dev
docker-compose exec jup-sdk-dev sh
```

For comprehensive Docker documentation, see [DOCKER.md](./DOCKER.md).

## **Disclaimer**

🚨 **This project is actively worked on.**  
While we don't expect breaking changes as the SDK evolves, we recommend you stay updated with the latest releases.  
Any important updates will be announced in the [Discord server](https://discord.gg/jup).