const express = require('express');
const { authenticateToken } = require('../middleware/auth');

const router = express.Router();

router.post('/verify', authenticateToken, (req, res) => {
  const { image_base64 } = req.body;

  if (!image_base64) {
    return res.status(400).json({ 
      match: false, 
      message: 'Image data is required' 
    });
  }

  // Mock: always returns successful match
  res.json({
    match: true,
    confidence: 0.97,
    verified: true
  });
});

module.exports = router;
