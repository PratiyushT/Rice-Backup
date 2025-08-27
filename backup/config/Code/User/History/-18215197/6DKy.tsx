"use client";

import { useEffect } from "react";
import { useSearchParams, useRouter } from "next/navigation";

export default function ClientCancelPage() {
  const searchParams = useSearchParams();
  const router = useRouter();

  const tier = searchParams.get("tier");
  const tierName = searchParams.get("tierName");
  const tierPrice = searchParams.get("tierPrice");

  useEffect(() => {
    const label = tierName && tierPrice ? `${tierName} ($${tierPrice})` : null;

    sessionStorage.setItem(
      "toastMessage",
      label
        ? `⚠️ Payment cancelled. Tier preserved: ${label}`
        : "⚠️ Payment was cancelled."
    );

    const redirectTo = tier ? `/?tier=${tier}` : "/";
    router.replace(redirectTo);
  }, [tier, tierName, tierPrice, router]);

  return (
    <div className="min-h-screen flex items-center justify-center text-slate-500">
      Redirecting back to your artwork...
    </div>
  );
}
