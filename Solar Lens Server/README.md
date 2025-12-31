# Solar Lens - Custom Image Upload Server

Azure Functions-based image upload service for Solar Lens tvOS app. Allows users to upload custom logos and backgrounds by scanning a QR code.

## Architecture

```
┌─────────────────┐         ┌──────────────────┐         ┌─────────────────┐
│  tvOS App       │◄────────┤  Azure Functions ├────────►│  Azure Blob     │
│  (Receiver)     │         │  + Static Web    │         │  Storage        │
└─────────────────┘         └──────────────────┘         └─────────────────┘
        │                            │
        │                            │
        └────────────────────────────┘
              QR Code Scanning
```

**Flow:**
1. tvOS generates unique device ID → shows QR code
2. User scans QR code → opens web upload page
3. User selects and uploads image → Azure Functions stores in Blob Storage
4. tvOS polls Azure Functions → downloads image
5. Azure Functions deletes image after successful download
6. tvOS saves image locally

## Prerequisites

- [.NET 10 SDK](https://dotnet.microsoft.com/download)
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
- [Azure Functions Core Tools v4](https://docs.microsoft.com/en-us/azure/azure-functions/functions-run-local)
- Azure Subscription (free tier works)
- [Azurite](https://docs.microsoft.com/en-us/azure/storage/common/storage-use-azurite) for local development (optional)

## Local Development Setup

### 1. Install Azure Storage Emulator (Azurite)

```bash
npm install -g azurite
```

### 2. Start Azurite

```bash
azurite --silent --location ./azurite --debug ./azurite/debug.log
```

Or use Docker:

```bash
docker run -p 10000:10000 -p 10001:10001 -p 10002:10002 mcr.microsoft.com/azure-storage/azurite
```

### 3. Restore Dependencies

```bash
cd "Solar Lens Server/src/ImageUpload.Functions"
dotnet restore
```

### 4. Run Functions Locally

```bash
cd "Solar Lens Server/src/ImageUpload.Functions"
func start
```

The Functions will be available at `http://localhost:7071/api`

### 5. Serve Web App Locally

For local testing, use any static web server:

```bash
cd "Solar Lens Server/web"
python3 -m http.server 8000
```

Or use npm:

```bash
npx http-server -p 8000
```

The web app will be available at `http://localhost:8000`

### 6. Test Locally

1. Open web app: `http://localhost:8000?device=12345678-1234-1234-1234-123456789abc`
2. Upload an image
3. Check blob storage using Azure Storage Explorer or Azurite

## Azure Deployment

### Step 1: Login to Azure

```bash
az login
az account set --subscription "YOUR_SUBSCRIPTION_NAME_OR_ID"
```

### Step 2: Create Resource Group

```bash
az group create \
  --name rg-solarlens-upload \
  --location westeurope
```

You can use a different location. Check available locations:
```bash
az account list-locations -o table
```

### Step 3: Create Storage Account

```bash
az storage account create \
  --name stsolarlensupload \
  --resource-group rg-solarlens-upload \
  --location westeurope \
  --sku Standard_LRS \
  --kind StorageV2 \
  --access-tier Hot
```

**Note:** Storage account names must be globally unique, lowercase, 3-24 characters. If `stsolarlensupload` is taken, try `stsolarlens[yourname]` or `stsolarlens[random]`.

### Step 4: Create Blob Container

```bash
az storage container create \
  --name uploaded-images \
  --account-name stsolarlensupload \
  --auth-mode login \
  --public-access off
```

### Step 5: Create Function App

```bash
az functionapp create \
  --name solarlens-upload-func \
  --resource-group rg-solarlens-upload \
  --storage-account stsolarlensupload \
  --consumption-plan-location westeurope \
  --runtime dotnet-isolated \
  --runtime-version 10 \
  --functions-version 4 \
  --os-type Linux
```

**Note:** Function app names must be globally unique. If taken, try `solarlens-upload-[yourname]` or `solarlens-upload-[random]`.

### Step 6: Configure Function App Settings

Get the storage connection string:

```bash
STORAGE_CONNECTION=$(az storage account show-connection-string \
  --name stsolarlensupload \
  --resource-group rg-solarlens-upload \
  --output tsv)
```

Configure Function App:

```bash
az functionapp config appsettings set \
  --name solarlens-upload-func \
  --resource-group rg-solarlens-upload \
  --settings \
    "BlobStorageConnectionString=$STORAGE_CONNECTION" \
    "BlobContainerName=uploaded-images" \
    "MaxFileSizeBytes=5242880" \
    "AllowedOrigins=*" \
    "RateLimitRequestsPerMinute=10"
```

### Step 7: Enable CORS

```bash
az functionapp cors add \
  --name solarlens-upload-func \
  --resource-group rg-solarlens-upload \
  --allowed-origins "*"
```

For production, replace `*` with your Static Web App URL.

### Step 8: Deploy Functions

From the project directory:

```bash
cd "Solar Lens Server/src/ImageUpload.Functions"
func azure functionapp publish solarlens-upload-func
```

Or using dotnet:

```bash
dotnet publish --configuration Release --output ./publish
cd publish
zip -r ../deploy.zip .
cd ..
az functionapp deployment source config-zip \
  --name solarlens-upload-func \
  --resource-group rg-solarlens-upload \
  --src deploy.zip
```

### Step 9: Create Static Web App

#### Option A: Using Azure Portal

1. Go to [Azure Portal](https://portal.azure.com)
2. Create new **Static Web App** resource
3. Resource Group: `rg-solarlens-upload`
4. Name: `solarlens-upload-web`
5. Region: West Europe
6. Deployment: Manual
7. Note the auto-generated URL

#### Option B: Using Azure CLI

```bash
az staticwebapp create \
  --name solarlens-upload-web \
  --resource-group rg-solarlens-upload \
  --location westeurope \
  --sku Free
```

### Step 10: Deploy Web App

Get deployment token:

```bash
DEPLOY_TOKEN=$(az staticwebapp secrets list \
  --name solarlens-upload-web \
  --resource-group rg-solarlens-upload \
  --query properties.apiKey -o tsv)
```

Deploy using Static Web Apps CLI:

```bash
cd "Solar Lens Server/web"

# Update API_BASE_URL in app.js first!
# Replace YOUR-FUNCTION-APP with your actual function app name

npm install -g @azure/static-web-apps-cli

swa deploy \
  --deployment-token "$DEPLOY_TOKEN" \
  --app-location . \
  --output-location .
```

### Step 11: Get URLs

Get your Function App URL:

```bash
echo "Function App URL: https://$(az functionapp show \
  --name solarlens-upload-func \
  --resource-group rg-solarlens-upload \
  --query defaultHostName -o tsv)"
```

Get your Static Web App URL:

```bash
az staticwebapp show \
  --name solarlens-upload-web \
  --resource-group rg-solarlens-upload \
  --query defaultHostname -o tsv
```

### Step 12: Update Configuration

#### Update Web App (`web/app.js`)

Replace the API_BASE_URL:

```javascript
API_BASE_URL: window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1'
    ? 'http://localhost:7071/api'
    : 'https://YOUR-FUNCTION-APP.azurewebsites.net/api',  // UPDATE THIS
```

#### Update tvOS App (`Solar Lens BigScreen/Services/ImageUploadClient.swift`)

Update the production URL:

```swift
#if DEBUG
static let baseURL = "http://localhost:7071/api"
static let webAppURL = "http://localhost:8000"
#else
static let baseURL = "https://YOUR-FUNCTION-APP.azurewebsites.net/api"  // UPDATE THIS
static let webAppURL = "https://YOUR-STATIC-WEB-APP.azurestaticapps.net"  // UPDATE THIS
#endif
```

Redeploy web app after updating the URL.

## Testing Deployment

### Test Upload Endpoint

```bash
DEVICE_ID=$(uuidgen)
echo "Device ID: $DEVICE_ID"

# Create a small test image (1x1 red pixel PNG in base64)
TEST_IMAGE="iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8DwHwAFBQIAX8jx0gAAAABJRU5ErkJggg=="

# Upload
curl -X POST https://YOUR-FUNCTION-APP.azurewebsites.net/api/upload \
  -H "Content-Type: application/json" \
  -d "{\"deviceId\":\"$DEVICE_ID\",\"imageType\":\"logo\",\"imageData\":\"$TEST_IMAGE\",\"format\":\"png\"}"
```

### Test Check Endpoint

```bash
curl https://YOUR-FUNCTION-APP.azurewebsites.net/api/check/$DEVICE_ID
```

Expected response:
```json
{"available":true,"imageType":"logo","format":"png"}
```

### Test Download Endpoint

```bash
curl https://YOUR-FUNCTION-APP.azurewebsites.net/api/download/$DEVICE_ID \
  --output test-download.png
```

### Test Web App

Open: `https://YOUR-STATIC-WEB-APP.azurestaticapps.net?device=12345678-1234-1234-1234-123456789abc`

## Security Considerations

### 1. Rate Limiting

The service implements rate limiting:
- Default: 10 requests per minute per IP
- Configurable via `RateLimitRequestsPerMinute` app setting

To adjust:

```bash
az functionapp config appsettings set \
  --name solarlens-upload-func \
  --resource-group rg-solarlens-upload \
  --settings "RateLimitRequestsPerMinute=20"
```

### 2. File Size Limits

- Default: 5MB max
- Configurable via `MaxFileSizeBytes` app setting

### 3. CORS Configuration

For production, restrict CORS to your Static Web App only:

```bash
az functionapp cors remove \
  --name solarlens-upload-func \
  --resource-group rg-solarlens-upload \
  --allowed-origins "*"

az functionapp cors add \
  --name solarlens-upload-func \
  --resource-group rg-solarlens-upload \
  --allowed-origins "https://YOUR-STATIC-WEB-APP.azurestaticapps.net"
```

### 4. Automatic Cleanup

Add a timer-triggered function to clean up old images:

Create `Functions/CleanupFunction.cs`:

```csharp
[Function("Cleanup")]
public async Task Run([TimerTrigger("0 0 */6 * * *")] TimerInfo timer)
{
    // Runs every 6 hours
    await _blobStorage.CleanupExpiredImagesAsync(TimeSpan.FromHours(24));
}
```

### 5. Budget Alerts

Set up budget alerts to prevent unexpected costs:

```bash
az consumption budget create \
  --resource-group rg-solarlens-upload \
  --budget-name solarlens-monthly-budget \
  --amount 5 \
  --time-grain Monthly \
  --start-date "2024-01-01" \
  --end-date "2025-12-31"
```

### 6. Device ID Validation

The service validates that device IDs are valid UUIDs to prevent injection attacks.

### 7. Content Type Validation

Only PNG and JPEG images are accepted. The service validates:
- File MIME type
- File extension
- Base64 encoding

## Cost Estimation

### Free Tier Limits

**Azure Functions (Consumption Plan):**
- First 1,000,000 executions: Free
- First 400,000 GB-s compute: Free

**Azure Blob Storage:**
- First 5GB: ~$0.10/month
- Operations: $0.0004 per 10,000 operations

**Azure Static Web Apps:**
- Free tier: 100GB bandwidth/month
- No cost for hosting

### Estimated Monthly Cost (Light Usage)

Assuming:
- 100 uploads per month
- Average image size: 2MB
- Each upload: 3 function calls (upload, check, download)

**Total: ~$0.10 - $0.50/month**

Most users will stay within the free tier.

### Cost Optimization Tips

1. **Enable automatic cleanup** to delete old images
2. **Use Standard_LRS storage** (locally redundant, cheapest)
3. **Monitor function execution** times - keep them fast
4. **Set budget alerts** as shown above

## Monitoring

### View Function Logs

```bash
az monitor app-insights component show \
  --app solarlens-upload-func \
  --resource-group rg-solarlens-upload
```

Or view in Azure Portal:
1. Go to Function App
2. Click "Application Insights"
3. View logs, metrics, and failures

### Monitor Storage Usage

```bash
az storage account show-usage \
  --account-name stsolarlensupload \
  --resource-group rg-solarlens-upload
```

### Check Function Status

```bash
az functionapp show \
  --name solarlens-upload-func \
  --resource-group rg-solarlens-upload \
  --query state
```

## Troubleshooting

### Issue: Function returns 500 error

**Check logs:**

```bash
func azure functionapp logstream solarlens-upload-func
```

**Common causes:**
- Missing app settings (BlobStorageConnectionString)
- Blob container doesn't exist
- Storage account connection string incorrect

### Issue: CORS error in web app

**Solution:** Add your Static Web App URL to CORS:

```bash
az functionapp cors add \
  --name solarlens-upload-func \
  --resource-group rg-solarlens-upload \
  --allowed-origins "https://YOUR-STATIC-WEB-APP.azurestaticapps.net"
```

### Issue: Rate limiting too strict

**Increase limit:**

```bash
az functionapp config appsettings set \
  --name solarlens-upload-func \
  --resource-group rg-solarlens-upload \
  --settings "RateLimitRequestsPerMinute=20"
```

### Issue: Deployment fails

**Check .NET version:**

```bash
dotnet --version  # Should be 10.x
```

**Rebuild and retry:**

```bash
dotnet clean
dotnet build --configuration Release
func azure functionapp publish solarlens-upload-func
```

## Cleanup (Delete All Resources)

To delete all Azure resources:

```bash
az group delete \
  --name rg-solarlens-upload \
  --yes \
  --no-wait
```

## API Documentation

### POST /api/upload

Upload an image for a device.

**Request:**
```json
{
  "deviceId": "uuid-string",
  "imageType": "logo" | "background",
  "imageData": "base64-encoded-image",
  "format": "png" | "jpeg"
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "message": "Image uploaded successfully",
  "deviceId": "uuid-string",
  "imageType": "logo"
}
```

**Error Responses:**
- `400 Bad Request`: Invalid input
- `429 Too Many Requests`: Rate limit exceeded
- `500 Internal Server Error`: Server error

### GET /api/check/{deviceId}

Check if an image is available for a device.

**Response (200 OK):**
```json
{
  "available": true,
  "imageType": "logo",
  "format": "png"
}
```

### GET /api/download/{deviceId}

Download and delete the image for a device.

**Response (200 OK):**
- Content-Type: `image/png` or `image/jpeg`
- Body: Image binary data
- Image is automatically deleted after download

**Error Responses:**
- `404 Not Found`: No image for this device
- `429 Too Many Requests`: Rate limit exceeded

## Development Tips

### Using JetBrains Rider

A run configuration is provided at `.run/ImageUpload.Functions.run.xml`. Open the project in Rider and run/debug using this configuration.

### Using Visual Studio Code

Install the Azure Functions extension and use F5 to run/debug.

### Environment Variables

Create a `local.settings.json` file (already exists) with your settings:

```json
{
  "IsEncrypted": false,
  "Values": {
    "AzureWebJobsStorage": "UseDevelopmentStorage=true",
    "FUNCTIONS_WORKER_RUNTIME": "dotnet-isolated",
    "BlobStorageConnectionString": "UseDevelopmentStorage=true",
    "BlobContainerName": "uploaded-images",
    "MaxFileSizeBytes": "5242880",
    "AllowedOrigins": "*",
    "RateLimitRequestsPerMinute": "10"
  }
}
```

## License

Part of Solar Lens project. See main repository for license.

## Support

For issues and questions, please open an issue in the main Solar Lens repository.
