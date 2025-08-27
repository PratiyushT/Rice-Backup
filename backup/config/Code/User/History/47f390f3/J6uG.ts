import Stripe from 'stripe';
import type { PricingTier } from '../../app.d.ts';

export class StripeService {
  private stripe: Stripe;

  constructor(apiKey: string, apiVersion: string = '2024-04-10') {
    if (!apiKey) {
      throw new Error('Stripe API key is missing');
    }

    this.stripe = new Stripe(apiKey, {
      apiVersion: apiVersion as Stripe.LatestApiVersion
    });
  }

  async createCheckoutSession(
    tier: PricingTier,
    tipAmount: number,
    baseUrl: string
  ): Promise<Stripe.Checkout.Session> {
    const lineItems: Stripe.Checkout.SessionCreateParams.LineItem[] = [
      {
        price_data: {
          currency: 'usd',
          product_data: {
            name: tier.name,
            description: tier.description,
            images: ['https://images.unsplash.com/photo-1541961017774-22349e4a1262?w=400']
          },
          unit_amount: Math.round(tier.price * 100),
        },
        quantity: 1,
      }
    ];

    if (tipAmount > 0) {
      lineItems.push({
        price_data: {
          currency: 'usd',
          product_data: {
            name: 'Tip for Artist',
            description: 'Support the amazing photographers'
          },
          unit_amount: Math.round(tipAmount * 100),
        },
        quantity: 1,
      });
    }

    const totalAmount = Math.round(tier.price * 100) + Math.round(tipAmount * 100);

    return await this.stripe.checkout.sessions.create({
      payment_method_types: ['card'],
      line_items: lineItems,
      mode: 'payment',
      success_url: `${baseUrl}/success?session_id={CHECKOUT_SESSION_ID}`,
      cancel_url: `${baseUrl}`,
      metadata: {
        tier_id: tier.id,
        tier_name: tier.name,
        tier_price: tier.price.toString(),
        tip_amount: tipAmount.toString(),
        total_amount: (totalAmount / 100).toFixed(2)
      },
      billing_address_collection: 'required',
      automatic_tax: { enabled: false }
    });
  }
}
