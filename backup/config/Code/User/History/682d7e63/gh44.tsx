"use client";

import { useState } from "react";

export default function TransakWhiteLabel() {
  const [form, setForm] = useState({
    email: "",
    amount: "",
    crypto: "USDC",
    wallet: process.env.NEXT_PUBLIC_WALLET_ADDRESS || "",
  });

  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement>) => {
    const { name, value } = e.target;
    setForm(prev => ({ ...prev, [name]: value }));
  };

  const openTransak = () => {
    const baseUrl =
      process.env.NEXT_PUBLIC_ONRAMP_ENV === "PRODUCTION"
        ? "https://global.transak.com"
        : "https://global-stg.transak.com";

    const queryParams = new URLSearchParams({
      apiKey: process.env.NEXT_PUBLIC_ONRAMP_API_KEY!,
      walletAddress: form.wallet,
      fiatAmount: form.amount,
      fiatCurrency: "USD",
      cryptoCurrency: form.crypto,
      userData: JSON.stringify({
        email: form.email,
      }),
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
    <div style={{ maxWidth: 400, margin: "0 auto", padding: 20 }}>
      <h2>Buy Crypto (White Label)</h2>

      <label>Email:<br />
        <input
          type="email"
          name="email"
          value={form.email}
          onChange={handleChange}
          style={{ width: "100%", marginBottom: 10 }}
        />
      </label>

      <label>Amount (USD):<br />
        <input
          type="number"
          name="amount"
          value={form.amount}
          onChange={handleChange}
          style={{ width: "100%", marginBottom: 10 }}
        />
      </label>

      <label>Crypto:<br />
        <select
          name="crypto"
          value={form.crypto}
          onChange={handleChange}
          style={{ width: "100%", marginBottom: 10 }}
        >
          <option value="USDC">USDC</option>
          <option value="ETH">ETH</option>
          <option value="MATIC">MATIC</option>
        </select>
      </label>

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
        Buy via Transak
      </button>
    </div>
  );
}
