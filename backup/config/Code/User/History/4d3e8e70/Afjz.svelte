<script lang="ts">
  import { onMount } from 'svelte';
  import type { PricingTier } from '../app.d.ts';
  import { PRICING_TIERS, TIP_OPTIONS } from '../lib/config.ts';

  let selectedTier: PricingTier | null = null;
  let tipAmount = 0;
  let customTip = 0;
  let isProcessing = false;

  const pricingTiers = PRICING_TIERS;
  const tipOptions = TIP_OPTIONS;

  function selectTier(tier: PricingTier) {
    selectedTier = tier;
  }

  function selectTip(amount: number) {
    tipAmount = amount;
    customTip = 0;
  }

  function handleCustomTip() {
    if (customTip > 0) {
      tipAmount = Math.round(customTip * 100); // Convert to cents
    }
  }

 function formatPrice(amount: number): string {
  return amount.toFixed(2); // ensures cents always show
}

  function getTotalAmount(): number {
    return selectedTier ? selectedTier.price + tipAmount : 0;
  }

  async function handlePurchase() {
    if (!selectedTier) return;

    isProcessing = true;

    try {
      const response = await fetch('/api/create-checkout-session', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          tier: selectedTier,
          tipAmount: tipAmount
        })
      });

      const { url } = await response.json();

      if (url) {
        window.location.href = url;
      }
    } catch (error) {
      console.error('Error creating checkout session:', error);
      alert('Something went wrong. Please try again.');
    } finally {
      isProcessing = false;
    }
  }
</script>

<svelte:head>
  <title>Surprise Artwork Shop - Discover Amazing Digital Art</title>
  <meta name="description" content="Purchase surprise digital artworks and discover amazing pieces from talented photographers around the world." />
</svelte:head>

<div class="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100">
  <!-- Header -->
  <header class="py-12 text-center">
    <h1 class="text-4xl md:text-6xl font-bold text-gray-900 mb-4">
      Surprise Artwork Shop
    </h1>
    <p class="text-xl text-gray-600 max-w-2xl mx-auto px-4">
      Discover beautiful, high-quality digital artworks curated just for you.
      Each purchase is a delightful surprise featuring stunning photography from around the world.
    </p>
  </header>

  <!-- Main Content -->
  <main class="max-w-7xl mx-auto px-4 pb-12">
    <!-- Pricing Tiers -->
    <section class="mb-12">
      <h2 class="text-3xl font-bold text-center text-gray-900 mb-8">Choose Your Surprise</h2>
      <div class="grid md:grid-cols-3 gap-8">
        {#each pricingTiers as tier}
          <div
            class="card p-8 cursor-pointer transition-all duration-300 hover:shadow-xl {selectedTier?.id === tier.id ? 'ring-2 ring-primary-500 shadow-xl' : ''}"
            on:click={() => selectTier(tier)}
            role="button"
            tabindex="0"
            on:keydown={(e) => e.key === 'Enter' && selectTier(tier)}
          >
            <div class="text-center mb-6">
              <h3 class="text-2xl font-bold text-gray-900 mb-2">{tier.name}</h3>
              <div class="text-4xl font-bold text-primary-600 mb-4">
                ${formatPrice(tier.price)}
              </div>
              <p class="text-gray-600">{tier.description}</p>
            </div>

            <ul class="space-y-3 mb-6">
              {#each tier.features as feature}
                <li class="flex items-center text-gray-700">
                  <svg class="w-5 h-5 text-green-500 mr-3" fill="currentColor" viewBox="0 0 20 20">
                    <path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd"/>
                  </svg>
                  {feature}
                </li>
              {/each}
            </ul>

            <button
              class="w-full btn-primary {selectedTier?.id === tier.id ? 'bg-primary-700' : ''}"
              on:click|stopPropagation={() => selectTier(tier)}
            >
              {selectedTier?.id === tier.id ? 'Selected' : 'Select'}
            </button>
          </div>
        {/each}
      </div>
    </section>

    <!-- Tip Section -->
    {#if selectedTier}
      <section class="card p-8 max-w-2xl mx-auto mb-8">
        <h3 class="text-2xl font-bold text-gray-900 mb-6 text-center">Add a Tip (Optional)</h3>
        <p class="text-gray-600 text-center mb-6">
          Support the amazing photographers who create these beautiful works of art!
        </p>

        <div class="grid grid-cols-4 gap-4 mb-6">
          {#each tipOptions as option}
            <button
              class="py-3 px-4 rounded-lg border-2 transition-all duration-200 {tipAmount === option ? 'border-primary-500 bg-primary-50 text-primary-700' : 'border-gray-200 hover:border-gray-300'}"
              on:click={() => selectTip(option)}
            >
              {option === 0 ? 'No tip' : `$${formatPrice(option)}`}
            </button>
          {/each}
        </div>

        <div class="flex items-center space-x-4">
          <label for="custom-tip" class="text-gray-700 font-medium">Custom tip:</label>
          <div class="flex items-center">
            <span class="text-gray-500 mr-1">$</span>
            <input
              id="custom-tip"
              type="number"
              min="0"
              step="0.01"
              placeholder="0.00"
              class="w-24 px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
              bind:value={customTip}
              on:input={handleCustomTip}
            />
          </div>
        </div>
      </section>

      <!-- Purchase Summary -->
      <section class="card p-8 max-w-lg mx-auto">
        <h3 class="text-2xl font-bold text-gray-900 mb-6 text-center">Purchase Summary</h3>

        <div class="space-y-4 mb-6">
          <div class="flex justify-between">
            <span class="text-gray-600">{selectedTier.name}</span>
            <span class="font-medium">${formatPrice(selectedTier.price)}</span>
          </div>

          {#if tipAmount > 0}
            <div class="flex justify-between">
              <span class="text-gray-600">Tip</span>
              <span class="font-medium">${formatPrice(tipAmount)}</span>
            </div>
          {/if}

          <hr class="border-gray-200">

          <div class="flex justify-between text-xl font-bold">
            <span>Total</span>
            <span class="text-primary-600">${formatPrice(getTotalAmount())}</span>
          </div>
        </div>

        <button
          class="w-full btn-primary text-lg py-4 disabled:opacity-50 disabled:cursor-not-allowed"
          disabled={isProcessing}
          on:click={handlePurchase}
        >
          {isProcessing ? 'Processing...' : 'Purchase Now'}
        </button>

        <p class="text-xs text-gray-500 text-center mt-4">
          Secure payment powered by Stripe. You'll receive your artwork immediately after payment.
        </p>
      </section>
    {/if}
  </main>
</div>
