import { usersRepository } from "../../users/repositories/users.repository.js";
import type { LoginInputDto } from "../dto/login.input.dto.js";
import { passwordService } from "./password.service.js";

export const authService = {
  async checkCredentials(input: LoginInputDto): Promise<boolean> {
    const user = await usersRepository.findByLoginOrEmail(input.loginOrEmail);

    if (!user) {
      return false;
    }

    return passwordService.verify(input.password, user.passwordHash);
  },
};
