export default function Hero() {
  return (
    <section
      class="min-h-screen flex items-center justify-center px-6 pt-32 pb-20 lg:pt-0 lg:pb-0 relative"
      style={{ background: "var(--bg-primary)" }}
    >
      <div class="max-w-[1200px] mx-auto grid grid-cols-1 lg:grid-cols-2 gap-8 lg:gap-16 items-center w-full">
        {/* Text Column */}
        <div class="flex flex-col gap-6 lg:gap-8 text-center lg:text-left items-center lg:items-start">
          <span class="label" style={{ color: "rgba(245, 240, 220, 0.6)" }}>
            VEHICLE MAINTENANCE TRACKER
          </span>

          <h1
            class="text-5xl md:text-6xl lg:text-7xl font-light leading-tight"
            style={{ color: "var(--text-primary)" }}
          >
            Know what's next.
          </h1>

          <p
            class="text-base md:text-lg max-w-[600px] leading-relaxed"
            style={{ color: "rgba(245, 240, 220, 0.8)" }}
          >
            Checkpoint tells you what your vehicle needs before you have to ask.
            Track services, costs, and schedules — all in one place. No
            subscriptions. No ads. Just clarity.
          </p>

          <div class="flex flex-col sm:flex-row items-center gap-4 mt-4">
            <a href="#">
              <img
                src="/Download_on_the_App_Store_Badge.svg"
                alt="Download on the App Store"
                class="h-14 sm:h-16"
              />
            </a>
            <a
              href="#features"
              class="btn-secondary !flex items-center justify-center h-14 sm:h-16 px-8 box-border text-xs sm:text-sm"
              onClick={(e) => {
                e.preventDefault();
                document.getElementById("features")?.scrollIntoView({ behavior: "smooth" });
              }}
            >
              See Features
            </a>
          </div>
        </div>

        {/* Mockup Column */}
        <div class="flex justify-center lg:justify-end">
          <img
            src="/home-screen-iphone.avif"
            alt="Checkpoint app home screen showing vehicle dashboard with Next Up card and odometer"
            class="w-[300px] sm:w-[400px] lg:w-[800px] max-w-full"
          />
        </div>
      </div>

      {/* Scroll chevron */}
      <button
        onClick={() => {
          document.getElementById("features")?.scrollIntoView({ behavior: "smooth" });
        }}
        class="absolute bottom-8 left-1/2 bg-transparent border-none cursor-pointer hero-chevron"
        style={{
          transform: "translateX(-50%)",
          color: "rgba(245, 240, 220, 0.4)",
        }}
        aria-label="Scroll down"
      >
        <svg
          width="24"
          height="24"
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
          stroke-width="2"
          stroke-linecap="square"
        >
          <path d="M6 9l6 6 6-6" />
        </svg>
      </button>
    </section>
  );
}
