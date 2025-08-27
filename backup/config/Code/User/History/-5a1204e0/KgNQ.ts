import type { NextApiRequest, NextApiResponse } from "next";
import JSZip from "jszip";
import fetch from "node-fetch";

const PEXELS_API_KEY = process.env.PEXELS_KEY!;
const SEARCH_QUERY = "art";
const PER_PAGE = 10;
const MAX_PAGES = 100;

export default async function handler(req: NextApiRequest, res: NextApiResponse) {
  try {
    const email = req.body?.email;
    if (!email) return res.status(400).json({ error: "Missing email" });

    const page = Math.floor(Math.random() * MAX_PAGES) + 1;
    const pexelsRes = await fetch(`https://api.pexels.com/v1/search?query=${SEARCH_QUERY}&per_page=${PER_PAGE}&page=${page}`, {
      headers: { Authorization: PEXELS_API_KEY },
    });

    const data:any = await pexelsRes.json();
    const photos = data.photos;
    if (!photos || photos.length === 0) return res.status(404).json({ error: "No photos found" });

    const chosen = photos[Math.floor(Math.random() * photos.length)];
    const imageRes = await fetch(chosen.src.large2x);
    const buffer = await imageRes.buffer();

    const zip = new JSZip();
    const filename = `mystery-artwork-${chosen.id}.jpg`;
    zip.file(filename, buffer);
    const zipBuffer = await zip.generateAsync({ type: "nodebuffer" });

    const zipBase64 = zipBuffer.toString("base64");

    return res.status(200).json({
      fileBase64: zipBase64,
      fileName: `mystery-artwork-${chosen.id}.zip`,
      fileType: "application/zip",
      email
    });

  } catch (err) {
    console.error("ZIP error:", err);
    return res.status(500).json({ error: "Internal server error" });
  }
}
