export async function createStripeSession({
  tier,
  email,
  tipAmount,
}: {
  tier: { title: string; price: number; description: string };
  email: string;
  tipAmount: number;
}): Promise<string> {
  const stripeSession = await fetch("/api/create-checkout-session", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ tier, email, tipAmount }),
  });

  const sessionData = await stripeSession.json();

  if (!stripeSession.ok) {
    throw new Error("Stripe Checkout failed to initiate");
  }

  return sessionData.sessionUrl;
}
