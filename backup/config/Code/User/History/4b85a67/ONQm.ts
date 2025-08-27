// /app/api/stripe-webhook/route.ts
import { headers } from "next/headers";
import { NextResponse } from "next/server";
import Stripe from "stripe";
import { z } from "zod";

const stripe = new Stripe(process.env.STRIPE_SECRET_KEY!, {
  apiVersion: "2024-04-10",
});

export async function POST(req: Request) {
  const rawBody = await req.text();
  const signature = headers().get("stripe-signature")!;
  
  let event: Stripe.Event;

  try {
    event = stripe.webhooks.constructEvent(
      rawBody,
      signature,
      process.env.STRIPE_WEBHOOK_SECRET!
    );
  } catch (err: any) {
    console.error("Webhook signature verification failed:", err.message);
    return new NextResponse("Webhook error", { status: 400 });
  }

  if (event.type === "checkout.session.completed") {
    const session = event.data.object as Stripe.Checkout.Session;

    // Extract your custom metadata
    const metadata = session.metadata!;
    const payload = {
      tier: metadata.tier,
      price: Number(metadata.price),
      tip: Number(metadata.tip),
      total: Number(metadata.total),
      email: metadata.email,
      timestamp: new Date().toISOString(),
      orderId: metadata.orderId,
      customerEmail: session.customer_email,
      imageFile: {
        url: metadata.imageUrl,
        filename: metadata.imageFilename,
        alt: metadata.imageAlt,
        photographer: metadata.photographer,
        pexelsId: metadata.pexelsId,
      },
    };

    await fetch(process.env.ZAPIER_WEBHOOK_URL!, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-Zapier-Secret": process.env.ZAPIER_SECRET_KEY!,
        "User-Agent": "Mystery-Artwork-Marketplace/1.0",
      },
      body: JSON.stringify(payload),
    });
  }

  return new NextResponse("ok", { status: 200 });
}
