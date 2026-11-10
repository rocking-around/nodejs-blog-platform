import { usersRepository } from "../../users/repositories/users.repository.js";
import type { LoginInputDto } from "../dto/login.input.dto.js";
import { passwordService } from "./password.service.js";
import { jwtService } from "./jwt.service.js";

export const authService = {
  async login(input: LoginInputDto): Promise<string | null> {
    const user = await usersRepository.findByLoginOrEmail(input.loginOrEmail);

    if (!user) {
      return null;
    }

    const isPasswordValid = await passwordService.verify(
      input.password,
      user.passwordHash,
    );

    return isPasswordValid
      ? jwtService.createAccessToken(user._id.toString())
      : null;
  },
};
