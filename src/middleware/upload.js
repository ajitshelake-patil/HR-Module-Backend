const multer = require('multer');
const path = require('path');
const fs = require('fs');
const crypto = require('crypto');

const UPLOAD_ROOT = path.join(__dirname, '..', '..', 'uploads');
const ALLOWED = ['.pdf', '.doc', '.docx', '.jpg', '.jpeg', '.png'];

function storageFor(subdir) {
  const dir = path.join(UPLOAD_ROOT, subdir);
  fs.mkdirSync(dir, { recursive: true });
  return multer.diskStorage({
    destination: dir,
    filename: (req, file, cb) => {
      const ext = path.extname(file.originalname).toLowerCase();
      cb(null, `${Date.now()}-${crypto.randomBytes(6).toString('hex')}${ext}`);
    },
  });
}

/** HR uploads (resume, signed consultant agreement): max 400 KB per file */
const HR_FILE_MAX_KB = 400;

/**
 * uploader('resumes')                                    -> 400 KB, PDF/DOC/DOCX/JPG/PNG
 * uploader('documents', { maxBytes, allowed: [...] })    -> custom size / types
 */
function uploader(subdir, { maxBytes = HR_FILE_MAX_KB * 1024, allowed = ALLOWED } = {}) {
  const names = allowed.map((e) => e.slice(1).toUpperCase()).filter((e) => e !== 'JPEG').join(', ');
  return multer({
    storage: storageFor(subdir),
    limits: { fileSize: maxBytes },
    fileFilter: (req, file, cb) => {
      const ext = path.extname(file.originalname).toLowerCase();
      if (!allowed.includes(ext)) return cb(new Error(`Only ${names} files are allowed`));
      cb(null, true);
    },
  });
}

/** Candidate joining documents: 250 KB per file, PDF / JPG / PNG */
const DOC_MAX_KB = 250;
const DOC_TYPES = ['.pdf', '.jpg', '.jpeg', '.png'];

/** Path stored in DB, relative to uploads root, e.g. "resumes/123-abc.pdf" */
function relPath(subdir, filename) {
  return `${subdir}/${filename}`;
}

/** Super Admin signature (final approval): image only (PNG / JPG), max 10 KB */
const SIGNATURE_MAX_KB = 10;
const SIGNATURE_TYPES = ['.png', '.jpg', '.jpeg'];

/** True only when the file really is a PNG or JPEG (checks the first bytes, not just the name) */
function isImageFile(fullPath) {
  try {
    const fd = fs.openSync(fullPath, 'r');
    const b = Buffer.alloc(8);
    fs.readSync(fd, b, 0, 8, 0);
    fs.closeSync(fd);
    const png = b[0] === 0x89 && b[1] === 0x50 && b[2] === 0x4e && b[3] === 0x47;
    const jpg = b[0] === 0xff && b[1] === 0xd8 && b[2] === 0xff;
    return png || jpg;
  } catch {
    return false;
  }
}

/** data: URI for an uploaded image (used to print the signature inside letters / PDFs) */
function imageDataUri(rel) {
  if (!rel) return '';
  const full = path.join(UPLOAD_ROOT, rel);
  if (!fs.existsSync(full)) return '';
  const mime = /\.png$/i.test(rel) ? 'image/png' : 'image/jpeg';
  return `data:${mime};base64,${fs.readFileSync(full).toString('base64')}`;
}

module.exports = {
  uploader, relPath, UPLOAD_ROOT, DOC_MAX_KB, DOC_TYPES, HR_FILE_MAX_KB,
  SIGNATURE_MAX_KB, SIGNATURE_TYPES, isImageFile, imageDataUri,
};
