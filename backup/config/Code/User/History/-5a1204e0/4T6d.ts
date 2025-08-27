import type { NextApiRequest, NextApiResponse } from "next";
import JSZip from "jszip";
import fetch from "node-fetch";

const PEXELS_API_KEY = process.env.PEXELS_API_KEY!;
const SEARCH_QUERY = "art";
const PER_PAGE = 15;
const MAX_PAGES = 100;

export default async function handler(req: NextApiRequest, res: NextApiResponse) {
  try {
    const email = req.body?.email;
    if (!email) return res.status(400).json({ error: "Missing email" });

    const randomPage = Math.floor(Math.random() * MAX_PAGES) + 1;

    const pexelsRes = await fetch(`https://api.pexels.com/v1/search?query=${SEARCH_QUERY}&per_page=${PER_PAGE}&page=${randomPage}`, {
      headers: { Authorization: PEXELS_API_KEY },
    });

    const data = await pexelsRes.json();
    const photos = data.photos;
    const randomPhoto = photos[Math.floor(Math.random() * photos.length)];
    const imageUrl = randomPhoto.src.large;
    const fileName = `mystery-artwork-${randomPhoto.id}.jpg`;

    const imageRes = await fetch(imageUrl);
    const imageBuffer = await imageRes.buffer();

    const zip = new JSZip();
    zip.file(fileName, imageBuffer);
    const zipBuffer = await zip.generateAsync({ type: "nodebuffer" });

    // Return base64 so Zapier can email it
    const zipBase64 = zipBuffer.toString("base64");

    return res.status(200).json({
      fileName: `mystery-artwork-${randomPhoto.id}.zip`,
      fileMime: "application/zip",
      fileBase64: zipBase64,
      email,
    });

  } catch (err) {
    console.error("ZIP Gen Error:", err);
    return res.status(500).json({ error: "Internal error" });
  }
}
