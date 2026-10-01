const normalizeApiPath = (value: string): string => {
  const withLeadingSlash = value.startsWith("/") ? value : `/${value}`;
  return withLeadingSlash.replace(/\/$/, "");
};

export const env = {
  port: Number(process.env.PORT ?? 5001),
  apiPath: normalizeApiPath(process.env.API_PATH ?? "/api"),
  mongoUrl:
    process.env.MONGO_URL ??
    "mongodb://localhost:27017/nodejs-blog-platform",
  mongoDatabaseName: process.env.DB_NAME ?? "nodejs-blog-platform",
};
