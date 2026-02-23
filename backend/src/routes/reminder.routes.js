const express = require('express');
const router = express.Router();
const controller = require('../controllers/reminder.controller');

// ดึง reminder ตาม user
router.get('/user/:userId', controller.getReminders);

// ดึง reminder ตาม id
router.get('/:id', controller.getReminderById);

// สร้าง reminder
router.post('/', controller.createReminder);

// อัปเดต reminder
router.put('/:id', controller.updateReminder);

// ลบ reminder
router.delete('/:id', controller.deleteReminder);

module.exports = router;