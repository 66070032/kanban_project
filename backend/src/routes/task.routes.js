const express = require('express');
const router = express.Router();
const controller = require('../controllers/task.controller');

// ดึงรายการ Task ทั้งหมด
router.get('/', controller.getTasks);
router.get('/assignee/:assigneeId', controller.getTasksByAssignee);

// สร้าง Task ใหม่
router.post('/', controller.createTask);

// ดึงข้อมูล Task รายชิ้น (ตาม ID)
router.get('/:id', controller.getTaskById);

// อัปเดตข้อมูล Task หรือเปลี่ยนสถานะ (Status)
router.put('/:id', controller.updateTask);

// ลบ Task
router.delete('/:id', controller.deleteTask);

module.exports = router;