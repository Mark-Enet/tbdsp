const express = require('express');
const { createProxyMiddleware } = require('http-proxy-middleware');
const path = require('path');

const app = express();
const port = Number(process.env.PORT || 3011);
const apiTarget = process.env.API_TARGET || 'http://127.0.0.1:5000';
const buildDirectory = path.join(__dirname, 'build');

app.use(
  '/api',
  createProxyMiddleware({
    target: apiTarget,
    changeOrigin: true,
    pathRewrite: (requestPath) => `/api${requestPath}`,
  }),
);

app.use(express.static(buildDirectory));
app.get('*', (_request, response) => {
  response.sendFile(path.join(buildDirectory, 'index.html'));
});

app.listen(port, '0.0.0.0', () => {
  console.log(`TBDSP frontend listening on port ${port}; proxying /api to ${apiTarget}`);
});