export default function ValueProps() {
  const props = [
    {
      index: "01",
      title: "WHAT'S DUE NEXT",
      body: "Open the app and know instantly. Checkpoint surfaces your most urgent service the moment you look.",
    },
    {
      index: "02",
      title: "WHAT IT COSTS",
      body: "Track every dollar across maintenance, repairs, and upgrades. Monthly and yearly breakdowns with cost-per-mile.",
    },
    {
      index: "03",
      title: "WHEN TO ACT",
      body: "Smart reminders by date and mileage. Checkpoint estimates your driving patterns and notifies you before anything is overdue.",
    },
  ];

  return (
    <section
      class="section-padding"
      style={{ background: "var(--bg-elevated)" }}
    >
      <div class="max-w-[1200px] mx-auto grid grid-cols-1 md:grid-cols-3 gap-12 md:gap-8">
        {props.map((prop) => (
          <div class="fade-in-on-scroll flex flex-col gap-4 text-center md:text-left">
            <span
              class="label"
              style={{ color: "rgba(245, 240, 220, 0.35)" }}
            >
              [{prop.index}]
            </span>
            <h3
              class="label-lg"
              style={{ color: "var(--text-primary)" }}
            >
              {prop.title}
            </h3>
            <p
              class="text-sm leading-relaxed"
              style={{ color: "rgba(245, 240, 220, 0.75)" }}
            >
              {prop.body}
            </p>
          </div>
        ))}
      </div>
    </section>
  );
}
