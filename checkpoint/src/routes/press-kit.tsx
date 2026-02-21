import { Title, Meta } from "@solidjs/meta";
import Navbar from "~/components/Navbar";
import Footer from "~/components/Footer";

export default function PressKit() {
  return (
    <>
      <Title>Press Kit — Checkpoint</Title>
      <Meta name="description" content="Checkpoint press kit. App summary, facts, screenshots, and brand assets for media." />

      <div class="frame">
        <Navbar />
        <main
          class="section-padding"
          style={{ background: "var(--bg-primary)", "padding-top": "140px" }}
        >
          <div class="max-w-[900px] mx-auto">
            {/* Header */}
            <h1
              class="text-3xl md:text-4xl font-light mb-2"
              style={{ color: "var(--text-primary)" }}
            >
              Press Kit
            </h1>
            <p
              class="text-sm mb-16"
              style={{ color: "rgba(245, 240, 220, 0.4)" }}
            >
              Last updated February 15, 2026
            </p>

            {/* App Summary */}
            <section class="mb-16">
              <h2
                class="label-lg mb-6"
                style={{ color: "rgba(245, 240, 220, 0.5)" }}
              >
                ABOUT CHECKPOINT
              </h2>
              <p
                class="text-base leading-relaxed mb-4"
                style={{ color: "rgba(245, 240, 220, 0.8)" }}
              >
                Checkpoint is a vehicle maintenance tracker for iPhone and Apple Watch. It helps
                drivers stay on top of oil changes, tire rotations, brake inspections, and every
                other service their vehicles need — with smart reminders, cost tracking, and a
                clean interface designed to get out of the way.
              </p>
              <p
                class="text-base leading-relaxed"
                style={{ color: "rgba(245, 240, 220, 0.8)" }}
              >
                No account required. No ads. All data stays on-device with iCloud sync.
                Built by Francisco Casiano in Puerto Rico.
              </p>
            </section>

            {/* Quick Facts */}
            <section class="mb-16">
              <h2
                class="label-lg mb-6"
                style={{ color: "rgba(245, 240, 220, 0.5)" }}
              >
                QUICK FACTS
              </h2>
              <div class="grid grid-cols-1 sm:grid-cols-2 gap-px" style={{ background: "rgba(245, 240, 220, 0.1)" }}>
                {[
                  { label: "Developer", value: "Francisco Casiano" },
                  { label: "Location", value: "Puerto Rico" },
                  { label: "Platform", value: "iOS 17.0+" },
                  { label: "Devices", value: "iPhone, Apple Watch, CarPlay" },
                  { label: "Price", value: "Free (Pro upgrade available)" },
                  { label: "Category", value: "Utilities / Automotive" },
                  { label: "Languages", value: "English, Spanish" },
                  { label: "Data", value: "On-device + iCloud sync" },
                ].map((fact) => (
                  <div
                    class="flex flex-col gap-1 p-4"
                    style={{ background: "var(--bg-primary)" }}
                  >
                    <span
                      class="label"
                      style={{ color: "rgba(245, 240, 220, 0.4)" }}
                    >
                      {fact.label}
                    </span>
                    <span
                      class="text-sm font-medium"
                      style={{ color: "var(--text-primary)" }}
                    >
                      {fact.value}
                    </span>
                  </div>
                ))}
              </div>
            </section>

            {/* Screenshots */}
            <section class="mb-16">
              <h2
                class="label-lg mb-6"
                style={{ color: "rgba(245, 240, 220, 0.5)" }}
              >
                SCREENSHOTS
              </h2>
              <div class="grid grid-cols-2 md:grid-cols-4 gap-4">
                {["Dashboard", "Service Log", "Reminders", "Apple Watch"].map((name) => (
                  <div class="mockup-placeholder" style={{ "min-height": "360px", width: "100%" }}>
                    {name}
                  </div>
                ))}
              </div>
              <p
                class="text-xs mt-4"
                style={{ color: "rgba(245, 240, 220, 0.4)" }}
              >
                High-resolution screenshots available upon request.
              </p>
            </section>

            {/* Brand Assets */}
            <section class="mb-16">
              <h2
                class="label-lg mb-6"
                style={{ color: "rgba(245, 240, 220, 0.5)" }}
              >
                BRAND ASSETS
              </h2>
              <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div
                  class="flex flex-col items-center justify-center gap-4 p-8"
                  style={{
                    background: "rgba(245, 240, 220, 0.04)",
                    border: "2px solid rgba(245, 240, 220, 0.1)",
                    "min-height": "200px",
                  }}
                >
                  <img
                    src="/418-checkpoint-app-icon-v1.avif"
                    alt="Checkpoint app icon"
                    class="w-20 h-20"
                  />
                  <span
                    class="label"
                    style={{ color: "rgba(245, 240, 220, 0.4)" }}
                  >
                    APP ICON
                  </span>
                </div>
                <div
                  class="flex flex-col items-center justify-center gap-4 p-8"
                  style={{
                    background: "rgba(245, 240, 220, 0.04)",
                    border: "2px solid rgba(245, 240, 220, 0.1)",
                    "min-height": "200px",
                  }}
                >
                  <span
                    class="label-lg tracking-widest"
                    style={{ color: "var(--text-primary)", "font-size": "24px" }}
                  >
                    CHECKPOINT
                  </span>
                  <span
                    class="label"
                    style={{ color: "rgba(245, 240, 220, 0.4)" }}
                  >
                    WORDMARK
                  </span>
                </div>
              </div>
              <p
                class="text-xs mt-4"
                style={{ color: "rgba(245, 240, 220, 0.4)" }}
              >
                Please do not modify, recolor, or distort the Checkpoint logo or wordmark.
                Vector files available upon request.
              </p>
            </section>

            {/* Brand Colors */}
            <section class="mb-16">
              <h2
                class="label-lg mb-6"
                style={{ color: "rgba(245, 240, 220, 0.5)" }}
              >
                BRAND COLORS
              </h2>
              <div class="grid grid-cols-2 sm:grid-cols-4 gap-4">
                {[
                  { name: "Primary Blue", hex: "#0033BE" },
                  { name: "Cream", hex: "#F5F0DC" },
                  { name: "Status Good", hex: "#38D9A9" },
                  { name: "Dark", hex: "#0A0A0A" },
                ].map((color) => (
                  <div class="flex flex-col gap-2">
                    <div
                      class="w-full aspect-square"
                      style={{
                        background: color.hex,
                        border: "2px solid rgba(245, 240, 220, 0.15)",
                      }}
                    />
                    <span
                      class="label"
                      style={{ color: "rgba(245, 240, 220, 0.5)" }}
                    >
                      {color.name}
                    </span>
                    <span
                      class="text-xs font-mono"
                      style={{ color: "rgba(245, 240, 220, 0.4)" }}
                    >
                      {color.hex}
                    </span>
                  </div>
                ))}
              </div>
            </section>

            {/* Contact */}
            <section>
              <h2
                class="label-lg mb-6"
                style={{ color: "rgba(245, 240, 220, 0.5)" }}
              >
                MEDIA CONTACT
              </h2>
              <p
                class="text-sm leading-relaxed"
                style={{ color: "rgba(245, 240, 220, 0.8)" }}
              >
                For press inquiries, review copies, interview requests, or high-resolution assets,
                contact us at{" "}
                <a
                  href="mailto:support@franciscocasiano.com"
                  style={{
                    color: "var(--text-primary)",
                    "text-decoration": "underline",
                    "text-underline-offset": "4px",
                  }}
                >
                  support@franciscocasiano.com
                </a>.
              </p>
            </section>
          </div>
        </main>
        <Footer />
      </div>
    </>
  );
}
