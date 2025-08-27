import Stripe from 'stripe';
import type { PricingTier } from '../../app.d.ts';

export class StripeService {
  private stripe: Stripe;

  constructor(secretKey: string) {
    this.stripe = new Stripe(secretKey, {
      apiVersion:  process.env.STRIPE_API_VERSION as Stripe.LatestApiVersion
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
          unit_amount: tier.price,
        },
        quantity: 1,
      }
    ];

    // Add tip as separate line item if provided
    if (tipAmount > 0) {
      lineItems.push({
        price_data: {
          currency: 'usd',
          product_data: {
            name: 'Tip for Artist',
            description: 'Support the amazing photographers'
          },
          unit_amount: tipAmount,
        },
        quantity: 1,
      });
    }

    const totalAmount = tier.price + (tipAmount || 0);

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
        total_amount: totalAmount.toString()
      },
      billing_address_collection: 'required',
      customer_email: undefined, // Let customer enter email
      automatic_tax: {
        enabled: false, // Set to true if you want to enable tax calculation
      }
    });
  }

  async constructWebhookEvent(payload: string, signature: string, webhookSecret: string): Promise<Stripe.Event> {
    return this.stripe.webhooks.constructEvent(payload, signature, webhookSecret);
  }

  async retrieveSession(sessionId: string): Promise<Stripe.Checkout.Session> {
    return await this.stripe.checkout.sessions.retrieve(sessionId);
  }

  async retrievePaymentIntent(paymentIntentId: string): Promise<Stripe.PaymentIntent> {
    return await this.stripe.paymentIntents.retrieve(paymentIntentId);
  }
}
