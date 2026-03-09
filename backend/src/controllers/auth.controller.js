const pool = require("../db");
const bcrypt = require("bcrypt");

//
// LOGIN
//
exports.login = async (req, res) => {
  const { email, password } = req.body;

  try {
    // 1. ค้นหา User ด้วย email
    const { rows } = await pool.query("SELECT * FROM users WHERE email = $1", [
      email,
    ]);

    if (rows.length === 0) {
      return res.status(401).json({ message: "อีเมลหรือรหัสผ่านไม่ถูกต้อง" });
    }

    const user = rows[0];

    // 2. ตรวจสอบรหัสผ่าน (เปรียบเทียบรหัสที่ส่งมา กับ Hash ใน DB)
    const isMatch = await bcrypt.compare(password, user.password);

    if (!isMatch) {
      return res.status(401).json({ message: "อีเมลหรือรหัสผ่านไม่ถูกต้อง" });
    }

    // 3. ส่งข้อมูลผู้ใช้กลับ (ห้ามส่ง password ออกไป)
    const { password: _, ...userWithoutPassword } = user;
    res.json({
      message: "Login successful",
      user: userWithoutPassword,
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

//
// REGISTER
//
exports.register = async (req, res) => {
  const { email, display_name, displayName, password } = req.body;
  const name = display_name || displayName;

  if (!email || !name || !password) {
    return res
      .status(400)
      .json({ message: "Email, display name, and password are required" });
  }

  const passwordHash = await bcrypt.hash(password, 10);

  try {
    const { rows } = await pool.query(
      `INSERT INTO users (email, display_name, password)
       VALUES ($1, $2, $3)
       RETURNING id, email, display_name, avatar_url, created_at`,
      [email, name, passwordHash],
    );

    res.status(201).json({ user: rows[0] });
  } catch (err) {
    if (err.code === "23505") {
      return res
        .status(409)
        .json({ message: "An account with this email already exists" });
    }
    res.status(400).json({ message: err.message });
  }
};
