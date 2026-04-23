import { For } from "solid-js";

export default function Pricing() {
  const freeFeatures = [
    "Up to 3 vehicles",
    "Full service logging & scheduling",
    "Smart mileage estimation",
    "Cost tracking & reports",
    "All widgets (Home, Lock Screen, Watch, CarPlay)",
    "Siri Shortcuts",
    "NHTSA recall alerts",
    "iCloud sync",
    "PDF export",
    "CSV import (Fuelly, Drivvo, Simply Auto)",
    "Camera text scanning (odometer & receipts)",
    "Dynamic app icon",
    "Default theme (Checkpoint)",
  ];

  const proFeatures = [
    "Everything in Free",
    "Unlimited vehicles (4+)",
    "4 Pro themes (Clean Slate, Red Line, Blueprint, Terra)",
    "Future: AI-powered receipt auto-fill (included free for Pro owners)",
  ];

  return (
    <section
      id="pricing"
      class="section-padding"
      style={{ background: "var(--bg-primary)" }}
    >
      <div class="max-w-[1200px] mx-auto">
        {/* Header */}
        <div class="text-center mb-16">
          <h2
            class="text-3xl md:text-4xl font-light mb-4"
            style={{ color: "var(--text-primary)" }}
          >
            Full-featured. Free forever.
          </h2>
          <p
            class="text-sm"
            style={{ color: "rgba(245, 240, 220, 0.7)" }}
          >
            No ads. No data selling. No subscription required.
          </p>
        </div>

        {/* Cards */}
        <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
          {/* Free */}
          <div class="fade-in-on-scroll pricing-card">
            <div>
              <span
                class="text-2xl font-bold uppercase tracking-wider"
                style={{ color: "var(--text-primary)" }}
              >
                FREE
              </span>
            </div>
            <div>
              <span
                class="text-4xl font-light"
                style={{ color: "var(--text-primary)" }}
              >
                $0
              </span>
            </div>
            <p
              class="text-sm"
              style={{ color: "rgba(245, 240, 220, 0.6)" }}
            >
              Everything you need
            </p>
            <ul class="check-list flex flex-col gap-2 text-xs" style={{ color: "rgba(245, 240, 220, 0.7)" }}>
              <For each={freeFeatures}>
                {(feature) => <li>{feature}</li>}
              </For>
            </ul>
            <div class="mt-auto pt-4 text-center">
              <a href="#" class="btn-primary block text-center">
                Download Free
              </a>
            </div>
          </div>

          {/* Pro (Highlighted) */}
          <div class="fade-in-on-scroll pricing-card pricing-card-highlight">
            <div class="flex flex-col gap-2">
              <span class="badge badge-pro" style={{ "align-self": "flex-start" }}>
                ONE-TIME
              </span>
              <span
                class="text-2xl font-bold uppercase tracking-wider"
                style={{ color: "var(--text-primary)" }}
              >
                PRO
              </span>
            </div>
            <div class="flex items-baseline gap-3">
              <span
                class="text-4xl font-light"
                style={{ color: "var(--text-primary)" }}
              >
                $9.99
              </span>
              <span
                class="text-lg line-through"
                style={{ color: "rgba(245, 240, 220, 0.35)" }}
              >
                $14.99
              </span>
            </div>
            <p
              class="text-sm"
              style={{ color: "rgba(245, 240, 220, 0.6)" }}
            >
              Launch pricing — goes up when AI OCR ships
            </p>
            <ul class="check-list flex flex-col gap-2 text-xs" style={{ color: "rgba(245, 240, 220, 0.7)" }}>
              <For each={proFeatures}>
                {(feature) => <li>{feature}</li>}
              </For>
            </ul>
            <div class="mt-auto pt-4 text-center">
              <a href="#" class="btn-primary block text-center">
                Get Pro
              </a>
            </div>
          </div>

          {/* Tip Jar */}
          <div class="fade-in-on-scroll pricing-card">
            <div>
              <span
                class="text-2xl font-bold uppercase tracking-wider"
                style={{ color: "var(--text-primary)" }}
              >
                TIP JAR
              </span>
            </div>
            <div class="flex gap-3">
              <div
                class="flex-1 py-3 text-center"
                style={{
                  border: "2px solid rgba(245, 240, 220, 0.2)",
                  color: "var(--text-primary)",
                }}
              >
                <span class="text-lg font-light">$1.99</span>
              </div>
              <div
                class="flex-1 py-3 text-center"
                style={{
                  border: "2px solid rgba(245, 240, 220, 0.2)",
                  color: "var(--text-primary)",
                }}
              >
                <span class="text-lg font-light">$4.99</span>
              </div>
              <div
                class="flex-1 py-3 text-center"
                style={{
                  border: "2px solid rgba(245, 240, 220, 0.2)",
                  color: "var(--text-primary)",
                }}
              >
                <span class="text-lg font-light">$9.99</span>
              </div>
            </div>
            <p
              class="text-sm"
              style={{ color: "rgba(245, 240, 220, 0.6)" }}
            >
              Support development. Get something rare.
            </p>
            <p
              class="text-xs leading-relaxed"
              style={{ color: "rgba(245, 240, 220, 0.55)" }}
            >
              Each tip unlocks one random rare theme. Three to collect: Midnight
              Oil, Garage Day, and Stealth. You might get lucky on the first try.
            </p>

            {/* Theme Preview Circles */}
            <div class="flex gap-4 justify-center mt-4">
              <div
                class="w-12 h-12 flex items-center justify-center text-lg"
                style={{
                  background: "rgba(245, 240, 220, 0.08)",
                  border: "2px solid rgba(245, 240, 220, 0.15)",
                  color: "rgba(245, 240, 220, 0.4)",
                }}
              >
                ?
              </div>
              <div
                class="w-12 h-12 flex items-center justify-center text-lg"
                style={{
                  background: "rgba(245, 240, 220, 0.08)",
                  border: "2px solid rgba(245, 240, 220, 0.15)",
                  color: "rgba(245, 240, 220, 0.4)",
                }}
              >
                ?
              </div>
              <div
                class="w-12 h-12 flex items-center justify-center text-lg"
                style={{
                  background: "rgba(245, 240, 220, 0.08)",
                  border: "2px solid rgba(245, 240, 220, 0.15)",
                  color: "rgba(245, 240, 220, 0.4)",
                }}
              >
                ?
              </div>
            </div>

            <div class="mt-auto pt-4 text-center">
              <a href="#" class="btn-secondary block text-center">
                Leave a Tip
              </a>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}
