const pool = require('../db');

// สร้าง Task
exports.createTask = async (req, res) => {
  try {
    const { title, description, assignee_id } = req.body;

    const { rows } = await pool.query(
      `INSERT INTO tasks (title, description, assignee_id)
       VALUES ($1, $2, $3)
       RETURNING *`,
      [title, description, assignee_id]
    );

    res.status(201).json(rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Server error' });
  }
};

// ดึง Task ทั้งหมด
exports.getTasks = async (req, res) => {
  try {
    const { rows } = await pool.query(`
      SELECT t.*, u.display_name as assignee_name 
      FROM tasks t 
      LEFT JOIN users u ON t.assignee_id = u.id 
      ORDER BY t.created_at DESC
    `);

    res.json(rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Server error' });
  }
};

// ดึง Task ตาม assignee
exports.getTasksByAssignee = async (req, res) => {
  try {
    const { assignee_id } = req.params;

    const { rows } = await pool.query(`
      SELECT t.*, u.display_name as assignee_name 
      FROM tasks t 
      LEFT JOIN users u ON t.assignee_id = u.id 
      WHERE t.assignee_id = $1
      ORDER BY t.created_at DESC
    `, [assignee_id]);

    res.json(rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Server error' });
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
      [title, description, status, assignee_id, id]
    );

    if (rows.length === 0)
      return res.status(404).json({ message: 'Task not found' });

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
      `SELECT * FROM tasks WHERE id = $1`,
      [id]
    );

    if (rows.length === 0)
      return res.status(404).json({ message: 'Task not found' });

    res.json(rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// ลบ Task
exports.deleteTask = async (req, res) => {
  try {
    const { id } = req.params;

    const { rowCount } = await pool.query(
      `DELETE FROM tasks WHERE id = $1`,
      [id]
    );

    if (rowCount === 0)
      return res.status(404).json({ message: 'Task not found' });

    res.json({ message: 'Task deleted successfully' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};