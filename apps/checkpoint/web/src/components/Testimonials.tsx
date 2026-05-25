import { For } from "solid-js";

const reasons = [
  {
    stat: "0",
    unit: "ADS",
    body: "No banners. No interstitials. No sponsored service recommendations. The app works for you, not advertisers.",
  },
  {
    stat: "6",
    unit: "SURFACES",
    body: "Home Screen, Lock Screen, Apple Watch, CarPlay, Siri, and interactive widgets. No competitor covers all six.",
  },
  {
    stat: "1",
    unit: "PAYMENT",
    body: "One-time Pro purchase. No monthly subscription for core features. No price hikes after you're hooked.",
  },
];

export default function Testimonials() {
  return (
    <section
      class="section-padding"
      style={{ background: "var(--bg-elevated)" }}
    >
      <div class="max-w-[1200px] mx-auto">
        <h2
          class="fade-in-on-scroll text-3xl md:text-4xl font-light mb-16 text-center"
          style={{ color: "var(--text-primary)" }}
        >
          Why drivers switch.
        </h2>

        <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
          <For each={reasons}>
            {(reason) => (
              <div
                class="fade-in-on-scroll flex flex-col gap-6 p-8"
                style={{
                  border: "2px solid rgba(245, 240, 220, 0.15)",
                }}
              >
                {/* Stat */}
                <div class="flex items-baseline gap-2">
                  <span
                    class="text-4xl font-light"
                    style={{ color: "var(--text-primary)" }}
                  >
                    {reason.stat}
                  </span>
                  <span
                    class="label"
                    style={{ color: "rgba(245, 240, 220, 0.45)" }}
                  >
                    {reason.unit}
                  </span>
                </div>

                {/* Body */}
                <p
                  class="text-sm leading-relaxed flex-1"
                  style={{ color: "rgba(245, 240, 220, 0.75)" }}
                >
                  {reason.body}
                </p>
              </div>
            )}
          </For>
        </div>
      </div>
    </section>
  );
}
