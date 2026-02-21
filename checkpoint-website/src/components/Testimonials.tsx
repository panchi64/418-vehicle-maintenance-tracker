import { For } from "solid-js";

const reviews = [
  {
    quote:
      "I opened it once to add my car and now I just glance at the widget. That's the whole point.",
    name: "Alex R.",
    vehicle: "2019 Honda Civic",
  },
  {
    quote:
      "The notifications genuinely made me laugh. My truck told me it was concerned.",
    name: "Jordan M.",
    vehicle: "2021 Ford F-150",
  },
  {
    quote:
      "Switched from Drivvo. Imported everything in 30 seconds. The design isn't even comparable.",
    name: "Sam K.",
    vehicle: "2020 Toyota Camry",
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
          What drivers are saying.
        </h2>

        <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
          <For each={reviews}>
            {(review) => (
              <div
                class="fade-in-on-scroll flex flex-col gap-6 p-8"
                style={{
                  border: "2px solid rgba(245, 240, 220, 0.15)",
                }}
              >
                {/* Stars */}
                <div class="flex gap-1 text-lg star">★★★★★</div>

                {/* Quote */}
                <p
                  class="text-sm leading-relaxed italic flex-1"
                  style={{ color: "rgba(245, 240, 220, 0.8)" }}
                >
                  "{review.quote}"
                </p>

                {/* Attribution */}
                <div>
                  <p
                    class="text-xs font-bold"
                    style={{ color: "var(--text-primary)" }}
                  >
                    — {review.name}
                  </p>
                  <p
                    class="text-xs"
                    style={{ color: "rgba(245, 240, 220, 0.45)" }}
                  >
                    {review.vehicle}
                  </p>
                </div>
              </div>
            )}
          </For>
        </div>
      </div>
    </section>
  );
}
