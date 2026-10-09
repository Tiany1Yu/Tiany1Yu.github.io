import type { APIRoute } from "astro";
import { getSortedPostsList } from "@utils/content-utils";
import { getPostUrlBySlug } from "@utils/url-utils";
const escapeHtml = (value: string) => value.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/\"/g, "&quot;");
export const GET: APIRoute = async () => {
  const docs = (await getSortedPostsList()).map((post) => ({
    url: getPostUrlBySlug(post.slug),
    meta: { title: post.data.title },
    excerpt: escapeHtml(post.data.description || post.data.title),
    searchable: [post.data.title, post.data.description, post.data.category, ...(post.data.tags ?? [])].join(" ").toLocaleLowerCase(),
  }));
  return new Response(JSON.stringify(docs), {
    headers: { "Content-Type": "application/json; charset=utf-8", "Cache-Control": "no-cache" },
  });
};
