// Pricing configuration
export const PRICING_TIERS = [
  {
    id: 'basic',
    name: 'Basic Surprise',
    price: 10.00,
    description: 'A delightful digital artwork to brighten your day',
    features: [
      'High-quality digital artwork',
      'Instant download',
      'Commercial usage rights',
      'Email support'
    ]
  },
  {
    id: 'premium',
    name: 'Premium Surprise',
    price: 20.00,
    description: 'Premium curated artwork with exclusive content',
    features: [
      'Premium high-resolution artwork',
      'Instant download',
      'Extended commercial rights',
      'Artist information included',
      'Priority support'
    ]
  },
  {
    id: 'premiumPlus',
    name: 'Premium Plus Collection',
    price: 50.00,
    description: 'The ultimate surprise package with bonus content',
    features: [
      'Ultra high-resolution artwork',
      'Multiple format downloads',
      'Full commercial rights',
      'Artist biography & story',
      'Exclusive bonus content',
      'VIP support'
    ]
  },
  {
    id: 'Deluxe',
    name: 'Deluxe Collection',
    price: 100.00,
    description: 'The ultimate surprise package with bonus content',
    features: [
      'Ultra high-resolution artwork',
      'Multiple format downloads',
      'Full commercial rights',
      'Artist biography & story',
      'Exclusive bonus content',
      'VIP support'
    ]
  }
];

// Tip options in dollars
export const TIP_OPTIONS = [0, 1.00, 2.00, 5.00]; // $0, $1, $2, $5

// Pexels search queries for different tier levels
export const PEXELS_QUERIES = {
  basic: 'nature landscape photography',
  premium: 'abstract art modern photography',
  deluxe: 'fine art professional photography'
};

// App metadata
export const APP_CONFIG = {
  name: 'Surprise Artwork Shop',
  description: 'Discover beautiful, high-quality digital artworks curated just for you.',
  supportEmail: 'support@surpriseartworkshop.com',
  version: '1.0.0'
};
