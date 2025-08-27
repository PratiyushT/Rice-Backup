// /pages/api/generate-image.ts
import type { NextApiRequest, NextApiResponse } from "next";

const PEXELS_API_KEY = process.env.PEXELS_KEY!;

export default async function handler(req: NextApiRequest, res: NextApiResponse) {
  try {
    const page = Math.floor(Math.random() * 100) + 1;
    const response = await fetch(`https://api.pexels.com/v1/search?query=art&per_page=1&page=${page}`, {
      headers: {
        Authorization: PEXELS_API_KEY,
      },
    });

    const data = await response.json();
    const photo = data.photos?.[0];

    if (!photo) {
      return res.status(404).json({ error: "No image found" });
    }

    return res.status(200).json({
      imageUrl: photo.src.large,
      photographer: photo.photographer,
      alt: photo.alt,
    });
  } catch (error) {
    return res.status(500).json({ error: "Failed to generate image" });
  }
}
