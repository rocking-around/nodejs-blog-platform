import type { Collection, Db } from "mongodb";
import type { Blog } from "../blogs/types/blog.js";
import type { Post } from "../posts/types/post.js";

export const BLOGS_COLLECTION_NAME = "blogs";
export const POSTS_COLLECTION_NAME = "posts";

export let blogsCollection: Collection<Blog>;
export let postsCollection: Collection<Post>;

export const initCollections = (database: Db): void => {
  blogsCollection = database.collection<Blog>(BLOGS_COLLECTION_NAME);
  postsCollection = database.collection<Post>(POSTS_COLLECTION_NAME);
};

export const getAllCollections = (): Array<
  Collection<Blog> | Collection<Post>
> => [
  blogsCollection,
  postsCollection,
];
