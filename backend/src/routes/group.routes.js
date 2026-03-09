const express = require("express");
const router = express.Router();
const groupController = require("../controllers/group.controller");

// Group CRUD
router.post("/", groupController.createGroup);
router.get("/user/:userId", groupController.getUserGroups);
router.get("/:id", groupController.getGroupById);
router.put("/:id", groupController.updateGroup);
router.delete("/:id", groupController.deleteGroup);

// Members
router.get("/:id/members", groupController.getGroupMembers);
router.post("/:id/members", groupController.addMember);
router.delete("/:id/members/:userId", groupController.removeMember);

// User search (for adding members)
router.get("/:id/search-users", groupController.searchUsers);

// Messages
router.get("/:id/messages", groupController.getMessages);
router.post("/:id/messages", groupController.sendMessage);
router.post("/:id/messages/task", groupController.sendTaskMessage);

module.exports = router;
