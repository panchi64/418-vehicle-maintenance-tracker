import { A } from "@solidjs/router";

export default function Footer() {
  return (
    <footer
      class="section-padding"
      style={{ background: "var(--bg-primary)", "padding-bottom": "40px" }}
    >
      <div class="max-w-[1200px] mx-auto grid grid-cols-1 md:grid-cols-3 gap-12 mb-24">
        {/* Column 1 — Brand */}
        <div class="flex flex-col gap-4">
          <div class="flex items-center gap-3">
            <img
              src="/418-checkpoint-app-icon-v1.avif"
              alt="Checkpoint app icon"
              class="w-16 h-16"
            />
          </div>
          <span class="label-lg" style={{ color: "var(--text-primary)" }}>
            CHECKPOINT
          </span>
          <p
            class="text-xs"
            style={{ color: "rgba(245, 240, 220, 0.5)" }}
          >
            Built by Francisco Casiano in Puerto Rico
          </p>
          <p
            class="text-xs"
            style={{ color: "rgba(245, 240, 220, 0.4)" }}
          >
            © 2026 Francisco Casiano. All rights reserved.
          </p>
        </div>

        {/* Column 2 — Links */}
        <div class="flex flex-col gap-3">
          <span class="label mb-2" style={{ color: "rgba(245, 240, 220, 0.5)" }}>
            LINKS
          </span>
          <A
            href="/privacy-policy"
            class="text-sm hover:underline"
            style={{
              color: "var(--text-primary)",
              "text-decoration": "none",
              "text-underline-offset": "4px",
            }}
          >
            Privacy Policy
          </A>
          <A
            href="/terms"
            class="text-sm hover:underline"
            style={{
              color: "var(--text-primary)",
              "text-decoration": "none",
              "text-underline-offset": "4px",
            }}
          >
            Terms of Service
          </A>
          <A
            href="/press-kit"
            class="text-sm hover:underline"
            style={{
              color: "var(--text-primary)",
              "text-decoration": "none",
              "text-underline-offset": "4px",
            }}
          >
            Press Kit
          </A>
          <A
            href="/support"
            class="text-sm hover:underline"
            style={{
              color: "var(--text-primary)",
              "text-decoration": "none",
              "text-underline-offset": "4px",
            }}
          >
            Support / Contact
          </A>
        </div>

        {/* Column 3 — Download */}
        <div class="flex flex-col gap-4">
          <span class="label mb-2" style={{ color: "rgba(245, 240, 220, 0.5)" }}>
            DOWNLOAD
          </span>
          <a href="#">
            <img
              src="/Download_on_the_App_Store_Badge.svg"
              alt="Download on the App Store"
              class="h-16"
            />
          </a>
          <p
            class="text-xs"
            style={{ color: "rgba(245, 240, 220, 0.5)" }}
          >
            Requires iOS 17.0 or later
          </p>
          <p
            class="text-xs"
            style={{ color: "rgba(245, 240, 220, 0.4)" }}
          >
            Also available on Apple Watch
          </p>
        </div>
      </div>

      {/* Bottom divider */}
      <hr class="section-divider" />
      <div class="max-w-[1200px] mx-auto flex flex-col md:flex-row justify-between items-center gap-4 mt-12">
        <p
          class="text-xs"
          style={{ color: "rgba(245, 240, 220, 0.3)" }}
        >
          Apple, iPhone, Apple Watch, and CarPlay are trademarks of Apple Inc.
        </p>
      </div>
    </footer>
  );
}
