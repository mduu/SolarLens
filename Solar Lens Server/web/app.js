// Configuration
const CONFIG = {
    // Update this URL to your deployed Azure Functions URL
    API_BASE_URL: window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1'
        ? 'http://localhost:7071/api'
        : 'https://solarlens-upload-func.azurewebsites.net/api',

    MAX_FILE_SIZE: {
        logo: 2 * 1024 * 1024, // 2MB
        background: 8 * 1024 * 1024 // 8MB
    },

    MAX_DIMENSIONS: {
        logo: {width: 512, height: 512},
        background: {width: 3840, height: 2160}
    }
};

// DOM Elements
const elements = {
    errorContainer: document.getElementById('errorContainer'),
    errorMessage: document.getElementById('errorMessage'),
    headerLogo: document.getElementById('headerLogo'),
    headerBackground: document.getElementById('headerBackground'),
    deviceInfo: document.getElementById('deviceInfo'),
    deviceIdDisplay: document.getElementById('deviceIdDisplay'),
    fileInput: document.getElementById('fileInput'),
    fileInputText: document.getElementById('fileInputText'),
    imagePreview: document.getElementById('imagePreview'),
    previewImage: document.getElementById('previewImage'),
    fileName: document.getElementById('fileName'),
    fileSize: document.getElementById('fileSize'),
    uploadButton: document.getElementById('uploadButton'),
    uploadButtonText: document.getElementById('uploadButtonText'),
    uploadSpinner: document.getElementById('uploadSpinner'),
    progressContainer: document.getElementById('progressContainer'),
    progressFill: document.getElementById('progressFill'),
    progressText: document.getElementById('progressText'),
    successContainer: document.getElementById('successContainer'),
    uploadContainer: document.getElementById('uploadContainer'),
    imageInfoLogo: document.getElementById('imageInfoLogo'),
    imageInfoBackground: document.getElementById('imageInfoBackground'),
};

// State
let state = {
    deviceId: null,
    selectedFile: null,
    selectedImageType: 'logo'
};

// Initialize
document.addEventListener('DOMContentLoaded', () => {
    // Get device ID from URL
    const urlParams = new URLSearchParams(window.location.search);
    state.deviceId = urlParams.get('device');
    state.selectedImageType = urlParams.get('imageType');

    if (!state.deviceId) {
        showError('Invalid URL: No device ID provided. Please scan the QR code from your Apple TV.');
        elements.uploadContainer.classList.add('hidden');
        return;
    }

    // Validate device ID format (UUID)
    if (!isValidUUID(state.deviceId)) {
        showError('Invalid device ID format. Please scan the QR code from your Apple TV again.');
        elements.uploadContainer.classList.add('hidden');
        return;
    }

    if (!state.selectedImageType) {
        showError('Invalid URL: No image-type provided. Please scan the QR code from your Apple TV.');
        elements.uploadContainer.classList.add('hidden');
        return;
    }

    // Show device info
    elements.deviceIdDisplay.textContent = state.deviceId;
    elements.deviceInfo.classList.remove('hidden');

    if (state.selectedImageType === 'logo') {
        elements.headerLogo.classList.remove('hidden');
        elements.imageInfoLogo.classList.remove('hidden');
    } else {
        elements.headerBackground.classList.remove('hidden');
        elements.imageInfoBackground.classList.remove('hidden');
    }

    // Setup event listeners
    setupEventListeners();
});

function setupEventListeners() {
    // File input change
    elements.fileInput.addEventListener('change', handleFileSelect);

    // Upload button
    elements.uploadButton.addEventListener('click', handleUpload);
}

