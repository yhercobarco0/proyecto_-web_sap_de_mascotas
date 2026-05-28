const fs = require('fs');
const path = require('path');

const logFilePath = path.resolve(__dirname, '../../../logs/auth.log');

const ensureLogFolder = () => {
  const folder = path.dirname(logFilePath);
  if (!fs.existsSync(folder)) {
    fs.mkdirSync(folder, { recursive: true });
  }
};

const formatLine = ({ userId, rol, ip, browser, action, details }) => {
  const timestamp = new Date().toISOString();
  const payload = JSON.stringify(details || {});
  return `[${timestamp}] userId=${userId || 'anon'} rol=${rol || 'unknown'} ip=${ip || 'unknown'} browser=${browser || 'unknown'} action=${action || 'unknown'} details=${payload}\n`;
};

const audit = async ({ userId, rol, ip, browser, action, details }) => {
  try {
    ensureLogFolder();
    const line = formatLine({ userId, rol, ip, browser, action, details });
    await fs.promises.appendFile(logFilePath, line, 'utf8');
  } catch (error) {
    console.error('Error writing audit log:', error.message);
  }
};

module.exports = { audit };