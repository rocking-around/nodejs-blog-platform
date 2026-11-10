import jsonwebtoken, { type JwtPayload } from "jsonwebtoken";
import { env } from "../../core/config/env.js";

const { sign, verify } = jsonwebtoken;

type AccessTokenPayload = JwtPayload & {
  userId: string;
};

const isAccessTokenPayload = (
  payload: string | JwtPayload,
): payload is AccessTokenPayload =>
  typeof payload !== "string" && typeof payload.userId === "string";

export const jwtService = {
  createAccessToken(userId: string): string {
    return sign({ userId }, env.jwtSecret, { expiresIn: "1h" });
  },

  getUserId(token: string): string | null {
    try {
      const payload = verify(token, env.jwtSecret);
      return isAccessTokenPayload(payload) ? payload.userId : null;
    } catch {
      return null;
    }
  },
};
