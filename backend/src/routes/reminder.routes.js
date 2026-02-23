const express = require('express');
const router = express.Router();
const controller = require('../controllers/reminder.controller');

router.get('/', controller.getReminders);
router.get('/user/:userId', controller.getRemindersByUser);
router.get('/:id', controller.getReminderById);
router.post('/', controller.createReminder);
router.put('/:id', controller.updateReminder);
router.delete('/:id', controller.deleteReminder);

module.exports = router;