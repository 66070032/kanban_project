require("dotenv").config();
const express = require("express");
const cors = require("cors");
const path = require("path");
const app = express();
const morgan = require("morgan");

app.use(cors());
app.use(express.json({ limit: "2mb" }));
app.use(morgan("dev"));
app.use("/uploads", express.static(path.join(__dirname, "../uploads")));

const userRoutes = require("./routes/user.routes");
const taskRoutes = require("./routes/task.routes");
const authRoutes = require("./routes/auth.routes");
const reminderRoutes = require("./routes/reminder.routes");
const groupRoutes = require("./routes/group.routes");
app.use("/users", userRoutes);
app.use("/tasks", taskRoutes);
app.use("/auth", authRoutes);
app.use("/reminders", reminderRoutes);
app.use("/groups", groupRoutes);

app.get("/health", (req, res) => {
  res.json({ status: "ok" });
});

app.listen(3000, () => {
  console.log("API running on port 3000");
});
