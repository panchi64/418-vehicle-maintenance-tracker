export default function Privacy() {
  return (
    <section
      class="section-padding"
      style={{ background: "var(--bg-primary)" }}
    >
      <div class="max-w-[700px] mx-auto">
        <h2
          class="fade-in-on-scroll text-3xl md:text-4xl font-light mb-12 text-center"
          style={{ color: "var(--text-primary)" }}
        >
          Your data stays yours.
        </h2>

        <div class="flex flex-col gap-8">
          <div class="fade-in-on-scroll">
            <p
              class="text-sm leading-relaxed"
              style={{ color: "rgba(245, 240, 220, 0.8)" }}
            >
              <strong style={{ color: "var(--text-primary)" }}>Local-first.</strong>{" "}
              Your data lives on your device and syncs through your iCloud
              account. We never see it. We never store it. There is no account
              to create.
            </p>
          </div>

          <div class="fade-in-on-scroll">
            <p
              class="text-sm leading-relaxed"
              style={{ color: "rgba(245, 240, 220, 0.8)" }}
            >
              <strong style={{ color: "var(--text-primary)" }}>No ads. Ever.</strong>{" "}
              Checkpoint will never show advertisements. The app is funded by Pro
              purchases and tips, not by selling your attention.
            </p>
          </div>

          <div class="fade-in-on-scroll">
            <p
              class="text-sm leading-relaxed"
              style={{ color: "rgba(245, 240, 220, 0.8)" }}
            >
              <strong style={{ color: "var(--text-primary)" }}>
                Privacy-respecting analytics.
              </strong>{" "}
              We use PostHog to understand how features are used — no
              personal data is collected, and you can opt out entirely in
              Settings.
            </p>
          </div>

          <div class="fade-in-on-scroll">
            <p
              class="text-sm leading-relaxed"
              style={{ color: "rgba(245, 240, 220, 0.8)" }}
            >
              <strong style={{ color: "var(--text-primary)" }}>No tracking.</strong>{" "}
              No third-party SDKs phoning home. No data brokers. Your vehicle
              information, service history, and spending data never leave your
              device except through iCloud.
            </p>
          </div>
        </div>
      </div>
    </section>
  );
}
