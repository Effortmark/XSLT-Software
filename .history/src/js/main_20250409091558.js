// Load XSLT template
let xsltProcessor = null;

async function loadXsltTemplate() {
  try {
    const response = await fetch('/static/pptx.xsl');
    const xsltText = await response.text();
    const parser = new DOMParser();
    const xsltDoc = parser.parseFromString(xsltText, 'text/xml');
    
    xsltProcessor = new XSLTProcessor();
    xsltProcessor.importStylesheet(xsltDoc);
  } catch (error) {
    console.error('Error loading XSLT template:', error);
    showError('Failed to load XSLT template');
  }
}

// Handle file upload
async function handleFileUpload(event) {
  event.preventDefault();
  const fileInput = document.getElementById('pptx-file');
  const file = fileInput.files[0];
  
  if (!file) {
    showError('Please select a file');
    return;
  }
  
  try {
    showLoading(true);
    const reader = new FileReader();
    
    reader.onload = async function(e) {
      try {
        const base64Data = e.target.result.split(',')[1];
        
        // Send file to serverless function
        const response = await fetch('/.netlify/functions/process-pptx', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            filename: file.name,
            data: base64Data
          })
        });
        
        if (!response.ok) {
          const error = await response.json();
          throw new Error(error.message || 'Failed to process file');
        }
        
        const xmlText = await response.text();
        const parser = new DOMParser();
        const xmlDoc = parser.parseFromString(xmlText, 'text/xml');
        
        // Transform XML using XSLT
        if (!xsltProcessor) {
          await loadXsltTemplate();
        }
        
        const resultDocument = xsltProcessor.transformToDocument(xmlDoc);
        const serializer = new XMLSerializer();
        const resultHtml = serializer.serializeToString(resultDocument);
        
        // Display results
        document.getElementById('results').innerHTML = resultHtml;
        showResults(true);
        
      } catch (error) {
        console.error('Error processing file:', error);
        showError(error.message);
      } finally {
        showLoading(false);
      }
    };
    
    reader.readAsDataURL(file);
    
  } catch (error) {
    console.error('Error reading file:', error);
    showError('Failed to read file');
    showLoading(false);
  }
}

// UI helper functions
function showLoading(show) {
  document.getElementById('loading').style.display = show ? 'block' : 'none';
  document.getElementById('upload-form').style.display = show ? 'none' : 'block';
}

function showResults(show) {
  document.getElementById('results').style.display = show ? 'block' : 'none';
  document.getElementById('upload-form').style.display = show ? 'none' : 'block';
}

function showError(message) {
  const errorElement = document.getElementById('error');
  errorElement.textContent = message;
  errorElement.style.display = 'block';
  setTimeout(() => {
    errorElement.style.display = 'none';
  }, 5000);
}

// Initialize
document.addEventListener('DOMContentLoaded', () => {
  loadXsltTemplate();
  document.getElementById('upload-form').addEventListener('submit', handleFileUpload);
});

