import { compare, hash } from "bcryptjs";

const PASSWORD_HASH_ROUNDS = 10;

export const passwordService = {
  async generateHash(password: string): Promise<string> {
    return hash(password, PASSWORD_HASH_ROUNDS);
  },

  async verify(password: string, passwordHash: string): Promise<boolean> {
    return compare(password, passwordHash);
  },
};
