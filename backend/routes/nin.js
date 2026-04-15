const express = require('express');
const { authenticateToken } = require('../middleware/auth');

const router = express.Router();

router.post('/verify', authenticateToken, (req, res) => {
  const { nin, dob } = req.body;

  if (!nin || !dob) {
    return res.status(400).json({ 
      success: false, 
      message: 'NIN and date of birth are required' 
    });
  }

  if (nin.length !== 11 || !/^\d{11}$/.test(nin)) {
    return res.status(400).json({ 
      success: false, 
      message: 'NIN must be exactly 11 digits' 
    });
  }

  // Special test NIN that returns error
  if (nin === '00000000000') {
    return res.status(404).json({ 
      success: false, 
      message: 'NIN not found' 
    });
  }

  // Mock success for any valid NIN + DOB
  res.json({
    success: true,
    name: 'John Doe',
    photo_url: 'https://placeholder.example/photo.jpg',
    nin_verified: true
  });
});

module.exports = router;
