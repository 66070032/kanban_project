const pool = require("../db");

// สร้าง Task
exports.createTask = async (req, res) => {
  try {
    const { title, description, assignee_id, status, due_at } = req.body;

    const { rows } = await pool.query(
      `INSERT INTO tasks (title, description, assignee_id, status, due_at)
       VALUES ($1, $2, $3, COALESCE($4, 'todo'), $5)
       RETURNING *`,
      [title, description, assignee_id, status, due_at || null],
    );

    res.status(201).json(rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Server error" });
  }
};

// ดึง Task ทั้งหมด
exports.getTasks = async (req, res) => {
  try {
    const { rows } = await pool.query(`
      SELECT t.*, u.display_name as assignee_name,
             g.name as group_name
      FROM tasks t 
      LEFT JOIN users u ON t.assignee_id = u.id
      LEFT JOIN "groups" g ON t.group_id = g.id
      ORDER BY t.created_at DESC
    `);

    res.json(rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Server error" });
  }
};

// ดึง Task ตาม assignee
exports.getTasksByAssignee = async (req, res) => {
  try {
    const { assignee_id } = req.params;

    const { rows } = await pool.query(
      `
      SELECT t.*, u.display_name as assignee_name,
             g.name as group_name
      FROM tasks t 
      LEFT JOIN users u ON t.assignee_id = u.id
      LEFT JOIN "groups" g ON t.group_id = g.id
      WHERE t.assignee_id = $1
      ORDER BY t.created_at DESC
    `,
      [assignee_id],
    );

    res.json(rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Server error" });
  }
};

// ดึง Tasks ตาม group
exports.getTasksByGroup = async (req, res) => {
  try {
    const { group_id } = req.params;

    const { rows } = await pool.query(
      `
      SELECT t.*, u.display_name as assignee_name,
             g.name as group_name
      FROM tasks t 
      LEFT JOIN users u ON t.assignee_id = u.id
      LEFT JOIN "groups" g ON t.group_id = g.id
      WHERE t.group_id = $1
      ORDER BY t.created_at DESC
    `,
      [group_id],
    );

    res.json(rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Server error" });
  }
};

// อัปเดต Task
exports.updateTask = async (req, res) => {
  try {
    const { id } = req.params;
    const { title, description, status, assignee_id } = req.body;

    const { rows } = await pool.query(
      `UPDATE tasks
       SET title=$1,
           description=$2,
           status=$3,
           assignee_id=$4,
           updated_at=NOW()
       WHERE id=$5
       RETURNING *`,
      [title, description, status, assignee_id, id],
    );

    if (rows.length === 0)
      return res.status(404).json({ message: "Task not found" });

    res.json(rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// ดึง Task ตาม ID
exports.getTaskById = async (req, res) => {
  try {
    const { id } = req.params;

    const { rows } = await pool.query(
      `SELECT t.*, u.display_name as assignee_name,
              g.name as group_name
       FROM tasks t
       LEFT JOIN users u ON t.assignee_id = u.id
       LEFT JOIN "groups" g ON t.group_id = g.id
       WHERE t.id = $1`,
      [id],
    );

    if (rows.length === 0)
      return res.status(404).json({ message: "Task not found" });

    res.json(rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// ลบ Task
exports.deleteTask = async (req, res) => {
  try {
    const { id } = req.params;

    const { rowCount } = await pool.query(`DELETE FROM tasks WHERE id = $1`, [
      id,
    ]);

    if (rowCount === 0)
      return res.status(404).json({ message: "Task not found" });

    res.json({ message: "Task deleted successfully" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// Upload voice instruction
exports.uploadVoiceInstruction = async (req, res) => {
  try {
    const { id } = req.params;

    if (!req.file) {
      return res.status(400).json({ message: "No voice file provided" });
    }

    const voiceFileName = req.file.filename;

    const { rows } = await pool.query(
      `UPDATE tasks
       SET voice_instruction_uuid=$1,
           updated_at=NOW()
       WHERE id=$2
       RETURNING *`,
      [voiceFileName, id],
    );

    if (rows.length === 0)
      return res.status(404).json({ message: "Task not found" });

    res.json({
      message: "Voice instruction uploaded successfully",
      task: rows[0],
      voice_instruction_url: `/uploads/${voiceFileName}`,
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// Download voice instruction
exports.getVoiceInstruction = async (req, res) => {
  try {
    const { id } = req.params;

    const { rows } = await pool.query(
      `SELECT voice_instruction_uuid FROM tasks WHERE id = $1`,
      [id],
    );

    if (rows.length === 0)
      return res.status(404).json({ message: "Task not found" });

    const voiceFile = rows[0].voice_instruction_uuid;
    if (!voiceFile) {
      return res.status(404).json({ message: "No voice instruction found" });
    }

    res.json({
      voice_instruction_url: `/uploads/${voiceFile}`,
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};
