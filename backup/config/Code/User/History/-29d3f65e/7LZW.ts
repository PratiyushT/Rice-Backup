import { toast } from "sonner";
import { useState } from "react";
import { ArtworkTier } from "@libs/data/artworkTiers";
import { createStripeSession } from "@libs/stripe/createSession";


export function usePurchase() {
  const [isProcessing, setIsProcessing] = useState(false);

  async function handlePurchase({
    selectedTier,
    email,
    tip,
    customTip,
    agreeToTerms,
  }: {
    selectedTier: ArtworkTier | undefined;
    email: string;
    tip: string;
    customTip: string;
    agreeToTerms: boolean;
  }) {
    if (!selectedTier) {
      toast.error("Please select an artwork tier");
      return;
    }
    if (!email || !email.includes("@")) {
      toast.error("Please enter a valid email address");
      return;
    }
    if (!agreeToTerms) {
      toast.error("Please agree to the terms and conditions");
      return;
    }
    if (tip === "custom" && (!customTip || isNaN(parseFloat(customTip)) || parseFloat(customTip) < 0)) {
      toast.error("Please enter a valid tip amount");
      return;
    }

    setIsProcessing(true);

    const tipAmount = tip === "custom" ? parseFloat(customTip) || 0 : parseFloat(tip);

    try {
      const url = await createStripeSession({
        tier: selectedTier,
        email,
        tipAmount,
      });
      window.location.href = url;
    } catch (err) {
      console.error("❌ Purchase error:", err);
      toast.error("Payment failed. Please try again.");
    } finally {
      setIsProcessing(false);
    }
  }

  return { handlePurchase, isProcessing };
}
