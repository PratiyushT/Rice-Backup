export interface ArtworkTier {
  id: string;
  price: number;
  title: string;
  description: string;
  features: string[];
}

export const artworkTiers: ArtworkTier[] = [
  {
    id: "discovery",
    price: 10,
    title: "Discovery Collection",
    description: "Perfect for art enthusiasts starting their collection",
    features: [
      "Digital artwork print",
      "Artist information card",
      "Certificate of authenticity",
      "Standard shipping",
    ],
  },
  // ...other tiers
];
