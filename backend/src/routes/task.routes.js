const express = require("express");
const router = express.Router();
const controller = require("../controllers/task.controller");
const upload = require("../middleware/multer");

// ดึง task ทั้งหมด
router.get("/", controller.getTasks);

// ดึง task ตาม assignee
router.get("/assignee/:assignee_id", controller.getTasksByAssignee);

// Upload voice instruction (MUST BE BEFORE /:id routes)
router.post(
  "/:id/voice-instruction",
  upload.single("voice_instruction"),
  controller.uploadVoiceInstruction,
);

// Get voice instruction URL (MUST BE BEFORE /:id routes)
router.get("/:id/voice-instruction", controller.getVoiceInstruction);

// ดึง task ตาม id
router.get("/:id", controller.getTaskById);

// สร้าง task
router.post("/", controller.createTask);

// อัปเดต task
router.put("/:id", controller.updateTask);

// ลบ task
router.delete("/:id", controller.deleteTask);

module.exports = router;
