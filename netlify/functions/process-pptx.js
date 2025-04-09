const JSZip = require('jszip');
const xml2js = require('xml2js');
const mime = require('mime-types');

const ALLOWED_EXTENSIONS = ['pptx'];
const MAX_FILE_SIZE = 50 * 1024 * 1024; // 50MB

const validateFile = (filename, size) => {
  const extension = filename.split('.').pop().toLowerCase();
  if (!ALLOWED_EXTENSIONS.includes(extension)) {
    throw new Error('Invalid file type. Only PPTX files are allowed.');
  }
  if (size > MAX_FILE_SIZE) {
    throw new Error('File too large. Maximum size is 50MB.');
  }
};

const processXmlFile = async (zip, name) => {
  const numbers = name.match(/\d+/) || ['1'];
  const num = numbers[0];
  
  const data = await zip.file(name).async('string');
  // Sanitize XML content
  const sanitizedData = data
    .replace(/<\?xml version="1.0"[^>]+>/, '')
    .replace(/<!DOCTYPE[^>]*>/, '')
    .replace(/<!--.*?-->/gs, '');
    
  return `<file name="${name}" num="${num}">${sanitizedData}</file>`;
};

exports.handler = async (event, context) => {
  try {
    if (event.httpMethod !== 'POST') {
      return {
        statusCode: 405,
        body: JSON.stringify({ error: 'Method not allowed' })
      };
    }

    const { filename, data } = JSON.parse(event.body);
    validateFile(filename, data.length);

    // Process the PPTX file
    const zip = new JSZip();
    await zip.loadAsync(Buffer.from(data, 'base64'));
    
    // Combine XML files
    const xmlParts = ['<?xml version="1.0"?><files>'];
    
    for (const [name, file] of Object.entries(zip.files)) {
      if (!name.endsWith('.xml') && !name.endsWith('.rels')) continue;
      if (name.includes('..') || name.startsWith('/')) {
        throw new Error('Invalid ZIP content - possible path traversal attempt');
      }
      
      if (/ppt\/(slideLayouts|slides|slideMasters)/.test(name)) {
        xmlParts.push(await processXmlFile(zip, name));
      }
    }
    
    xmlParts.push('</files>');
    const xmlCombined = xmlParts.join('\n');

    // Transform XML using client-side XSLT
    // We'll send the combined XML to the client for transformation
    return {
      statusCode: 200,
      headers: {
        'Content-Type': 'application/xml'
      },
      body: xmlCombined
    };

  } catch (error) {
    console.error('Error processing PPTX:', error);
    return {
      statusCode: 500,
      body: JSON.stringify({ error: error.message })
    };
  }
}; 