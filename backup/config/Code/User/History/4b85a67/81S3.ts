// /app/api/stripe-webhook/route.ts (Next.js 13+)
import { headers } from "next/headers";
import { NextResponse } from "next/server";
import Stripe from "stripe";

const stripe = new Stripe(process.env.STRIPE_SECRET_KEY!, {
  apiVersion: process.env.NEXT_PUBLIC_STRIPE_API_VERSION as any,
});

export async function POST(req: Request) {
  const body = await req.text();
  const signature = headers().get("stripe-signature")!;
  const webhookSecret = process.env.STRIPE_WEBHOOK_SECRET!;

  let event: Stripe.Event;

  try {
    event = stripe.webhooks.constructEvent(body, signature, webhookSecret);
  } catch (err) {
    console.error("Webhook signature verification failed:", err);
    return NextResponse.json({ error: "Invalid signature" }, { status: 400 });
  }

  if (event.type === "checkout.session.completed") {
    const session = event.data.object as Stripe.Checkout.Session;

    // Forward to Zapier
    const metadata = session.metadata || {};
    const payload = {
      tier: metadata.tier,
      price: parseFloat(metadata.price || "0"),
      tip: parseFloat(metadata.tip || "0"),
      total: parseFloat(metadata.total || "0"),
      email: metadata.email,
      timestamp: metadata.timestamp,
      orderId: metadata.orderId,
      customerEmail: session.customer_email,
      imageFile: {
        url: metadata.imageUrl,
        filename: metadata.filename,
        alt: metadata.alt,
        photographer: metadata.photographer,
        pexelsId: metadata.pexelsId,
      },
    };

    await fetch(process.env.NEXT_PUBLIC_ZAPIER_WEBHOOK_URL!, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-Zapier-Secret": process.env.ZAPIER_SECRET_KEY!,
        "User-Agent": "Mystery-Artwork-Marketplace/1.0",
      },
      body: JSON.stringify(payload),
    });
  }

  return NextResponse.json({ received: true });
}
