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

## Wake Scheduler (push notifications for automations)

Second service in this Function App, added by
[story #9](../specs/stories/009-remote-push-for-automations-and-notifications.md)
and [ADR-006](../specs/adrs/006-server-as-push-alarm-clock.md). It is a **dumb
alarm clock**: devices register *when* they want to be woken, and at that moment
the server sends an APNs push. It never learns what an automation does, never
sees Solar Manager credentials, and never calls the Solar Manager API.

```
iOS app ──PUT/DELETE /api/wake──▶ [WakeUpsert/WakeDelete] ──▶ Azure Table "WakeSchedules"
                                                                    ▲
                                              [WakeScheduler, every minute]
                                                selects due rows, enqueues
                                                                    │
                                                                    ▼
                                                     Queue "apns-push" (1 msg = 1 push)
                                                                    │
                                                      [ApnsSender] ──HTTP/2──▶ APNs
```

### Stored per schedule

Device token, environment (sandbox/production), kind (deadline/window), push
kind (alert/silent), next fire time, cadence + end for windows, the notification
category/deep link/fallback text the **device** supplied (already localized on
the device), and a SHA-256 hash of the install secret. Nothing else.

Rows are deleted as soon as they have served their purpose: a deadline after
its push is accepted, a window when it passes `until`.

### API

| Method | Route | Purpose |
|---|---|---|
| `PUT` | `/api/wake/{deviceToken}/{scheduleId}` | Create or update a schedule |
| `DELETE` | `/api/wake/{deviceToken}/{scheduleId}` | Cancel one schedule |
| `DELETE` | `/api/wake/{deviceToken}` | Forget this device (Settings toggle, logout) |
| `GET` | `/api/wake/{deviceToken}` | Re-sync / debugging |

Anonymous like the upload API, rate limited per IP, and additionally guarded by
a per-install secret (`X-Install-Secret` header or `?installSecret=`) that the
app generates once and keeps in its Keychain — otherwise knowing a device token
would be enough to cancel or spam someone else's schedules.

Example:

```bash
curl -X PUT "https://<app>.azurewebsites.net/api/wake/$TOKEN/$SCHEDULE_ID" \
  -H 'Content-Type: application/json' \
  -d '{
    "environment": "sandbox",
    "kind": "deadline",
    "pushKind": "alert",
    "fireAt": "2026-08-29T17:30:00Z",
    "automation": "AutoResetChargingMode",
    "defaultTitle": "Auto-reset Charging Mode",
    "defaultBody": "Reset time reached — applying charging mode…",
    "installSecret": "<per-install secret>"
  }'
```

Server-side clamping: silent-push windows are forced to a cadence of at least
10 minutes and expire after at most 7 days (the app renews them while a run is
active), and a deadline more than 15 minutes in the past is rejected.

### APNs configuration

Token-based auth with a `.p8` key — no certificates, no yearly expiry. Set as
app settings (or Key Vault references):

| Setting | Value |
|---|---|
| `Apns__TeamId` | `UYT5K989XD` |
| `Apns__KeyId` | Key ID of the APNs key (10 chars) |
| `Apns__BundleId` | `com.marcduerst.SolarManagerWatch` |
| `Apns__P8` | The `.p8` file contents, raw PEM or base64 |

```bash
az functionapp config appsettings set \
  --name func-solarlens-upload --resource-group rg-solarlens \
  --settings "Apns__TeamId=UYT5K989XD" "Apns__KeyId=<KEY_ID>" \
             "Apns__BundleId=com.marcduerst.SolarManagerWatch" \
             "Apns__P8=$(base64 -i AuthKey_<KEY_ID>.p8)"
```

The `.p8` can only be downloaded once — keep it in the password manager. The
provider JWT is cached per worker process for ~50 minutes (Apple requires
20–60) and is only re-minted after a rejection once it is old enough, otherwise
APNs answers `TooManyProviderTokenUpdates`.

### Error handling — three classes, one poison queue

| Situation | Handling |
|---|---|
| `410 Unregistered`, `400 BadDeviceToken` | The token is dead: delete **all** schedules of that device, complete the message. No retry. |
| `429`, `5xx`, network | Re-queued by the function itself with a 45 s delay until `fireAt + 10 min`, then dropped with a warning. A late deadline push is worse than none — the device's own fallback notification has already fired. |
| Anything unexpected (bad key, wrong topic, payload bug) | The function throws; after `maxDequeueCount` (5) the runtime parks the message in the **poison queue** `apns-push-poison`. |

The poison queue is a **diagnostic inbox, not a replay source** — by the time
anyone reacts, its messages are stale. `WakeScheduler` therefore logs its depth
once a day at `Warning` (alert on this in Application Insights); inspect the
messages in the Portal storage browser, fix the cause, then purge.

**No batching.** One queue message is one push: a batch containing one dead
token would retry the whole batch and duplicate pushes to the healthy devices.

### Local development

The queue and table clients pin their storage service version so Azurite keeps
working when the SDK moves ahead. If a future SDK bump outruns your Azurite,
either update Azurite or start it with `--skipApiVersionCheck`.

`Microsoft.Azure.Functions.Worker.Extensions.Storage.Queues` is pinned to
**5.5.0** on purpose: 5.5.5 drags `Microsoft.Extensions.*` 10.x into the
generated host-side extension bundle, which the Functions host (shipping 9.x)
cannot load — it refuses to start with *"Could not load file or assembly
'Microsoft.Extensions.Options, Version=10.0.0.0'"*. Test locally before bumping.

```bash
# terminal 1
azurite --silent --location ./azurite --debug ./azurite/debug.log
# terminal 2
cd "Solar Lens Server/src/ImageUpload.Functions"
func start
```

Table `WakeSchedules` and queue `apns-push` are created on first use; the
poison queue is created by the runtime on demand.

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
