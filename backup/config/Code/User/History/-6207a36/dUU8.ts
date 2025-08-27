// pages/api/create-checkout-session.ts
import { NextApiRequest, NextApiResponse } from "next";
import Stripe from "stripe";

const stripe = new Stripe(process.env.STRIPE_SECRET_KEY!, {
  apiVersion: process.env.STRIPE_API_VERSION as Stripe.LatestApiVersion,
});

export default async function handler(req: NextApiRequest, res: NextApiResponse) {
  if (req.method !== "POST") {
    res.setHeader("Allow", "POST");
    return res.status(405).end("Method Not Allowed");
  }

  try {
    const { tier, email, tipAmount } = req.body;

    const lineItems = [
      {
        price_data: {
          currency: "usd",
          product_data: {
            name: tier.title,
            description: tier.description,
          },
          unit_amount: tier.price * 100,
        },
        quantity: 1,
      },
    ];

    if (tipAmount > 0) {
      lineItems.push({
        price_data: {
          currency: "usd",
          product_data: { name: "Tip" },
          unit_amount: tipAmount * 100,
        },
        quantity: 1,
      });
    }

    const session = await stripe.checkout.sessions.create({
      payment_method_types: ["card"],
      customer_email: email,
      line_items: lineItems,
      mode: "payment",
      success_url: `${req.headers.origin}/success?session_id={CHECKOUT_SESSION_ID}`,
      cancel_url: `${req.headers.origin}/cancel`,
    });

    res.status(200).json({ sessionUrl: session.url });
  } catch (error) {
    console.error("Stripe session error:", error);
    res.status(500).json({ error: "Unable to create checkout session" });
  }
}
