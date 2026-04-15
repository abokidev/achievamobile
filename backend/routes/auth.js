const express = require('express');
const jwt = require('jsonwebtoken');
const { JWT_SECRET } = require('../middleware/auth');
const candidates = require('../data/mock_candidates.json');

const router = express.Router();

router.post('/login', (req, res) => {
  const { email, password } = req.body;

  if (!email || !password) {
    return res.status(400).json({ message: 'Email and password are required' });
  }

  if (password !== 'test1234') {
    return res.status(401).json({ message: 'Invalid email or password' });
  }

  const candidate = candidates.find(c => c.email === email) || {
    id: 'usr_001',
    name: 'Test Candidate',
    email: email,
    isVerified: false
  };

  const token = jwt.sign(
    { userId: candidate.id, email: candidate.email },
    JWT_SECRET,
    { expiresIn: '4h' }
  );

  res.json({
    token,
    userId: candidate.id,
    name: candidate.name,
    isVerified: candidate.isVerified || false
  });
});

module.exports = router;
