"use client";

import { useEffect } from "react";
import { useSearchParams, useRouter } from "next/navigation";

export default function CancelPage() {
  const searchParams = useSearchParams();
  const router = useRouter();
  const tier = searchParams.get("tier");

  useEffect(() => {
    const redirectTo = tier ? `/?tier=${tier}` : "/";
    router.replace(redirectTo);
  }, [tier, router]);

  return (
    <div className="min-h-screen flex items-center justify-center text-slate-500">
      Redirecting back to your artwork...
    </div>
  );
}
