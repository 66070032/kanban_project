const pool = require('../db');

// ดึง reminders ตาม user
exports.getReminders = async (req, res) => {
  try {
    const { userId } = req.params;

    const { rows } = await pool.query(
      `SELECT id, user_id, title, description, due_date,
              is_completed, is_sent, created_at, updated_at
       FROM reminders
       WHERE user_id = $1
       ORDER BY due_date ASC`,
      [userId]
    );

    res.json(rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Server error' });
  }
};

// ดึง reminder ตาม id
exports.getReminderById = async (req, res) => {
  try {
    const { id } = req.params;

    const { rows } = await pool.query(
      `SELECT * FROM reminders WHERE id = $1`,
      [id]
    );

    if (rows.length === 0) {
      return res.status(404).json({ message: 'Reminder not found' });
    }

    res.json(rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Server error' });
  }
};

// สร้าง reminder
exports.createReminder = async (req, res) => {
  try {
    const { userId, title, description, dueDate } = req.body;

    if (!userId || !title || !dueDate) {
      return res.status(400).json({ message: 'userId, title and dueDate required' });
    }

    const { rows } = await pool.query(
      `INSERT INTO reminders (user_id, title, description, due_date)
       VALUES ($1, $2, $3, $4)
       RETURNING *`,
      [userId, title, description || null, dueDate]
    );

    res.status(201).json(rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Server error' });
  }
};

// อัปเดต reminder
exports.updateReminder = async (req, res) => {
  try {
    const { id } = req.params;
    const { title, description, dueDate, isCompleted } = req.body;

    const { rows } = await pool.query(
      `UPDATE reminders
       SET title = COALESCE($1, title),
           description = COALESCE($2, description),
           due_date = COALESCE($3, due_date),
           is_completed = COALESCE($4, is_completed),
           updated_at = NOW()
       WHERE id = $5
       RETURNING *`,
      [title, description, dueDate, isCompleted, id]
    );

    if (rows.length === 0) {
      return res.status(404).json({ message: 'Reminder not found' });
    }

    res.json(rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Server error' });
  }
};

// ลบ reminder
exports.deleteReminder = async (req, res) => {
  try {
    const { id } = req.params;

    const { rowCount } = await pool.query(
      `DELETE FROM reminders WHERE id = $1`,
      [id]
    );

    if (rowCount === 0) {
      return res.status(404).json({ message: 'Reminder not found' });
    }

    res.json({ message: 'Reminder deleted' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Server error' });
  }
};