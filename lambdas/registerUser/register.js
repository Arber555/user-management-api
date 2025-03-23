const { DynamoDBClient } = require("@aws-sdk/client-dynamodb");
const {
  DynamoDBDocumentClient,
  PutCommand,
  GetCommand,
} = require("@aws-sdk/lib-dynamodb");
const bcrypt = require("bcryptjs");

const client = DynamoDBDocumentClient.from(new DynamoDBClient());
const USERS_TABLE = process.env.USERS_TABLE;

exports.handler = async (event) => {
  try {
    const { username, password, email } = JSON.parse(event.body || "{}");

    // Username validation
    if (
      !username ||
      typeof username !== "string" ||
      username.trim().length === 0 ||
      !/^[a-zA-Z0-9_]+$/.test(username)
    ) {
      return {
        statusCode: 400,
        body: JSON.stringify({
          message:
            "Username must be alphanumeric and cannot include spaces or special characters.",
        }),
      };
    }

    // Password validation
    if (
      !password ||
      typeof password !== "string" ||
      password.length < 8 ||
      !/[A-Z]/.test(password) ||
      !/[0-9]/.test(password)
    ) {
      return {
        statusCode: 400,
        body: JSON.stringify({
          message:
            "Password must be at least 8 characters, include one uppercase letter and one number",
        }),
      };
    }

    // Email validation (optional)
    if (email && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
      return {
        statusCode: 400,
        body: JSON.stringify({ message: "Invalid email format" }),
      };
    }

    // Check if user already exists
    const existing = await client.send(
      new GetCommand({
        TableName: USERS_TABLE,
        Key: { username },
      })
    );

    if (existing.Item) {
      return {
        statusCode: 409,
        body: JSON.stringify({ message: "Username already exists" }),
      };
    }

    const passwordHash = await bcrypt.hash(password, 10);

    // Build item to insert
    const newUser = {
      username,
      passwordHash,
    };

    if (email) newUser.email = email;

    await client.send(
      new PutCommand({
        TableName: USERS_TABLE,
        Item: newUser,
      })
    );

    return {
      statusCode: 201,
      body: JSON.stringify({ message: "User registered successfully" }),
    };
  } catch (err) {
    console.error("Register error:", err);
    return {
      statusCode: 500,
      body: JSON.stringify({
        message: "Registration failed. Please try again.",
      }),
    };
  }
};
