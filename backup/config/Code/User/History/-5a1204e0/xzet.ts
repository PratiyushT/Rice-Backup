import type { NextApiRequest, NextApiResponse } from "next";

const PEXELS_API_KEY = process.env.PEXELS_KEY!;
const SEARCH_QUERY = "art"; // You can change this to "abstract", "painting", etc.
const PER_PAGE = 15;
const MAX_PAGES = 100; // Pexels limits total result pages for many queries

export default async function handler(req: NextApiRequest, res: NextApiResponse) {
  try {
    const randomPage = Math.floor(Math.random() * MAX_PAGES) + 1;

    const response = await fetch(`https://api.pexels.com/v1/search?query=${SEARCH_QUERY}&per_page=${PER_PAGE}&page=${randomPage}`, {
      headers: {
        Authorization: PEXELS_API_KEY,
      },
    });

    if (!response.ok) {
      return res.status(response.status).json({ error: "Failed to fetch from Pexels API" });
    }

    const data = await response.json();
    const photos = data.photos;

    if (!photos || photos.length === 0) {
      return res.status(404).json({ error: "No photos found for the query" });
    }

    const randomIndex = Math.floor(Math.random() * photos.length);
    const photo = photos[randomIndex];

    return res.status(200).json({
      imageUrl: photo.src.large,
      photographer: photo.photographer,
      alt: photo.alt || SEARCH_QUERY,
      url: photo.url // Pexels page
    });
  } catch (error) {
    console.error("[Generate Image Error]", error);
    return res.status(500).json({ error: "Failed to generate image" });
  }
}
