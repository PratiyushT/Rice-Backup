import type { NextApiRequest, NextApiResponse } from "next";
import fetch from "node-fetch";

type PexelsPhoto = {
  id: number;
  width: number;
  height: number;
  url: string;
  photographer: string;
  photographer_url: string;
  photographer_id: number;
  avg_color: string;
  src: {
    original: string;
    large2x: string;
    large: string;
    medium: string;
    small: string;
    portrait: string;
    landscape: string;
    tiny: string;
  };
  alt: string;
};

type PexelsSearchResponse = {
  total_results: number;
  page: number;
  per_page: number;
  photos: PexelsPhoto[];
  next_page?: string;
};




const PEXELS_API_KEY = process.env.PEXELS_KEY!;
const SEARCH_QUERY = "art";
const PER_PAGE = 10;
const MAX_PAGES = 100;

export default async function handler(req: NextApiRequest, res: NextApiResponse) {
  try {

    const page = Math.floor(Math.random() * MAX_PAGES) + 1;
    const pexelsRes = await fetch(`https://api.pexels.com/v1/search?query=${SEARCH_QUERY}&per_page=${PER_PAGE}&page=${page}`, {
      headers: { Authorization: PEXELS_API_KEY },
    });

    const data = (await pexelsRes.json()) as PexelsSearchResponse;
    const photos = data.photos;
    if (!photos || photos.length === 0) return res.status(404).json({ error: "No photos found" });

    const chosen = photos[Math.floor(Math.random() * photos.length)];
   res.setHeader("Cache-Control", "no-store, max-age=0");

    return res.status(200).json({
      imageUrl: chosen.src.large2x,
      photographer: chosen.photographer,
      alt: chosen.alt,
      pexelsId: chosen.id
    });

  } catch (err) {
    console.error("❌ Artwork URL error:", err);
    return res.status(500).json({ error: "Failed to generate image URL" });
  }
}
