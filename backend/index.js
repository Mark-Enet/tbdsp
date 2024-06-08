// backend/index.js
const express = require('express');
const app = express();
const PORT = process.env.PORT || 3000;
const client = require('./elasticsearch');

app.get('/', (req, res) => {
  res.send('Hello, TBDP!');
});

app.get('/search', async (req, res) => {
  const { q } = req.query;
  const { body } = await client.search({
    index: 'tbdp',
    body: {
      query: {
        match: { message: q }
      }
    }
  });
  res.send(body.hits.hits);
});

app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});