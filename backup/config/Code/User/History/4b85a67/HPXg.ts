import { NextApiRequest, NextApiResponse } from "next";
import { buffer } from "micro";
import Stripe from "stripe";
import axios from "axios";

const stripe = new Stripe(process.env.STRIPE_SECRET_KEY!, {
  apiVersion: "2023-10-16",
});

export const config = {
  api: {
    bodyParser: false,
  },
};

export default async function handler(req: NextApiRequest, res: NextApiResponse) {
  const buf = await buffer(req);
  const sig = req.headers["stripe-signature"] as string;

  let event: Stripe.Event;

  try {
    event = stripe.webhooks.constructEvent(
      buf,
      sig,
      process.env.STRIPE_WEBHOOK_SECRET!
    );
  } catch (err) {
    return res.status(400).send(`Webhook Error: ${err instanceof Error ? err.message : "Unknown error"}`);
  }

  if (event.type === "checkout.session.completed") {
    const session = event.data.object as Stripe.Checkout.Session;

    // Step 2: Extract metadata
    const metadata = session.metadata || {};
    const email = session.customer_email || metadata.email;

    // Step 3: Build payload like your original structure
    const payload = {
      tier: metadata.tierTitle,
      price: parseFloat(metadata.basePrice),
      tip: parseFloat(metadata.tip || "0"),
      total: session.amount_total! / 100,
      email,
      timestamp: new Date().toISOString(),
      orderId: `ORDER-${Date.now()}-${Math.random().toString(36).substring(2, 10)}`,
      customerEmail: email,
      imageFile: {
        url: metadata.imageUrl,
        filename: metadata.imageFilename,
        alt: metadata.imageAlt,
        photographer: metadata.photographer,
        pexelsId: metadata.pexelsId,
      },
    };

    // Step 4: Send to Zapier
    try {
      await axios.post("https://hooks.zapier.com/hooks/catch/your-id", payload, {
        headers: {
          "Content-Type": "application/json",
          "X-Zapier-Secret": "mystery-artwork-secure-2024-abc123xyz789",
          "User-Agent": "Mystery-Artwork-Marketplace/1.0",
        },
      });
    } catch (err) {
      console.error("Failed to send to Zapier:", err);
    }
  }

  res.status(200).json({ received: true });
}
