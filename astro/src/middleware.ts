import { defineMiddleware } from "astro:middleware";
import legacyAliases from "./data/legacy-aliases.json";
export const onRequest = defineMiddleware((context, next) => {
  if (!import.meta.env.DEV) return next();
  let pathname: string;
  try { pathname = decodeURIComponent(context.url.pathname); }
  catch { return next(); }
  const target = legacyAliases[pathname as keyof typeof legacyAliases];
  return target ? context.redirect(target, 302) : next();
});
