import type { WithId } from "mongodb";
import type { User } from "../../types/user.js";
import type { UserViewModel } from "../../types/user-view-model.js";

export const mapToUserViewModel = (user: WithId<User>): UserViewModel => ({
  id: user._id.toString(),
  login: user.login,
  email: user.email,
  createdAt: user.createdAt,
});
