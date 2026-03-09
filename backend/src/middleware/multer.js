const multer = require("multer");
const path = require("path");
const fs = require("fs");
const { v4: uuidv4 } = require("uuid");

// Ensure uploads directory exists
const uploadsDir = path.join(__dirname, "../../uploads");
if (!fs.existsSync(uploadsDir)) {
  fs.mkdirSync(uploadsDir, { recursive: true });
}

// Configure storage
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, uploadsDir);
  },
  filename: (req, file, cb) => {
    const uniqueName = `${uuidv4()}_${Date.now()}.m4a`;
    cb(null, uniqueName);
  },
});

// Filter to accept only audio files
const fileFilter = (req, file, cb) => {
  // Accept common audio MIME types
  const allowedMimes = [
    "audio/mp4",
    "audio/mpeg",
    "audio/wav",
    "audio/aac",
    "audio/mp4a-latm",
    "audio/x-m4a",
    "application/x-m4a",
  ];

  // Also check file extension as fallback
  const fileExt = path.extname(file.originalname).toLowerCase();
  const allowedExts = [".m4a", ".mp3", ".wav", ".aac", ".ogg", ".flac"];

  if (allowedMimes.includes(file.mimetype) || allowedExts.includes(fileExt)) {
    cb(null, true);
  } else {
    cb(
      new Error(
        `Only audio files are allowed. Got: ${file.mimetype} (${fileExt})`,
      ),
    );
  }
};

const upload = multer({
  storage,
  fileFilter,
  limits: { fileSize: 50 * 1024 * 1024 }, // 50MB
});

module.exports = upload;
