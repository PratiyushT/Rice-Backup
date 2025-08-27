import { NextRequest, NextResponse } from 'next/server';

export async function POST(request: NextRequest) {
  try {
    const orderData = await request.json();

    // Get environment variables (server-side only)
    const zapierWebhookUrl = process.env.NEXT_PUBLIC_ZAPIER_WEBHOOK_URL;
    const zapierSecretKey = process.env.ZAPIER_SECRET_KEY;

    if (!zapierWebhookUrl || !zapierSecretKey) {
      console.error('Missing Zapier configuration');
      return NextResponse.json(
        { error: 'Webhook configuration error' },
        { status: 500 }
      );
    }

    // Send data to Zapier with secret key in headers
    const response = await fetch(zapierWebhookUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-Zapier-Secret': zapierSecretKey,
        'User-Agent': 'Mystery-Artwork-Marketplace/1.0'
      },
      body: JSON.stringify(orderData),
    });

    if (response.ok) {
      console.log('✅ Order data sent to Zapier successfully');
      return NextResponse.json({ success: true });
    } else {
      console.warn('⚠️ Zapier webhook response not OK:', response.status);
      return NextResponse.json(
        { error: 'Zapier webhook failed', status: response.status },
        { status: 502 }
      );
    }

  } catch (error) {
    console.error('❌ Webhook API error:', error);
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
  }
}
