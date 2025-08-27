"use client";

import { useEffect } from "react";
import { useRouter, useSearchParams } from "next/navigation";

export default function SuccessPage() {
  const router = useRouter();
  const searchParams = useSearchParams();

  const amount = searchParams.get("amount");
  const email = searchParams.get("email");

  useEffect(() => {
    const formatted = amount
      ? `✅ Payment successful. Total paid: $${amount}`
      : "✅ Payment successful.";

    sessionStorage.setItem("toastMessage", formatted);
    router.replace("/");
  }, [amount, email, router]);

  return (
    <div className="min-h-screen flex items-center justify-center text-slate-500">
      Confirming your payment and redirecting...
    </div>
  );
}
