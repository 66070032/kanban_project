const pool = require("../db");
const bcrypt = require("bcrypt");
const path = require("path");
const fs = require("fs");
const multer = require("multer");
const { v4: uuidv4 } = require("uuid");

const avatarStorage = multer.diskStorage({
  destination: (req, file, cb) => {
    const dir = path.join(__dirname, "../../uploads/avatars");
    fs.mkdirSync(dir, { recursive: true });
    cb(null, dir);
  },
  filename: (req, file, cb) => {
    const ext = path.extname(file.originalname) || ".jpg";
    cb(null, `${uuidv4()}${ext}`);
  },
});

exports.avatarUpload = multer({
  storage: avatarStorage,
  limits: { fileSize: 5 * 1024 * 1024 },
  fileFilter: (req, file, cb) => {
    if (file.mimetype.startsWith("image/")) {
      cb(null, true);
    } else {
      cb(new Error("Only image files are allowed"), false);
    }
  },
}).single("avatar");

//
// GET ALL USERS
//
exports.getUsers = async (req, res) => {
  const { rows } = await pool.query(
    `SELECT id, email, display_name, avatar_url, created_at
     FROM users
     ORDER BY created_at DESC`,
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
    [id],
  );

  if (rows.length === 0) {
    return res.status(404).json({ message: "User not found" });
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
    [displayName, avatarUrl, id],
  );

  if (rows.length === 0) {
    return res.status(404).json({ message: "User not found" });
  }

  res.json(rows[0]);
};

//
// UPLOAD AVATAR
//
exports.uploadAvatar = async (req, res) => {
  const { id } = req.params;

  if (!req.file) {
    return res.status(400).json({ message: "No image file uploaded" });
  }

  const protocol = req.headers["x-forwarded-proto"] || req.protocol;
  const host = req.headers["x-forwarded-host"] || req.get("host");
  const avatarUrl = `${protocol}://${host}/uploads/avatars/${req.file.filename}`;

  try {
    const { rows } = await pool.query(
      `UPDATE users
       SET avatar_url = $1
       WHERE id = $2
       RETURNING id, email, display_name, avatar_url, created_at`,
      [avatarUrl, id],
    );

    if (rows.length === 0) {
      return res.status(404).json({ message: "User not found" });
    }

    res.json(rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

//
// CHANGE PASSWORD
//
exports.changePassword = async (req, res) => {
  const { id } = req.params;
  const { currentPassword, newPassword } = req.body;

  if (!currentPassword || !newPassword) {
    return res
      .status(400)
      .json({ message: "currentPassword and newPassword are required" });
  }

  if (newPassword.length < 6) {
    return res
      .status(400)
      .json({ message: "New password must be at least 6 characters" });
  }

  try {
    const { rows } = await pool.query("SELECT * FROM users WHERE id = $1", [
      id,
    ]);

    if (rows.length === 0) {
      return res.status(404).json({ message: "User not found" });
    }

    const user = rows[0];
    const isMatch = await bcrypt.compare(currentPassword, user.password);

    if (!isMatch) {
      return res.status(401).json({ message: "Current password is incorrect" });
    }

    const newHash = await bcrypt.hash(newPassword, 10);
    await pool.query("UPDATE users SET password = $1 WHERE id = $2", [
      newHash,
      id,
    ]);

    res.json({ message: "Password updated successfully" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

//
// DELETE USER
//
exports.deleteUser = async (req, res) => {
  const { id } = req.params;

  const { rowCount } = await pool.query(`DELETE FROM users WHERE id = $1`, [
    id,
  ]);

  if (rowCount === 0) {
    return res.status(404).json({ message: "User not found" });
  }

  res.json({ message: "User deleted" });
};
