const express = require('express');
const { v4: uuidv4 } = require('uuid');
const { authenticateToken } = require('../middleware/auth');
const questions = require('../data/mock_questions.json');

const router = express.Router();

router.get('/info', authenticateToken, (req, res) => {
  res.json({
    title: 'General Assessment',
    duration_minutes: 45,
    total_questions: questions.length
  });
});

router.get('/questions', authenticateToken, (req, res) => {
  // Return questions without correct answers
  const clientQuestions = questions.map(q => ({
    id: q.id,
    text: q.text,
    options: q.options,
    subject: q.subject
  }));
  res.json(clientQuestions);
});

router.post('/submit', authenticateToken, (req, res) => {
  const { answers, duration_taken_seconds } = req.body;

  if (!answers || !Array.isArray(answers)) {
    return res.status(400).json({ message: 'Answers array is required' });
  }

  const reference = `ACH-2026-${uuidv4().substring(0, 5).toUpperCase()}`;

  res.json({
    submitted: true,
    timestamp: new Date().toISOString(),
    reference,
    answers_received: answers.length,
    duration_taken_seconds: duration_taken_seconds || 0
  });
});

// Proctor endpoints
router.post('/proctor/snapshot', authenticateToken, (req, res) => {
  const { image_base64, event_type } = req.body;
  console.log(`[Proctor] Snapshot received - type: ${event_type}, size: ${(image_base64 || '').length} chars`);
  res.json({ logged: true });
});

router.post('/proctor/event', authenticateToken, (req, res) => {
  const { type, timestamp } = req.body;
  console.log(`[Proctor] Event: ${type} at ${timestamp}`);
  res.json({ logged: true });
});

module.exports = router;
