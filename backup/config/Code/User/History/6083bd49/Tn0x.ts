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
  {
    id: "curator",
    price: 20,
    title: "Curator's Choice",
    description: "Handpicked pieces from emerging artists",
    features: [
      "Premium digital artwork",
      "Artist biography & story",
      "Signed certificate",
      "Priority shipping",
      "Collectible packaging",
    ],
  },
  {
    id: "collector",
    price: 50,
    title: "Collector's Edition",
    description: "Exclusive pieces from established artists",
    features: [
      "Limited edition artwork",
      "Artist video message",
      "Numbered certificate",
      "Express shipping",
      "Museum-quality materials",
      "Protective sleeve",
    ],
  },
  {
    id: "masterpiece",
    price: 100,
    title: "Masterpiece Mystery",
    description: "Rare and exceptional artistic creations",
    features: [
      "Original or rare print",
      "Personal artist note",
      "Premium certificate",
      "White-glove delivery",
      "Conservation-grade materials",
      "Custom display frame",
      "Lifetime authenticity guarantee",
    ],
  },
];
