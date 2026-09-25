const express = require('express');
const packageMetadata = require('../package.json');

function createApp() {
  const app = express();

  app.disable('x-powered-by');

  app.use(express.json({
    limit: '32kb'
  }));

  app.get('/health', (req, res) => {
    res.status(200).json({
      status: 'ok'
    });
  });

  app.get('/version', (req, res) => {
    res.status(200).json({
      name: packageMetadata.name,
      version: packageMetadata.version
    });
  });

  app.get('/api/status', (req, res) => {
    res.status(200).json({
      service: 'secure-delivery-api',
      environment: process.env.NODE_ENV || 'development',
      status: 'operational'
    });
  });

  app.use((req, res) => {
    res.status(404).json({
      error: 'not_found'
    });
  });

  return app;
}

module.exports = {
  createApp
};
