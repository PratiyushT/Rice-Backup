// src/app/api/generate-artwork/route.ts

import { NextResponse } from "next/server";

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

export async function GET() {
  try {
    const page = Math.floor(Math.random() * MAX_PAGES) + 1;

    const pexelsRes = await fetch(
      `https://api.pexels.com/v1/search?query=${SEARCH_QUERY}&per_page=${PER_PAGE}&page=${page}`,
      {
        headers: { Authorization: PEXELS_API_KEY },
        cache: "no-store",
      }
    );

    const data = (await pexelsRes.json()) as PexelsSearchResponse;
    const photos = data.photos;

    if (!photos || photos.length === 0) {
      return NextResponse.json({ error: "No photos found" }, { status: 404 });
    }

    const chosen = photos[Math.floor(Math.random() * photos.length)];

    return NextResponse.json(
      {
        imageUrl: chosen.src.large2x,
        photographer: chosen.photographer,
        alt: chosen.alt,
        pexelsId: chosen.id,
      },
      {
        status: 200,
        headers: {
          "Cache-Control": "no-store, max-age=0",
        },
      }
    );
  } catch (err) {
    console.error("❌ Artwork URL error:", err);
    return NextResponse.json(
      { error: "Failed to generate image URL" },
      { status: 500 }
    );
  }
}
