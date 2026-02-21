export default function FinalCTA() {
  return (
    <section
      class="flex flex-col items-center justify-center text-center px-6"
      style={{
        background: "var(--bg-primary)",
        "padding-top": "100px",
        "padding-bottom": "100px",
      }}
    >
      <div class="max-w-225 flex flex-col items-center gap-8">
        <h2
          class="fade-in-on-scroll font-light leading-tight"
          style={{ color: "var(--text-primary)" }}
        >
          <span class="block text-3xl md:text-4xl lg:text-5xl">
            Maintenance is inevitable
          </span>
          <span
            class="block text-xl md:text-2xl lg:text-3xl mt-4"
            style={{ color: "rgba(245, 240, 220, 0.7)" }}
          >
            Forgetting about it doesn't have to be
          </span>
        </h2>

        <p
          class="fade-in-on-scroll text-sm"
          style={{ color: "rgba(245, 240, 220, 0.7)" }}
        >
          Free on the App Store. No account required.
        </p>

        <a href="#" class="fade-in-on-scroll">
          <img
            src="/Download_on_the_App_Store_Badge.svg"
            alt="Download on the App Store"
            class="h-16"
          />
        </a>
      </div>
    </section>
  );
}
