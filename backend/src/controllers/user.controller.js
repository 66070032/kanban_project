const pool = require('../db');
const bcrypt = require('bcrypt');

//
// CREATE USER
//
exports.createUser = async (req, res) => {
  const { email, displayName, password } = req.body;

  const passwordHash = await bcrypt.hash(password, 10);

  try {
    const { rows } = await pool.query(
      `INSERT INTO users (email, display_name, password)
       VALUES ($1, $2, $3)
       RETURNING id, email, display_name, avatar_url, created_at`,
      [email, displayName, passwordHash]
    );

    res.status(201).json(rows[0]);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
};

//
// GET ALL USERS
//
exports.getUsers = async (req, res) => {
  const { rows } = await pool.query(
    `SELECT id, email, display_name, avatar_url, created_at
     FROM users
     ORDER BY created_at DESC`
  );

  res.json(rows);
};

//
// GET USER BY ID
//
exports.getUserById = async (req, res) => {
  const { id } = req.params;

  const { rows } = await pool.query(
    `SELECT id, email, display_name, avatar_url, created_at
     FROM users
     WHERE id = $1`,
    [id]
  );

  if (rows.length === 0) {
    return res.status(404).json({ message: 'User not found' });
  }

  res.json(rows[0]);
};

//
// UPDATE USER
//
exports.updateUser = async (req, res) => {
  const { id } = req.params;
  const { displayName, avatarUrl } = req.body;

  const { rows } = await pool.query(
    `UPDATE users
     SET display_name = $1,
         avatar_url = $2
     WHERE id = $3
     RETURNING id, email, display_name, avatar_url, created_at`,
    [displayName, avatarUrl, id]
  );

  if (rows.length === 0) {
    return res.status(404).json({ message: 'User not found' });
  }

  res.json(rows[0]);
};

//
// DELETE USER
//
exports.deleteUser = async (req, res) => {
  const { id } = req.params;

  const { rowCount } = await pool.query(
    `DELETE FROM users WHERE id = $1`,
    [id]
  );

  if (rowCount === 0) {
    return res.status(404).json({ message: 'User not found' });
  }

  res.json({ message: 'User deleted' });
};

//
// LOGIN
//
exports.login = async (req, res) => {
  const { email, password } = req.body;

  try {
    // 1. ค้นหา User ด้วย email
    const { rows } = await pool.query(
      'SELECT * FROM users WHERE email = $1',
      [email]
    );

    if (rows.length === 0) {
      return res.status(401).json({ message: 'อีเมลหรือรหัสผ่านไม่ถูกต้อง' });
    }

    const user = rows[0];

    // 2. ตรวจสอบรหัสผ่าน (เปรียบเทียบรหัสที่ส่งมา กับ Hash ใน DB)
    const isMatch = await bcrypt.compare(password, user.password);

    if (!isMatch) {
      return res.status(401).json({ message: 'อีเมลหรือรหัสผ่านไม่ถูกต้อง' });
    }

    // 3. ส่งข้อมูลผู้ใช้กลับ (ห้ามส่ง password ออกไป)
    const { password: _, ...userWithoutPassword } = user;
    res.json({
      message: 'Login successful',
      user: userWithoutPassword
    });

  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};