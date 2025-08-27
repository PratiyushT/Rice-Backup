"use client";

import { useState } from "react";
import { Button } from "@/components/ui/button";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Checkbox } from "@/components/ui/checkbox";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { toast } from "sonner";

import { artworkTiers, ArtworkTier } from "@libs/data/artworkTiers";
import { tipOptions } from "@libs/data/tipOptions";
import { usePurchase } from "@libs/hooks/usePurchase";
import { useSearchParams } from "next/navigation";


export default function Home() {
  const [selectedTier, setSelectedTier] = useState<string>(defaultTier || "");
  const defaultTier = searchParams.get("tier");
  const [email, setEmail] = useState("");
  const [tip, setTip] = useState("0");
  const [customTip, setCustomTip] = useState("");
  const [agreeToTerms, setAgreeToTerms] = useState(false);
  const searchParams = useSearchParams();


  const selectedArtwork = artworkTiers.find((tier) => tier.id === selectedTier);
  const tipAmount =
    tip === "custom" ? parseFloat(customTip) || 0 : parseFloat(tip);
  const totalAmount = (selectedArtwork?.price || 0) + tipAmount;

  const { handlePurchase, isProcessing } = usePurchase();

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-50 to-slate-100 dark:from-slate-900 dark:to-slate-800">
      {/* Header */}
      <header className="relative overflow-hidden bg-gradient-to-r from-slate-900 via-purple-900 to-slate-900 text-white">
        <div className="absolute inset-0 opacity-20">
          <div
            className="w-full h-full bg-repeat"
            style={{
              backgroundImage: `url("data:image/svg+xml,%3Csvg width='60' height='60' viewBox='0 0 60 60' xmlns='http://www.w3.org/2000/svg'%3E%3Cg fill='none' fill-rule='evenodd'%3E%3Cg fill='%239C92AC' fill-opacity='0.1'%3E%3Ccircle cx='30' cy='30' r='2'/%3E%3C/g%3E%3C/g%3E%3C/svg%3E")`,
            }}
          ></div>
        </div>
        <div className="relative container mx-auto px-6 py-16">
          <div className="text-center">
            <h1 className="text-5xl font-bold mb-4 bg-gradient-to-r from-white to-purple-200 bg-clip-text text-transparent">
              Mystery Artwork Collection
            </h1>
            <p className="text-xl text-purple-100 max-w-2xl mx-auto">
              Discover extraordinary art from talented artists around the world.
              Each mystery box contains a unique piece waiting to inspire you.
            </p>
          </div>
        </div>
      </header>

      {/* Main Content */}
      <main className="container mx-auto px-6 py-12">
        <div className="max-w-6xl mx-auto">
          {/* Artwork Tiers */}
          <section className="mb-12">
            <h2 className="text-3xl font-bold text-center mb-8 text-slate-800 dark:text-slate-200">
              Choose Your Mystery Artwork
            </h2>
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
              {artworkTiers.map((tier) => (
                <Card
                  key={tier.id}
                  className={`cursor-pointer transition-all duration-300 hover:shadow-lg hover:-translate-y-1 ${
                    selectedTier === tier.id
                      ? "ring-2 ring-purple-600 shadow-lg transform -translate-y-1"
                      : "hover:ring-1 hover:ring-purple-300"
                  }`}
                  onClick={() => setSelectedTier(tier.id)}
                >
                  <CardHeader className="text-center">
                    <div className="w-16 h-16 mx-auto mb-4 rounded-full bg-gradient-to-r from-purple-600 to-pink-600 flex items-center justify-center text-white font-bold text-xl">
                      ${tier.price}
                    </div>
                    <CardTitle className="text-xl">{tier.title}</CardTitle>
                    <CardDescription>{tier.description}</CardDescription>
                  </CardHeader>
                  <CardContent>
                    <ul className="space-y-2 text-sm">
                      {tier.features.map((feature, index) => (
                        <li key={index} className="flex items-center">
                          <div className="w-2 h-2 bg-purple-600 rounded-full mr-3 flex-shrink-0"></div>
                          {feature}
                        </li>
                      ))}
                    </ul>
                  </CardContent>
                </Card>
              ))}
            </div>
          </section>

          {/* Purchase Form */}
          {selectedTier && (
            <section className="max-w-2xl mx-auto">
              <Card className="shadow-xl">
                <CardHeader>
                  <CardTitle className="text-2xl text-center">
                    Complete Your Purchase
                  </CardTitle>
                  <CardDescription className="text-center">
                    You selected: <strong>{selectedArtwork?.title}</strong> - $
                    {selectedArtwork?.price}
                  </CardDescription>
                </CardHeader>
                <CardContent className="space-y-6">
                  {/* Email Input */}
                  <div className="space-y-2">
                    <Label htmlFor="email">Delivery Email Address</Label>
                    <Input
                      id="email"
                      type="email"
                      placeholder="your@email.com"
                      value={email}
                      onChange={(e) => setEmail(e.target.value)}
                      className="w-full"
                    />
                  </div>

                  {/* Tip Selection */}
                  <div className="space-y-2">
                    <Label htmlFor="tip">Add a Tip (Optional)</Label>
                    <Select value={tip} onValueChange={setTip}>
                      <SelectTrigger>
                        <SelectValue placeholder="Select tip amount" />
                      </SelectTrigger>
                      <SelectContent>
                        {tipOptions.map((option) => (
                          <SelectItem key={option.value} value={option.value}>
                            {option.label}
                          </SelectItem>
                        ))}
                      </SelectContent>
                    </Select>

                    {tip === "custom" && (
                      <div className="mt-2">
                        <Input
                          type="number"
                          placeholder="Enter custom tip amount"
                          value={customTip}
                          onChange={(e) => setCustomTip(e.target.value)}
                          min="0"
                          step="0.01"
                        />
                      </div>
                    )}
                  </div>

                  {/* Terms and Conditions */}
                  <div className="flex items-center space-x-2">
                    <Checkbox
                      id="terms"
                      checked={agreeToTerms}
                      onCheckedChange={(checked) =>
                        setAgreeToTerms(checked as boolean)
                      }
                    />
                    <Label htmlFor="terms" className="text-sm">
                      I agree to the{" "}
                      <button
                        type="button"
                        className="text-purple-600 hover:underline"
                      >
                        Terms and Conditions
                      </button>
                    </Label>
                  </div>

                  {/* Order Summary */}
                  <div className="bg-slate-50 dark:bg-slate-800 p-4 rounded-lg space-y-2">
                    <div className="flex justify-between">
                      <span>Artwork ({selectedArtwork?.title})</span>
                      <span>${selectedArtwork?.price}</span>
                    </div>
                    {tipAmount > 0 && (
                      <div className="flex justify-between text-sm text-slate-600 dark:text-slate-400">
                        <span>Tip</span>
                        <span>${tipAmount.toFixed(2)}</span>
                      </div>
                    )}
                    <hr className="my-2" />
                    <div className="flex justify-between font-bold text-lg">
                      <span>Total</span>
                      <span>${totalAmount.toFixed(2)}</span>
                    </div>
                  </div>

                  {/* Purchase Button */}
                  <Button
                    onClick={() =>
                      handlePurchase({
                        selectedTier: artworkTiers.find((t) => t.id === selectedTier),
                        email,
                        tip,
                        customTip,
                        agreeToTerms,
                      })
                    }
                    disabled={isProcessing}
                    className="w-full bg-gradient-to-r from-purple-600 to-pink-600 hover:from-purple-700 hover:to-pink-700 text-white font-semibold py-3 text-lg"
                  >
                    {isProcessing
                      ? "Processing..."
                      : `Purchase Mystery Artwork - $${totalAmount.toFixed(2)}`}
                  </Button>

                  <p className="text-xs text-center text-slate-500">
                    🔒 This is a development environment. All payments are
                    automatically approved.
                  </p>
                </CardContent>
              </Card>
            </section>
          )}
        </div>
      </main>

      {/* Footer */}
      <footer className="bg-slate-900 text-white py-8 mt-16">
        <div className="container mx-auto px-6 text-center">
          <p className="text-slate-400">
            © 2024 Mystery Artwork Collection. Discover the extraordinary.
          </p>
        </div>
      </footer>
    </div>
  );
}
