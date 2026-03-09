const pool = require("../db");

// Create a group
exports.createGroup = async (req, res) => {
  try {
    const { name, description, created_by } = req.body;

    if (!name || !created_by) {
      return res
        .status(400)
        .json({ message: "Name and created_by are required" });
    }

    const { rows } = await pool.query(
      `INSERT INTO groups (name, description, created_by)
       VALUES ($1, $2, $3)
       RETURNING *`,
      [name, description || null, created_by],
    );

    const group = rows[0];

    // Auto-add creator as admin member
    await pool.query(
      `INSERT INTO group_members (group_id, user_id, role)
       VALUES ($1, $2, 'admin')`,
      [group.id, created_by],
    );

    res.status(201).json(group);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Server error" });
  }
};

// Get groups for a user
exports.getUserGroups = async (req, res) => {
  try {
    const { userId } = req.params;

    const { rows } = await pool.query(
      `SELECT g.*,
              u.display_name as creator_name,
              gm.role as user_role,
              (SELECT COUNT(*) FROM group_members WHERE group_id = g.id) as member_count,
              (SELECT json_build_object(
                'id', m.id,
                'content', m.content,
                'message_type', m.message_type,
                'sender_name', su.display_name,
                'created_at', m.created_at
              )
              FROM messages m
              LEFT JOIN users su ON m.sender_id = su.id
              WHERE m.group_id = g.id
              ORDER BY m.created_at DESC
              LIMIT 1) as last_message
       FROM groups g
       JOIN group_members gm ON g.id = gm.group_id AND gm.user_id = $1
       LEFT JOIN users u ON g.created_by = u.id
       ORDER BY g.created_at DESC`,
      [userId],
    );

    res.json(rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Server error" });
  }
};

// Get group by ID
exports.getGroupById = async (req, res) => {
  try {
    const { id } = req.params;

    const { rows } = await pool.query(
      `SELECT g.*, u.display_name as creator_name,
              (SELECT COUNT(*) FROM group_members WHERE group_id = g.id) as member_count
       FROM groups g
       LEFT JOIN users u ON g.created_by = u.id
       WHERE g.id = $1`,
      [id],
    );

    if (rows.length === 0) {
      return res.status(404).json({ message: "Group not found" });
    }

    res.json(rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Server error" });
  }
};

// Update group
exports.updateGroup = async (req, res) => {
  try {
    const { id } = req.params;
    const { name, description } = req.body;

    const { rows } = await pool.query(
      `UPDATE groups SET name = COALESCE($1, name), description = COALESCE($2, description)
       WHERE id = $3 RETURNING *`,
      [name, description, id],
    );

    if (rows.length === 0) {
      return res.status(404).json({ message: "Group not found" });
    }

    res.json(rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Server error" });
  }
};

// Delete group
exports.deleteGroup = async (req, res) => {
  try {
    const { id } = req.params;

    const { rowCount } = await pool.query(`DELETE FROM groups WHERE id = $1`, [
      id,
    ]);

    if (rowCount === 0) {
      return res.status(404).json({ message: "Group not found" });
    }

    res.json({ message: "Group deleted successfully" });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Server error" });
  }
};

// Get group members
exports.getGroupMembers = async (req, res) => {
  try {
    const { id } = req.params;

    const { rows } = await pool.query(
      `SELECT u.id, u.display_name, u.email, u.avatar_url, gm.role, gm.joined_at
       FROM group_members gm
       JOIN users u ON gm.user_id = u.id
       WHERE gm.group_id = $1
       ORDER BY gm.joined_at ASC`,
      [id],
    );

    res.json(rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Server error" });
  }
};

// Add member to group
exports.addMember = async (req, res) => {
  try {
    const { id } = req.params;
    const { user_id, role } = req.body;

    if (!user_id) {
      return res.status(400).json({ message: "user_id is required" });
    }

    // Check if user exists
    const userCheck = await pool.query(`SELECT id FROM users WHERE id = $1`, [
      user_id,
    ]);
    if (userCheck.rows.length === 0) {
      return res.status(404).json({ message: "User not found" });
    }

    const { rows } = await pool.query(
      `INSERT INTO group_members (group_id, user_id, role)
       VALUES ($1, $2, $3)
       ON CONFLICT (group_id, user_id) DO NOTHING
       RETURNING *`,
      [id, user_id, role || "member"],
    );

    if (rows.length === 0) {
      return res.status(409).json({ message: "User already in group" });
    }

    res.status(201).json(rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Server error" });
  }
};

// Remove member from group
exports.removeMember = async (req, res) => {
  try {
    const { id, userId } = req.params;

    const { rowCount } = await pool.query(
      `DELETE FROM group_members WHERE group_id = $1 AND user_id = $2`,
      [id, userId],
    );

    if (rowCount === 0) {
      return res.status(404).json({ message: "Member not found in group" });
    }

    res.json({ message: "Member removed successfully" });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Server error" });
  }
};

// Get messages for a group (paginated)
exports.getMessages = async (req, res) => {
  try {
    const { id } = req.params;
    const limit = parseInt(req.query.limit) || 50;
    const before = req.query.before; // cursor-based pagination

    let query;
    let params;

    if (before) {
      query = `SELECT m.*, u.display_name as sender_name, u.avatar_url as sender_avatar
               FROM messages m
               JOIN users u ON m.sender_id = u.id
               WHERE m.group_id = $1 AND m.id < $2
               ORDER BY m.created_at DESC
               LIMIT $3`;
      params = [id, before, limit];
    } else {
      query = `SELECT m.*, u.display_name as sender_name, u.avatar_url as sender_avatar
               FROM messages m
               JOIN users u ON m.sender_id = u.id
               WHERE m.group_id = $1
               ORDER BY m.created_at DESC
               LIMIT $2`;
      params = [id, limit];
    }

    const { rows } = await pool.query(query, params);

    res.json(rows.reverse()); // Return in chronological order
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Server error" });
  }
};

// Send a text message
exports.sendMessage = async (req, res) => {
  try {
    const { id } = req.params;
    const { sender_id, content } = req.body;

    if (!sender_id || !content) {
      return res
        .status(400)
        .json({ message: "sender_id and content are required" });
    }

    const { rows } = await pool.query(
      `INSERT INTO messages (group_id, sender_id, content, message_type)
       VALUES ($1, $2, $3, 'text')
       RETURNING *`,
      [id, sender_id, content],
    );

    // Fetch with sender info
    const result = await pool.query(
      `SELECT m.*, u.display_name as sender_name, u.avatar_url as sender_avatar
       FROM messages m
       JOIN users u ON m.sender_id = u.id
       WHERE m.id = $1`,
      [rows[0].id],
    );

    res.status(201).json(result.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Server error" });
  }
};

// Send a task message (creates task + message in one go)
exports.sendTaskMessage = async (req, res) => {
  const client = await pool.connect();
  try {
    const { id } = req.params;
    const { sender_id, title, description, assignee_id, due_at } = req.body;

    if (!sender_id || !title) {
      return res
        .status(400)
        .json({ message: "sender_id and title are required" });
    }

    await client.query("BEGIN");

    // Create the task
    const taskResult = await client.query(
      `INSERT INTO tasks (title, description, assignee_id, status, due_at)
       VALUES ($1, $2, $3, 'todo', $4)
       RETURNING *`,
      [title, description || null, assignee_id || null, due_at || null],
    );

    const task = taskResult.rows[0];

    // Build a descriptive message
    let messageContent = `📋 New Task: ${title}`;
    if (assignee_id) {
      const assigneeResult = await client.query(
        `SELECT display_name FROM users WHERE id = $1`,
        [assignee_id],
      );
      if (assigneeResult.rows.length > 0) {
        messageContent += `\nAssigned to: ${assigneeResult.rows[0].display_name}`;
      }
    }
    if (due_at) {
      messageContent += `\nDue: ${new Date(due_at).toLocaleDateString()}`;
    }

    // Create the message linked to the task
    const msgResult = await client.query(
      `INSERT INTO messages (group_id, sender_id, content, message_type, task_id)
       VALUES ($1, $2, $3, 'task', $4)
       RETURNING *`,
      [id, sender_id, messageContent, task.id],
    );

    await client.query("COMMIT");

    // Fetch with sender info
    const result = await pool.query(
      `SELECT m.*, u.display_name as sender_name, u.avatar_url as sender_avatar
       FROM messages m
       JOIN users u ON m.sender_id = u.id
       WHERE m.id = $1`,
      [msgResult.rows[0].id],
    );

    res.status(201).json({
      message: result.rows[0],
      task: task,
    });
  } catch (err) {
    await client.query("ROLLBACK");
    console.error(err);
    res.status(500).json({ message: "Server error" });
  } finally {
    client.release();
  }
};

// Search users to add to group (by email or name)
exports.searchUsers = async (req, res) => {
  try {
    const { q } = req.query;
    const { id } = req.params;

    if (!q || q.length < 2) {
      return res
        .status(400)
        .json({ message: "Search query must be at least 2 characters" });
    }

    const { rows } = await pool.query(
      `SELECT u.id, u.display_name, u.email, u.avatar_url
       FROM users u
       WHERE (LOWER(u.display_name) LIKE $1 OR LOWER(u.email) LIKE $1)
         AND u.id NOT IN (SELECT user_id FROM group_members WHERE group_id = $2)
       LIMIT 20`,
      [`%${q.toLowerCase()}%`, id],
    );

    res.json(rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Server error" });
  }
};
