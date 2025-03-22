const { DynamoDBClient } = require("@aws-sdk/client-dynamodb");
const { DynamoDBDocumentClient, GetCommand } = require("@aws-sdk/lib-dynamodb");
const jwt = require("jsonwebtoken");

const client = DynamoDBDocumentClient.from(new DynamoDBClient());
const USERS_TABLE = process.env.USERS_TABLE;
const JWT_SECRET = process.env.JWT_SECRET;

exports.handler = async (event) => {
  try {
    const authHeader = event.headers.Authorization || event.headers.authorization;

    if (!authHeader || !authHeader.startsWith("Bearer ")) {
      return { statusCode: 401, body: JSON.stringify({ message: "Missing or invalid Authorization header" }) };
    }

    const token = authHeader.split(" ")[1];
    const decoded = jwt.verify(token, JWT_SECRET);

    const result = await client.send(new GetCommand({
      TableName: USERS_TABLE,
      Key: { username: decoded.username },
    }));

    if (!result.Item) {
      return { statusCode: 404, body: JSON.stringify({ message: "User not found" }) };
    }

    const { passwordHash, ...userInfo } = result.Item;

    return {
      statusCode: 200,
      body: JSON.stringify({ user: userInfo }),
    };
  } catch (err) {
    console.error("Get user info error:", err);

    if (err.name === "TokenExpiredError") {
      return { statusCode: 401, body: JSON.stringify({ message: "Token expired" }) };
    }

    return {
      statusCode: 401,
      body: JSON.stringify({ message: "Unauthorized" }),
    };
  }
};
