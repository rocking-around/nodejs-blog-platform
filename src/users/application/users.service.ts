import { passwordService } from "../../auth/application/password.service.js";
import type { FieldError } from "../../core/types/FieldError.js";
import type { UserInputDto } from "../dto/user.input.dto.js";
import { usersRepository } from "../repositories/users.repository.js";
import type { User } from "../types/user.js";

export type CreateUserResult =
  | { status: "success"; userId: string }
  | { status: "error"; error: FieldError };

export const usersService = {
  async create(input: UserInputDto): Promise<CreateUserResult> {
    const userWithLogin = await usersRepository.findByLogin(input.login);

    if (userWithLogin) {
      return {
        status: "error",
        error: { field: "login", message: "login should be unique" },
      };
    }

    const userWithEmail = await usersRepository.findByEmail(input.email);

    if (userWithEmail) {
      return {
        status: "error",
        error: { field: "email", message: "email should be unique" },
      };
    }

    const user: User = {
      login: input.login,
      email: input.email,
      passwordHash: await passwordService.generateHash(input.password),
      createdAt: new Date().toISOString(),
    };

    return { status: "success", userId: await usersRepository.create(user) };
  },

  async delete(id: string): Promise<boolean> {
    return usersRepository.delete(id);
  },
};
