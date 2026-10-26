#!/usr/bin/env node
/**
 * Мок-сервер учебного API «Библиотека».
 * Запуск: node mock-server.js --port 8080 --origin http://localhost:5555
 */

'use strict';

const http = require('node:http');
const crypto = require('node:crypto');

const args = process.argv.slice(2);
function arg(name, fallback) {
  const i = args.indexOf('--' + name);
  return i !== -1 && args[i + 1] ? args[i + 1] : fallback;
}

const PORT = Number(arg('port', 8080));
const ORIGIN = arg('origin', '*');
const SECRET = 'учебный-ключ';
const ACCESS_TTL = 900;

// Простые данные для тестирования
const db = {
  books: [
    { id: 1, title: 'Война и мир', isbn: '978-5-17-118366-4', year: 1869, pages: 1300, publisherId: 1, authorIds: [1], genreIds: [2], copiesTotal: 4, copiesAvailable: 4 },
    { id: 2, title: 'Анна Каренина', isbn: '978-5-17-090620-1', year: 1877, pages: 864, publisherId: 1, authorIds: [1], genreIds: [2], copiesTotal: 3, copiesAvailable: 3 },
  ],
  authors: [
    { id: 1, fullName: 'Толстой Л. Н.', birthYear: 1828, country: 'Россия' },
    { id: 2, fullName: 'Достоевский Ф. М.', birthYear: 1821, country: 'Россия' },
  ],
  genres: [
    { id: 1, name: 'Роман', description: 'Крупная форма' },
    { id: 2, name: 'Классика', description: 'Классическая литература' },
  ],
  publishers: [
    { id: 1, name: 'АСТ', city: 'Москва' },
    { id: 2, name: 'Эксмо', city: 'Москва' },
  ],
  readers: [
    { id: 1, fullName: 'Иванов И. И.', email: 'ivanov@test.ru', phone: '+79001234567', card: { number: 'RC-000001', issuedAt: '2024-01-01T00:00:00Z' } },
  ],
  loans: [],
};

function cors(res) {
  res.setHeader('Access-Control-Allow-Origin', ORIGIN);
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, PATCH, DELETE, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  res.setHeader('Access-Control-Max-Age', '86400');
}

function send(res, status, payload) {
  cors(res);
  if (payload === undefined || status === 204) {
    res.writeHead(204);
    res.end();
    return;
  }
  const body = JSON.stringify(payload, null, 2);
  res.writeHead(status, { 'Content-Type': 'application/json; charset=utf-8' });
  res.end(body);
}

async function readBody(req) {
  const chunks = [];
  for await (const chunk of req) chunks.push(chunk);
  if (!chunks.length) return {};
  try {
    return JSON.parse(Buffer.concat(chunks).toString('utf8'));
  } catch {
    return null;
  }
}

function paginate(rows, q) {
  const page = Math.max(1, Number(q.page) || 1);
  const size = Math.min(100, Math.max(1, Number(q.size) || 10));
  const total = rows.length;
  return {
    items: rows.slice((page - 1) * size, page * size),
    page,
    size,
    total,
    totalPages: Math.max(1, Math.ceil(total / size)),
  };
}

