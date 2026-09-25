const { createApp } = require('./app');
const { resolvePort } = require('./config');

const port = resolvePort(process.env.PORT);
const app = createApp();

const server = app.listen(port, '0.0.0.0', () => {
  console.log(`secure-delivery-api listening on port ${port}`);
});

function shutdown(signal) {
  console.log(`${signal} received, shutting down`);

  server.close((error) => {
    if (error) {
      console.error('Failed to shut down cleanly', error);
      process.exitCode = 1;
      return;
    }

    process.exitCode = 0;
  });
}

process.on('SIGTERM', () => shutdown('SIGTERM'));
process.on('SIGINT', () => shutdown('SIGINT'));
