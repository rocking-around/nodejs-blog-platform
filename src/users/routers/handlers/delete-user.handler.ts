import type { Request, Response } from "express";
import { HTTP_STATUSES } from "../../../core/types/http-statuses.js";
import { usersService } from "../../application/users.service.js";

export const deleteUserHandler = async (
  req: Request<{ id: string }>,
  res: Response,
): Promise<Response> => {
  const isDeleted = await usersService.delete(req.params.id);

  if (!isDeleted) {
    return res.sendStatus(HTTP_STATUSES.NOT_FOUND);
  }

  return res.sendStatus(HTTP_STATUSES.NO_CONTENT);
};