async function handle(req, res, url) {
  const q = Object.fromEntries(url.searchParams.entries());
  const path = url.pathname.replace(/\/+$/, '') || '/';
  const method = req.method.toUpperCase();

  // Учебные переключатели
  if (q.__fail) {
    return send(res, Number(q.__fail), { message: 'Ошибка вызвана намеренно' });
  }

  const delay = Number(q.__delay) || 0;
  if (delay > 0) await new Promise(r => setTimeout(r, Math.min(delay, 10000)));

  // Health check
  if (path === '/api/__health' && method === 'GET') {
    return send(res, 200, { status: 'ok', time: new Date().toISOString() });
  }

  // Книги
  if (path === '/api/books' && method === 'GET') {
    let rows = db.books.filter(b => !b.deletedAt);
    if (q.search) {
      const needle = q.search.toLowerCase();
      rows = rows.filter(b => b.title.toLowerCase().includes(needle) || b.isbn.toLowerCase().includes(needle));
    }
    if (q.genreId) rows = rows.filter(b => b.genreIds.includes(Number(q.genreId)));
    if (q.publisherId) rows = rows.filter(b => b.publisherId === Number(q.publisherId));
    const result = paginate(rows, q);
    return send(res, 200, result);
  }

  if (path.match(/^\/api\/books\/\d+$/) && method === 'GET') {
    const id = Number(path.split('/').pop());
    const book = db.books.find(b => b.id === id && !b.deletedAt);
    if (!book) return send(res, 404, { message: 'Книга не найдена' });
    return send(res, 200, book);
  }

  if (path === '/api/books' && method === 'POST') {
    const body = await readBody(req);
    if (!body) return send(res, 400, { message: 'Некорректный JSON' });
    
    // Проверка уникальности ISBN
    const existing = db.books.find(b => b.isbn === body.isbn && !b.deletedAt);
    if (existing) {
      return send(res, 422, {
        message: 'Ошибка валидации',
        errors: { isbn: 'Книга с таким ISBN уже существует' }
      });
    }

    const newId = db.books.length > 0 ? Math.max(...db.books.map(b => b.id)) + 1 : 1;
    const newBook = { id: newId, ...body, copiesAvailable: body.copiesTotal || 0 };
    db.books.push(newBook);
    return send(res, 201, newBook);
  }

  if (path.match(/^\/api\/books\/\d+$/) && method === 'PUT') {
    const id = Number(path.split('/').pop());
    const book = db.books.find(b => b.id === id && !b.deletedAt);
    if (!book) return send(res, 404, { message: 'Книга не найдена' });
    
    const body = await readBody(req);
    Object.assign(book, body);
    return send(res, 200, book);
  }

  if (path.match(/^\/api\/books\/\d+$/) && method === 'DELETE') {
    const id = Number(path.split('/').pop());
    const book = db.books.find(b => b.id === id);
    if (!book) return send(res, 404, { message: 'Книга не найдена' });
    book.deletedAt = new Date().toISOString();
    return send(res, 204);
  }

  if (path === '/api/books/bulk-delete' && method === 'POST') {
    const body = await readBody(req);
    const ids = body.ids || [];
    let deleted = 0;
    for (const id of ids) {
      const book = db.books.find(b => b.id === id && !b.deletedAt);
      if (book) {
        book.deletedAt = new Date().toISOString();
        deleted++;
      }
    }
    return send(res, 200, { deleted });
  }

  // Авторы
  if (path === '/api/authors' && method === 'GET') {
    let rows = db.authors.filter(a => !a.deletedAt);
    if (q.search) {
      const needle = q.search.toLowerCase();
      rows = rows.filter(a => a.fullName.toLowerCase().includes(needle) || a.country.toLowerCase().includes(needle));
    }
    const result = paginate(rows, q);
    return send(res, 200, result);
  }

  // Жанры
  if (path === '/api/genres' && method === 'GET') {
    let rows = db.genres.filter(g => !g.deletedAt);
    if (q.search) {
      const needle = q.search.toLowerCase();
      rows = rows.filter(g => g.name.toLowerCase().includes(needle));
    }
    const result = paginate(rows, q);
    return send(res, 200, result);
  }

  // Издательства
  if (path === '/api/publishers' && method === 'GET') {
    let rows = db.publishers.filter(p => !p.deletedAt);
    if (q.search) {
      const needle = q.search.toLowerCase();
      rows = rows.filter(p => p.name.toLowerCase().includes(needle));
    }
    const result = paginate(rows, q);
    return send(res, 200, result);
  }

  // Читатели
  if (path === '/api/readers' && method === 'GET') {
    let rows = db.readers.filter(r => !r.deletedAt);
    if (q.search) {
      const needle = q.search.toLowerCase();
      rows = rows.filter(r => r.fullName.toLowerCase().includes(needle) || r.email.toLowerCase().includes(needle));
    }
    const result = paginate(rows, q);
    return send(res, 200, result);
  }

  // 404 для всех остальных запросов
  return send(res, 404, { message: `Адрес ${method} ${path} не обслуживается` });
}

const server = http.createServer(async (req, res) => {
  const url = new URL(req.url, `http://${req.headers.host || 'localhost'}`);

  if (req.method === 'OPTIONS') {
    cors(res);
    res.writeHead(204);
    return res.end();
  }

  try {
    await handle(req, res, url);
  } catch (err) {
    console.error(err);
    if (!res.headersSent) send(res, 500, { message: 'Внутренняя ошибка сервера' });
  }
  
  console.log(`${req.method.padEnd(6)} ${url.pathname}${url.search} → ${res.statusCode}`);
});

server.listen(PORT, () => {
  console.log('');
  console.log('  Учебное API «Библиотека»');
  console.log(`  Адрес:              http://localhost:${PORT}/api`);
  console.log(`  Разрешённый источник: ${ORIGIN}`);
  console.log('');
  console.log('  Проверка: http://localhost:8080/api/__health');
  console.log('  Задержка: ?__delay=1500');
  console.log('  Ошибка:   ?__fail=500');
  console.log('');
});