async function handleFileSelect(event) {
    const file = event.target.files[0];

    if (!file) {
        return;
    }

    // Validate file type
    if (!file.type.match(/image\/(png|jpeg)/)) {
        showError('Invalid file type. Please select a PNG or JPEG image.');
        elements.fileInput.value = '';
        return;
    }

    // Validate file size
    const maxSize = CONFIG.MAX_FILE_SIZE[state.selectedImageType];
    if (file.size > maxSize) {
        showError(`File too large. Maximum size for ${state.selectedImageType} is ${formatFileSize(maxSize)}.`);
        elements.fileInput.value = '';
        return;
    }

    // Validate image dimensions
    try {
        const dimensions = await getImageDimensions(file);
        const maxDims = CONFIG.MAX_DIMENSIONS[state.selectedImageType];

        if (dimensions.width > maxDims.width || dimensions.height > maxDims.height) {
            showError(`Image dimensions too large. Maximum for ${state.selectedImageType} is ${maxDims.width}x${maxDims.height}px.`);
            elements.fileInput.value = '';
            return;
        }

        // All validations passed
        state.selectedFile = file;
        showPreview(file, dimensions);
        elements.uploadButton.disabled = false;
        hideError();

    } catch (error) {
        showError('Failed to read image file. Please try another image.');
        elements.fileInput.value = '';
    }
}

async function handleUpload() {
    if (!state.selectedFile || !state.deviceId) {
        return;
    }

    // Disable upload button
    elements.uploadButton.disabled = true;
    elements.uploadButtonText.textContent = 'Uploading...';
    elements.uploadSpinner.classList.remove('hidden');
    elements.progressContainer.classList.remove('hidden');

    try {
        // Read file as base64
        const base64Data = await fileToBase64(state.selectedFile);

        // Determine format
        const format = state.selectedFile.type === 'image/png' ? 'png' : 'jpeg';

        // Prepare upload request
        const uploadData = {
            deviceId: state.deviceId,
            imageType: state.selectedImageType,
            imageData: base64Data.split(',')[1], // Remove data:image/...;base64, prefix
            format: format
        };

        // Upload to Azure Functions
        const response = await fetch(`${CONFIG.API_BASE_URL}/upload`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(uploadData)
        });

        if (!response.ok) {
            const errorText = await response.text();
            throw new Error(errorText || `Upload failed with status ${response.status}`);
        }

        // Success!
        elements.progressFill.style.width = '100%';
        elements.progressText.textContent = 'Upload complete!';

        // Show success screen
        setTimeout(() => {
            elements.uploadContainer.classList.add('hidden');
            elements.successContainer.classList.remove('hidden');
        }, 500);

    } catch (error) {
        console.error('Upload error:', error);
        showError(`Upload failed: ${error.message}`);

        // Re-enable upload button
        elements.uploadButton.disabled = false;
        elements.uploadButtonText.textContent = 'Upload Image';
        elements.uploadSpinner.classList.add('hidden');
        elements.progressContainer.classList.add('hidden');
    }
}

// Helper Functions

function isValidUUID(uuid) {
    const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
    return uuidRegex.test(uuid);
}

function getImageDimensions(file) {
    return new Promise((resolve, reject) => {
        const img = new Image();
        const url = URL.createObjectURL(file);

        img.onload = () => {
            URL.revokeObjectURL(url);
            resolve({
                width: img.width,
                height: img.height
            });
        };

        img.onerror = () => {
            URL.revokeObjectURL(url);
            reject(new Error('Failed to load image'));
        };

        img.src = url;
    });
}

function fileToBase64(file) {
    return new Promise((resolve, reject) => {
        const reader = new FileReader();
        reader.onload = () => resolve(reader.result);
        reader.onerror = reject;
        reader.readAsDataURL(file);
    });
}

function showPreview(file, dimensions) {
    const url = URL.createObjectURL(file);
    elements.previewImage.src = url;
    elements.fileName.textContent = file.name;
    elements.fileSize.textContent = `${formatFileSize(file.size)} • ${dimensions.width}x${dimensions.height}px`;
    elements.imagePreview.classList.remove('hidden');
    elements.fileInputText.textContent = 'Tap to change image';
}

function formatFileSize(bytes) {
    if (bytes < 1024) return bytes + ' B';
    if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(1) + ' KB';
    return (bytes / (1024 * 1024)).toFixed(1) + ' MB';
}

function showError(message) {
    elements.errorMessage.textContent = message;
    elements.errorContainer.classList.remove('hidden');
}

function hideError() {
    elements.errorContainer.classList.add('hidden');
}
