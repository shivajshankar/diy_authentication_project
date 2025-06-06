const { createProxyMiddleware } = require('http-proxy-middleware');

module.exports = function(app) {
  app.use(
    '/api',
    createProxyMiddleware({
      target: 'http://localhost:8080',
      changeOrigin: true,
      secure: false,
    })
  );

  // Handle client-side routing - return index.html for all routes that don't match a file
  app.use((req, res, next) => {
    if (req.accepts('html')) {
      res.sendFile('index.html', { root: 'public' });
    } else {
      next();
    }
  });
};
