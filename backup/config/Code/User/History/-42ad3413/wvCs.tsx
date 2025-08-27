import dynamic from "next/dynamic";
import { Suspense } from "react";

// Dynamically import the actual page
const ClientCancelPage = dynamic(() => import("./client"), {
  ssr: false, // This disables server-side rendering for this component
});

export default function CancelPageWrapper() {
  return (
    <Suspense fallback={<div className="min-h-screen flex items-center justify-center text-slate-500">Loading...</div>}>
      <ClientCancelPage />
    </Suspense>
  );
}
