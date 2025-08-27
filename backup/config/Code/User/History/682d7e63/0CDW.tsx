"use client";

import { useEffect } from "react";

export default function TransakWhiteLabel({
  email,
  amount,
  crypto,
}: {
  email: string;
  amount: number;
  crypto: string;
}) {
  useEffect(() => {
    if (typeof window !== "undefined") {
      import("@transak/transak-sdk");
    }
  }, []);

  const openTransak = () => {
    const baseUrl =
      process.env.NEXT_PUBLIC_ONRAMP_ENV === "PRODUCTION"
        ? "https://global.transak.com"
        : "https://global-stg.transak.com";

    const queryParams = new URLSearchParams({
      apiKey: process.env.NEXT_PUBLIC_ONRAMP_API_KEY!,
      walletAddress: process.env.NEXT_PUBLIC_WALLET_ADDRESS!,
      fiatAmount: amount.toString(),
      fiatCurrency: "USD",
      cryptoCurrency: crypto,
      userData: JSON.stringify({ email }),
      productsAvailed: "BUY",
      hideExchangeScreen: "true",
      hideWalletAddressForm: "true",
      hideEmailForm: "true",
      isFeeCalculationHidden: "true",
      themeColor: "000000",
    });

    const transakUrl = `${baseUrl}?${queryParams.toString()}`;
    window.open(transakUrl, "_blank", "width=500,height=700");
  };

  return (
    <button
      onClick={openTransak}
      style={{
        padding: "12px 24px",
        background: "#111",
        color: "#fff",
        border: "none",
        borderRadius: "8px",
        cursor: "pointer",
        width: "100%",
      }}
    >
      Complete Purchase via Transak
    </button>
  );
}
