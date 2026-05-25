import { For } from "solid-js";

interface Theme {
  name: string;
  slug: string;
  description: string;
  badge: "FREE" | "PRO" | "RARE";
}

const themes: Theme[] = [
  { name: "Checkpoint", slug: "checkpoint", description: "Cerulean blue depths, cream instrumentation", badge: "FREE" },
  { name: "Clean Slate", slug: "clean-slate", description: "Cool gray light mode, rounded and minimal", badge: "PRO" },
  { name: "Red Line", slug: "red-line", description: "Black and crimson, aggressive", badge: "PRO" },
  { name: "Blueprint", slug: "blueprint", description: "Navy with engineering blue gridlines", badge: "PRO" },
  { name: "Terra", slug: "terra", description: "Warm earthy tones, organic", badge: "PRO" },
  { name: "Midnight Oil", slug: "midnight-oil", description: "Purple-black with electric blue glow", badge: "RARE" },
  { name: "Garage Day", slug: "garage-day", description: "Warm workshop amber, light mode", badge: "RARE" },
  { name: "Stealth", slug: "stealth", description: "Pure OLED black with gunmetal", badge: "RARE" },
];

const badgeClass = (badge: Theme["badge"]) => {
  switch (badge) {
    case "FREE": return "badge badge-free";
    case "PRO": return "badge badge-pro";
    case "RARE": return "badge badge-rare";
  }
};

export default function ThemesGallery() {
  return (
    <section
      class="section-padding"
      style={{ background: "var(--bg-dark)" }}
    >
      <div class="max-w-[1200px] mx-auto">
        {/* Header */}
        <div class="text-center mb-16">
          <h2
            class="text-3xl md:text-4xl font-light mb-4"
            style={{ color: "var(--text-primary)" }}
          >
            Eight ways to see your data.
          </h2>
          <p
            class="text-sm"
            style={{ color: "rgba(245, 240, 220, 0.6)" }}
          >
            One free. Four with Pro. Three hidden in the tip jar.
          </p>
        </div>

        {/* Grid */}
        <div class="grid grid-cols-2 md:grid-cols-4 gap-4 md:gap-6">
          <For each={themes}>
            {(theme) => (
              <div class="fade-in-on-scroll theme-tile">
                <img
                  src={`/screenshots/${theme.slug}.avif`}
                  alt={`${theme.name} theme screenshot`}
                  class="w-full aspect-[9/16] object-cover"
                />
                <div class="w-full flex flex-col gap-2">
                  <div class="flex items-center justify-between gap-2">
                    <span
                      class="text-xs font-bold uppercase tracking-wider"
                      style={{ color: "var(--text-primary)" }}
                    >
                      {theme.name}
                    </span>
                    <span class={badgeClass(theme.badge)}>{theme.badge}</span>
                  </div>
                  <p
                    class="text-xs"
                    style={{ color: "rgba(245, 240, 220, 0.45)" }}
                  >
                    {theme.description}
                  </p>
                </div>
              </div>
            )}
          </For>
        </div>

        {/* Note */}
        <p
          class="text-center mt-12 text-xs"
          style={{ color: "rgba(245, 240, 220, 0.4)" }}
        >
          Pro themes unlock with a one-time purchase. Rare themes are unlocked
          randomly through the tip jar — one per tip.
        </p>
      </div>
    </section>
  );
}
