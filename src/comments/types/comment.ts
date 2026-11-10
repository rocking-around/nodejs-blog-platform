export type CommentatorInfo = {
  userId: string;
  userLogin: string;
};

export type Comment = {
  content: string;
  postId: string;
  commentatorInfo: CommentatorInfo;
  createdAt: string;
};
