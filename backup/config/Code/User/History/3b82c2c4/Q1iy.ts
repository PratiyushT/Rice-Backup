import { json } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { STRIPE_SECRET_KEY, STRIPE_API_VERSION } from '$env/static/private';
import { PUBLIC_SITE_URL } from '$env/static/public';
import type { PricingTier } from '../../../app.d.ts';
import { StripeService } from '../../../lib/services/stripe';

export const POST: RequestHandler = async ({ request }) => {
  try {
    const { tier, tipAmount }: { tier: PricingTier; tipAmount: number } = await request.json();

    if (!tier) {
      return json({ error: 'Invalid tier selected' }, { status: 400 });
    }

    const stripeService = new StripeService(STRIPE_SECRET_KEY, STRIPE_API_VERSION);
    const session = await stripeService.createCheckoutSession(tier, tipAmount || 0, PUBLIC_SITE_URL);

    return json({ url: session.url });
  } catch (error: any) {
    console.error('Error creating checkout session:', error.message, error.stack);
    return json({ error: 'Failed to create checkout session' }, { status: 500 });
  }
};
