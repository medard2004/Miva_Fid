const http = require('http');
const fs = require('fs');
const path = require('path');
const url = require('url');

const PORT = process.env.PORT || 8080;
const BUILD_DIR = path.resolve(__dirname, '..', 'build', 'web');

const MIME_TYPES = {
  '.html': 'text/html; charset=UTF-8',
  '.js': 'application/javascript; charset=UTF-8',
  '.mjs': 'application/javascript; charset=UTF-8',
  '.json': 'application/json; charset=UTF-8',
  '.css': 'text/css; charset=UTF-8',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.gif': 'image/gif',
  '.svg': 'image/svg+xml',
  '.ico': 'image/x-icon',
  '.wasm': 'application/wasm',
  '.ttf': 'font/ttf',
  '.otf': 'font/otf',
  '.woff': 'font/woff',
  '.woff2': 'font/woff2',
};

const server = http.createServer((req, res) => {
  const parsedUrl = url.parse(req.url);
  let pathname = parsedUrl.pathname;

  // Normalisation du chemin
  let filePath = path.join(BUILD_DIR, pathname);

  // Vérifier si le chemin existe
  fs.stat(filePath, (err, stats) => {
    if (!err && stats.isDirectory()) {
      filePath = path.join(filePath, 'index.html');
    }

    fs.readFile(filePath, (readErr, content) => {
      if (!readErr) {
        const ext = path.extname(filePath).toLowerCase();
        const contentType = MIME_TYPES[ext] || 'application/octet-stream';
        res.writeHead(200, {
          'Content-Type': contentType,
          'Access-Control-Allow-Origin': '*',
          'Cache-Control': 'no-cache, no-store, must-revalidate',
          'Pragma': 'no-cache',
          'Expires': '0',
        });
        res.end(content);
      } else {
        // Fallback SPA (Single Page Application) pour Flutter Web
        // Renvoie index.html pour les routes profondes comme /join?code=RESTO123
        const indexPath = path.join(BUILD_DIR, 'index.html');
        fs.readFile(indexPath, (indexErr, indexContent) => {
          if (!indexErr) {
            res.writeHead(200, {
              'Content-Type': 'text/html; charset=UTF-8',
              'Access-Control-Allow-Origin': '*',
              'Cache-Control': 'no-cache, no-store, must-revalidate',
              'Pragma': 'no-cache',
              'Expires': '0',
            });
            res.end(indexContent);
          } else {
            res.writeHead(404, { 'Content-Type': 'text/plain' });
            res.end('Fichier non trouvé et build/web/index.html absent.');
          }
        });
      }
    });
  });
});

server.listen(PORT, '0.0.0.0', () => {
  console.log(`Serveur Miva Fid Client Web actif !`);
  console.log(`URL locale : http://localhost:${PORT}/`);
  console.log(`URL Deep-link test : http://localhost:${PORT}/join?code=RESTO123`);
});

