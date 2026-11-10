import type { Collection, Db } from "mongodb";
import type { Blog } from "../blogs/types/blog.js";
import type { Comment } from "../comments/types/comment.js";
import type { Post } from "../posts/types/post.js";
import type { User } from "../users/types/user.js";

export const BLOGS_COLLECTION_NAME = "blogs";
export const POSTS_COLLECTION_NAME = "posts";
export const USERS_COLLECTION_NAME = "users";
export const COMMENTS_COLLECTION_NAME = "comments";

export let blogsCollection: Collection<Blog>;
export let postsCollection: Collection<Post>;
export let usersCollection: Collection<User>;
export let commentsCollection: Collection<Comment>;

export const initCollections = (database: Db): void => {
  blogsCollection = database.collection<Blog>(BLOGS_COLLECTION_NAME);
  postsCollection = database.collection<Post>(POSTS_COLLECTION_NAME);
  usersCollection = database.collection<User>(USERS_COLLECTION_NAME);
  commentsCollection = database.collection<Comment>(COMMENTS_COLLECTION_NAME);
};

export const getAllCollections = (): Array<
  Collection<Blog> | Collection<Post> | Collection<User> | Collection<Comment>
> => [
  blogsCollection,
  postsCollection,
  usersCollection,
  commentsCollection,
];
