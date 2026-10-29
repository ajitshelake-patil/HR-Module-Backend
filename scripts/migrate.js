/**
 * Imports db/hhc_recruitment.sql (all tables + dummy data) into MySQL.
 * WARNING: the file drops and recreates the database - run only for a fresh setup.
 * You can also import the same file directly in MySQL Workbench / phpMyAdmin.
 */
require('dotenv').config();
const fs = require('fs');
const path = require('path');
const mysql = require('mysql2/promise');

(async () => {
  const dbName = process.env.DB_NAME || 'hhc_recruitment';
  let sql = fs.readFileSync(path.join(__dirname, '..', 'db', 'hhc_recruitment.sql'), 'utf8');
  if (dbName !== 'hhc_recruitment') sql = sql.replace(/(DATABASE (?:IF EXISTS )?|USE )hhc_recruitment\b/g, `$1\`${dbName}\``);
  const conn = await mysql.createConnection({
    host: process.env.DB_HOST || 'localhost',
    port: Number(process.env.DB_PORT || 3306),
    user: process.env.DB_USER || 'root',
    password: process.env.DB_PASSWORD || '',
    multipleStatements: true,
  });
  await conn.query(sql);
  await conn.end();
  console.log(`Database "${dbName}" created with tables and dummy data.`);
})().catch((e) => {
  console.error('Database setup failed:', e.message);
  process.exit(1);
});
