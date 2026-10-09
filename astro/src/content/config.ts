import { defineCollection, z } from "astro:content";

const postsCollection = defineCollection({
	schema: z.object({
		title: z.string(),
		published: z.coerce.date(),
		updated: z.preprocess(value => value === "" || value === null ? undefined : value, z.coerce.date().optional()),
		draft: z.boolean().optional().default(false),
		description: z.string().optional().default(""),
		image: z.string().optional().default(""),
		tags: z.array(z.string()).optional().default([]),
		category: z.string().optional().nullable().default(""),
		lang: z.string().optional().default(""),

		/* For internal use */
		prevTitle: z.string().default(""),
		prevSlug: z.string().default(""),
		nextTitle: z.string().default(""),
		nextSlug: z.string().default(""),
	}),
});
const projectsCollection = defineCollection({
  schema: z.object({
    title: z.string(),
    description: z.string().optional().default(""),
    venue: z.string().optional().default(""),
    year: z.coerce.number().optional(),
    image: z.string().optional().default(""),
    github: z.union([z.string().url(), z.literal("")]).optional(),
    paper: z.union([z.string().url(), z.literal("")]).optional(),
    draft: z.boolean().optional().default(false),
  }),
});
const specCollection = defineCollection({
	schema: z.object({}),
});
export const collections = {
	posts: postsCollection,
	projects: projectsCollection,
	spec: specCollection,
};
