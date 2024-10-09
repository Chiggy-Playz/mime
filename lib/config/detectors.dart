import 'dart:typed_data';

bool isAnimated(Uint8List bytes) {
  if (bytes.length < 12) return false;

  // Check for PNG (including APNG)
  if (bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47) {
    return _isPNGAnimated(bytes);
  }

  // Check for GIF
  if (bytes[0] == 0x47 && bytes[1] == 0x49 && bytes[2] == 0x46) {
    return _isGIFAnimated(bytes);
  }

  // Check for WebP
  if (bytes[8] == 0x57 && bytes[9] == 0x45 && bytes[10] == 0x42 && bytes[11] == 0x50) {
    return _isWebPAnimated(bytes);
  }

  // MP4, MOV, and other video formats are always considered animated
  if ((bytes[4] == 0x66 && bytes[5] == 0x74 && bytes[6] == 0x79 && bytes[7] == 0x70) || // MP4, MOV, M4V
      (bytes[0] == 0x00 && bytes[1] == 0x00 && bytes[2] == 0x00 && bytes[3] == 0x1C && bytes[4] == 0x66 && bytes[5] == 0x74 && bytes[6] == 0x79 && bytes[7] == 0x70) || // MOV
      (bytes[0] == 0x1A && bytes[1] == 0x45 && bytes[2] == 0xDF && bytes[3] == 0xA3)) { // MKV, WebM
    return true;
  }

  // Check for HEIF/HEIC (which can support animation)
  if (bytes[4] == 0x66 && bytes[5] == 0x74 && bytes[6] == 0x79 && bytes[7] == 0x70 &&
      ((bytes[8] == 0x68 && bytes[9] == 0x65 && bytes[10] == 0x69 && bytes[11] == 0x63) || // HEIC
       (bytes[8] == 0x68 && bytes[9] == 0x65 && bytes[10] == 0x76 && bytes[11] == 0x63) || // HEVC
       (bytes[8] == 0x6D && bytes[9] == 0x69 && bytes[10] == 0x66 && bytes[11] == 0x31))) { // HEIF
    return _isHEIFAnimated(bytes);
  }

  // Check for TIFF (which can be animated)
  if ((bytes[0] == 0x49 && bytes[1] == 0x49 && bytes[2] == 0x2A && bytes[3] == 0x00) ||
      (bytes[0] == 0x4D && bytes[1] == 0x4D && bytes[2] == 0x00 && bytes[3] == 0x2A)) {
    return _isTIFFAnimated(bytes);
  }

  // All other formats are considered not animated
  return false;
}

bool _isPNGAnimated(Uint8List bytes) {
  for (int i = 0; i < bytes.length - 7; i++) {
    if (bytes[i] == 0x61 && bytes[i + 1] == 0x63 && bytes[i + 2] == 0x54 && bytes[i + 3] == 0x4C) {
      return true; // Found acTL chunk, indicating APNG
    }
  }
  return false;
}

bool _isGIFAnimated(Uint8List bytes) {
  int frameCount = 0;
  for (int i = 0; i < bytes.length - 2; i++) {
    if (bytes[i] == 0x00 && bytes[i + 1] == 0x21 && bytes[i + 2] == 0xF9) {
      frameCount++;
      if (frameCount > 1) return true;
    }
  }
  return false;
}

bool _isWebPAnimated(Uint8List bytes) {
  for (int i = 12; i < bytes.length - 4; i++) {
    if (bytes[i] == 0x41 && bytes[i + 1] == 0x4E && bytes[i + 2] == 0x49 && bytes[i + 3] == 0x4D) {
      return true; // Found ANIM chunk, it's an animated WebP
    }
  }
  return false;
}

bool _isHEIFAnimated(Uint8List bytes) {
  // Simplified check: look for 'mif1' brand which indicates multi-image file
  for (int i = 0; i < bytes.length - 4; i++) {
    if (bytes[i] == 0x6D && bytes[i+1] == 0x69 && bytes[i+2] == 0x66 && bytes[i+3] == 0x31) {
      return true;
    }
  }
  return false;
}

bool _isTIFFAnimated(Uint8List bytes) {
  // Simplified check: look for multiple IFDs (Image File Directories)
  int ifdCount = 0;
  bool isLittleEndian = bytes[0] == 0x49;
  
  int offset = isLittleEndian ? 
    bytes[4] | (bytes[5] << 8) | (bytes[6] << 16) | (bytes[7] << 24) :
    (bytes[4] << 24) | (bytes[5] << 16) | (bytes[6] << 8) | bytes[7];

  while (offset != 0 && offset < bytes.length - 2) {
    ifdCount++;
    if (ifdCount > 1) return true;
    
    int entryCount = isLittleEndian ?
      bytes[offset] | (bytes[offset + 1] << 8) :
      (bytes[offset] << 8) | bytes[offset + 1];
      
    offset += 2 + entryCount * 12;
    if (offset >= bytes.length - 4) break;
    
    offset = isLittleEndian ?
      bytes[offset] | (bytes[offset + 1] << 8) | (bytes[offset + 2] << 16) | (bytes[offset + 3] << 24) :
      (bytes[offset] << 24) | (bytes[offset + 1] << 16) | (bytes[offset + 2] << 8) | bytes[offset + 3];
  }
  
  return false;
}