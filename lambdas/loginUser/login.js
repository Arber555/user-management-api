const { DynamoDBClient } = require("@aws-sdk/client-dynamodb");
const { DynamoDBDocumentClient, GetCommand } = require("@aws-sdk/lib-dynamodb");
const jwt = require("jsonwebtoken");
const bcrypt = require("bcryptjs");

const client = DynamoDBDocumentClient.from(new DynamoDBClient());
const USERS_TABLE = process.env.USERS_TABLE;
const JWT_SECRET = process.env.JWT_SECRET;

exports.handler = async (event) => {
  try {
    const { username, password } = JSON.parse(event.body || "{}");

    if (!username || !password) {
      return { statusCode: 400, body: JSON.stringify({ message: "Username and password required" }) };
    }

    const result = await client.send(new GetCommand({
      TableName: USERS_TABLE,
      Key: { username },
    }));

    const user = result.Item;

    if (!user || !(await bcrypt.compare(password, user.passwordHash))) {
      return {
        statusCode: 401,
        body: JSON.stringify({ message: "Invalid credentials" }),
      };
    }

    const token = jwt.sign({ username }, JWT_SECRET, { expiresIn: "1h" });

    return {
      statusCode: 200,
      body: JSON.stringify({ token }),
    };
  } catch (err) {
    console.error("Login error:", err);
    return {
      statusCode: 500,
      body: JSON.stringify({ message: "Login failed. Please try again." }),
    };
  }
};
