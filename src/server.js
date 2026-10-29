require('dotenv').config();
const express = require('express');
const cors = require('cors');
const path = require('path');
const fs = require('fs');
const { authenticate } = require('./middleware/auth');
const { UPLOAD_ROOT, HR_FILE_MAX_KB } = require('./middleware/upload');

// Session token secret (login keeps you signed in). Set JWT_SECRET in .env for production.
if (!process.env.JWT_SECRET) process.env.JWT_SECRET = 'hhc-recruitment-local-secret';

const app = express();
app.set('trust proxy', true);
app.use(cors({ origin: process.env.FRONTEND_URL || true }));
app.use(express.json({ limit: '2mb' }));

app.get('/api/health', (req, res) => res.json({ ok: true }));

// Public
app.use('/api/auth', require('./routes/auth'));
app.use('/api/portal', require('./routes/portal'));

// Authenticated
app.use('/api/masters', authenticate, require('./routes/masters'));
app.use('/api/users', authenticate, require('./routes/users'));                 // Users (Manager / Super Admin)
app.use('/api/candidates', authenticate, require('./routes/candidates'));       // Step 1
app.use('/api/ctc', authenticate, require('./routes/ctc'));                     // Step 2 & 3
app.use('/api/offers', authenticate, require('./routes/offers'));               // Step 4a
app.use('/api/agreements', authenticate, require('./routes/agreements'));       // Step 4b
app.use('/api/documents', authenticate, require('./routes/documents'));         // Step 5
app.use('/api/employees', authenticate, require('./routes/employees'));         // Step 6 & 7
app.use('/api/appointments', authenticate, require('./routes/appointments'));   // Step 8

/** Protected file download: /api/files?p=letters/x.pdf&token=JWT */
app.get('/api/files', authenticate, (req, res) => {
  const rel = String(req.query.p || '');
  const full = path.resolve(UPLOAD_ROOT, rel);
  if (!rel || !full.startsWith(path.resolve(UPLOAD_ROOT) + path.sep) || !fs.existsSync(full)) {
    return res.status(404).json({ message: 'File not found' });
  }
  if (req.query.download) return res.download(full);
  res.sendFile(full);
});

// Serve built frontend in production (npm run build in /frontend)
const dist = path.join(__dirname, '..', '..', 'frontend', 'dist');
if (fs.existsSync(dist)) {
  app.use(express.static(dist));
  app.get(/^\/(?!api\/).*/, (req, res) => res.sendFile(path.join(dist, 'index.html')));
}

app.use((req, res) => res.status(404).json({ message: 'Not found' }));

// eslint-disable-next-line no-unused-vars
app.use((err, req, res, next) => {
  if (err.code === 'LIMIT_FILE_SIZE') {
    return res.status(400).json({ message: `File is too large. Maximum size is ${HR_FILE_MAX_KB} KB.` });
  }
  if (err.code === 'ER_DUP_ENTRY') return res.status(409).json({ message: 'Duplicate entry' });
  const status = err.status || (err.message?.startsWith('Only PDF') ? 400 : 500);
  if (status === 500) console.error(err);
  res.status(status).json({ message: status === 500 ? 'Something went wrong' : err.message });
});

// Log instead of silently dying, so a failure shows up in the backend window / pm2 logs
process.on('unhandledRejection', (err) => console.error('[unhandledRejection]', err));
process.on('uncaughtException', (err) => {
  console.error('[uncaughtException]', err);
  process.exit(1); // pm2 / the developer restarts it; the error above says why
});

const PORT = Number(process.env.PORT || 5000);
app.listen(PORT, () => console.log(`Recruitment API running on http://localhost:${PORT}`));
