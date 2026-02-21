import { For } from "solid-js";

const apps = [
  { name: "Fuelly", format: "CSV import" },
  { name: "Drivvo", format: "CSV import" },
  { name: "Simply Auto", format: "CSV import" },
];

export default function ImportSection() {
  return (
    <section
      class="section-padding"
      style={{ background: "var(--bg-elevated)" }}
    >
      <div class="max-w-[800px] mx-auto text-center">
        <h2
          class="fade-in-on-scroll text-3xl md:text-4xl font-light mb-4"
          style={{ color: "var(--text-primary)" }}
        >
          Switching? Bring your data.
        </h2>
        <p
          class="fade-in-on-scroll text-sm mb-12"
          style={{ color: "rgba(245, 240, 220, 0.7)" }}
        >
          Import your service history from other apps in seconds.
        </p>

        {/* App Logos */}
        <div class="fade-in-on-scroll grid grid-cols-3 gap-8 mb-12">
          <For each={apps}>
            {(app) => (
              <div class="flex flex-col items-center gap-3">
                <div
                  class="w-16 h-16 flex items-center justify-center text-xs font-bold"
                  style={{
                    background: "rgba(245, 240, 220, 0.08)",
                    border: "2px solid rgba(245, 240, 220, 0.15)",
                    color: "rgba(245, 240, 220, 0.5)",
                  }}
                >
                  CSV
                </div>
                <span
                  class="text-sm font-bold"
                  style={{ color: "var(--text-primary)" }}
                >
                  {app.name}
                </span>
                <span
                  class="text-xs"
                  style={{ color: "rgba(245, 240, 220, 0.45)" }}
                >
                  {app.format}
                </span>
              </div>
            )}
          </For>
        </div>

        <p
          class="fade-in-on-scroll text-xs leading-relaxed"
          style={{ color: "rgba(245, 240, 220, 0.5)" }}
        >
          Export a CSV from your current app, open it in Checkpoint, done. Your
          history, costs, and service records transfer automatically.
        </p>
      </div>
    </section>
  );
}
