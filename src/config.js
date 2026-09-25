const DEFAULT_PORT = 3000;

function resolvePort(value) {
  const candidate = value ?? DEFAULT_PORT;
  const port = Number(candidate);

  if (!Number.isInteger(port) || port < 1 || port > 65535) {
    throw new Error('PORT must be an integer between 1 and 65535');
  }

  return port;
}

module.exports = {
  DEFAULT_PORT,
  resolvePort
};
