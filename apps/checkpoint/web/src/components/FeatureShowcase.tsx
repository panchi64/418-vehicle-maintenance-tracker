import { For, createSignal, createEffect, onCleanup } from "solid-js";

interface FeatureBlock {
  id: string;
  label: string;
  labelColor: string;
  headline: string;
  body: string;
  details: string[];
  mockupText: string;
  mockupPosition: "left" | "right";
  bgColor: string;
  notifications?: string[];
}

const features: FeatureBlock[] = [
  {
    id: "feat-dashboard",
    label: "DASHBOARD",
    labelColor: "var(--status-good)",
    headline: "Your vehicle talks. This is what it says.",
    body: 'The home screen shows one thing first: what\'s due next. A single card with the service name, status, and how many miles or days remain. Below it, your recent activity and quick stats. Switch to the Services tab for the full maintenance timeline — color-coded by urgency. Green means good. Amber means soon. Red means now.',
    details: [
      "Multi-vehicle selector — switch between cars instantly",
      "Quick-add floating button for fast logging",
      "Status indicators: Good / Due Soon / Overdue",
    ],
    mockupText: "iPhone — Home Tab\n\"Next Up\" Card\nVehicle Selector\nMaintenance Timeline",
    mockupPosition: "right",
    bgColor: "var(--bg-primary)",
  },
  {
    id: "feat-service-log",
    label: "SERVICE LOG",
    labelColor: "var(--status-good)",
    headline: "Every oil change. Every repair. Documented.",
    body: "Log any service in seconds. Pick from presets like Oil Change, Brake Pads, or Tire Rotation — or create your own. Attach receipts, photos, and notes. Set it as a one-off or schedule it to repeat.",
    details: [
      "10 service type presets + custom types",
      "Photo and receipt attachments",
      "Text extraction from receipts — all on your device",
      "Optional recurring schedule with custom intervals",
    ],
    mockupText: "iPhone — Service Entry Form\nFilled Fields\nReceipt Photo Attached",
    mockupPosition: "left",
    bgColor: "var(--bg-elevated)",
  },
  {
    id: "feat-mileage",
    label: "SMART MILEAGE",
    labelColor: "var(--status-warn)",
    headline: "It knows how far you've driven.",
    body: "Checkpoint learns your driving rate and estimates your current mileage between updates. Recent trips count more than old ones, so it stays accurate as your habits change. You can update manually, type it in, or just point your camera at the odometer.",
    details: [
      "Driving rate calculated from your history",
      "Predictive mileage estimation that adapts to your driving",
      "Snap a photo of your odometer to update mileage",
      "Biweekly mileage prompts via notification",
    ],
    mockupText: "iPhone — Mileage Update\nOdometer OCR Camera View",
    mockupPosition: "right",
    bgColor: "var(--bg-primary)",
  },
  {
    id: "feat-costs",
    label: "COSTS",
    labelColor: "var(--status-urgent)",
    headline: "Know where the money went.",
    body: "Every service has a cost. Checkpoint categorizes them — maintenance, repair, upgrade, inspection — and builds reports automatically. See your monthly spending, yearly totals, and cost-per-mile. Export a professional PDF of your full service history for resale or insurance.",
    details: [
      "Monthly and yearly spending charts",
      "Cost-per-mile calculation",
      "Category breakdowns (color-coded)",
      "PDF export for service history",
    ],
    mockupText: "iPhone — Costs Tab\nBar Chart\nMonthly Spending\nCategory Breakdown",
    mockupPosition: "left",
    bgColor: "var(--bg-elevated)",
  },
  {
    id: "feat-reminders",
    label: "REMINDERS",
    labelColor: "var(--status-warn)",
    headline: "Your car has opinions. You'll hear them.",
    body: "Notifications speak in the voice of your vehicle — dry, factual, slightly judgmental. They escalate from casual to urgent as deadlines approach. You'll get reminders at 30 days, 7 days, and the day before. Configurable, but the defaults are good.",
    notifications: [
      "Odometer Sync Requested — Civic here. It's been 14 days. How far have we gone?",
      "Oil Change: 7 Days — Civic would like to remind you. Politely.",
      "Brake Inspection: OVERDUE — Civic is concerned. Mechanically speaking.",
    ],
    details: [],
    mockupText: "",
    mockupPosition: "right",
    bgColor: "var(--bg-primary)",
  },
  {
    id: "feat-ecosystem",
    label: "APPLE ECOSYSTEM",
    labelColor: "var(--status-good)",
    headline: "Everywhere you already look.",
    body: "Checkpoint lives on your Home Screen, Lock Screen, Apple Watch, and in Siri. Glance at a widget and know what's due. Ask Siri 'What's due on my car?' and get an answer. Mark a service done from your wrist. No need to open the app.",
    details: [
      "Home Screen widgets (small & medium)",
      "Lock Screen widgets (circular, rectangular, inline)",
      "Apple Watch app with service list, mileage update, and mark-done",
      "Watch complications (4 families)",
      "Siri Shortcuts — 3 voice commands",
      "Interactive widgets — mark services done without opening the app",
      "CarPlay Dashboard — widgets appear natively on your car's display",
    ],
    mockupText: "Composite — Apple Watch\nLock Screen Widgets\nHome Screen Widgets",
    mockupPosition: "left",
    bgColor: "var(--bg-elevated)",
  },
  {
    id: "feat-safety",
    label: "SAFETY",
    labelColor: "var(--status-urgent)",
    headline: "If there's a recall, you'll know.",
    body: "Checkpoint checks NHTSA recall databases for your vehicle. If a safety recall is issued, you get a notification. No searching government websites. No guessing. Your VIN is decoded and checked automatically.",
    details: [
      "NHTSA recall alerts",
      "VIN lookup — auto-fills your vehicle details",
      "Safety-critical notifications",
    ],
    mockupText: "iPhone — Recall Alert Card\nNHTSA Notice\nVehicle Name & Severity",
    mockupPosition: "right",
    bgColor: "var(--bg-primary)",
  },
];

function FeatureBlockComponent(props: { feature: FeatureBlock; index: number }) {
  const f = props.feature;
  const isLeft = f.mockupPosition === "left";
  const hasNotifications = f.notifications && f.notifications.length > 0;

  return (
    <div
      id={f.id}
      class="section-padding"
      style={{ background: f.bgColor }}
    >
      <div
        class="fade-in-on-scroll max-w-[1200px] mx-auto grid grid-cols-1 lg:grid-cols-2 gap-16 items-center"
      >
        {/* Text Column */}
        <div
          class="flex flex-col gap-6"
          style={{ order: isLeft ? "2" : "1" }}
        >
          <span
            class="label"
            style={{ color: f.labelColor }}
          >
            {f.label}
          </span>
          <h2
            class="text-3xl md:text-4xl font-light leading-tight"
            style={{ color: "var(--text-primary)" }}
          >
            {f.headline}
          </h2>
          <p
            class="text-sm leading-relaxed"
            style={{ color: "rgba(245, 240, 220, 0.75)" }}
          >
            {f.body}
          </p>

          {/* Detail List */}
          {f.details.length > 0 && (
            <ul class="flex flex-col gap-2 mt-2">
              <For each={f.details}>
                {(detail) => (
                  <li
                    class="text-xs flex items-start gap-2"
                    style={{ color: "rgba(245, 240, 220, 0.55)" }}
                  >
                    <span style={{ color: "var(--status-good)", "flex-shrink": "0" }}>—</span>
                    {detail}
                  </li>
                )}
              </For>
            </ul>
          )}

          {/* Notification Cards (for Reminders section) */}
          {hasNotifications && (
            <div class="flex flex-col gap-3 mt-4">
              <For each={f.notifications}>
                {(notif) => (
                  <div class="notification-card">
                    <em>"{notif}"</em>
                  </div>
                )}
              </For>
            </div>
          )}
        </div>

        {/* Mockup Column */}
        <div
          class="flex justify-center"
          style={{ order: isLeft ? "1" : "2" }}
        >
          {hasNotifications ? (
            <img
              src="/notification-image.avif"
              alt="Checkpoint app notification banners showing vehicle maintenance reminders with escalating urgency"
              class="w-[800px] max-w-full"
            />
          ) : f.id === "feat-dashboard" ? (
            <img
              src="/home-screen-iphone-maintenance-card.avif"
              alt="Checkpoint app dashboard showing maintenance timeline with Next Up card and upcoming services"
              class="w-[800px] max-w-full"
            />
          ) : f.id === "feat-service-log" ? (
            <img
              src="/service-entry-form.avif"
              alt="Checkpoint app service entry form showing oil change with date, cost, category, and mileage fields"
              class="w-[800px] max-w-full max-h-[750px] object-contain"
            />
          ) : f.id === "feat-mileage" ? (
            <img
              src="/odometer-camera-view.avif"
              alt="Checkpoint app OCR camera view scanning an odometer reading"
              class="w-[800px] max-w-full max-h-[750px] object-contain"
            />
          ) : f.id === "feat-costs" ? (
            <img
              src="/cost-screen-bar-chart.avif"
              alt="Checkpoint app costs tab showing monthly spending bar chart and category breakdown"
              class="w-[800px] max-w-full max-h-[750px] object-contain"
            />
          ) : f.id === "feat-ecosystem" ? (
            <img
              src="/widgets-preview.avif"
              alt="Checkpoint app Home Screen widgets showing next service due and upcoming maintenance"
              class="w-[800px] max-w-full max-h-[750px] object-contain"
            />
          ) : f.id === "feat-safety" ? (
            <img
              src="/home-screen-recall.avif"
              alt="Checkpoint app showing NHTSA recall alert card with vehicle name and severity"
              class="w-[800px] max-w-full max-h-[750px] object-contain"
            />
          ) : (
            <div class="mockup-placeholder">
              <span>{f.mockupText.split("\n").map((line, i) => (
                <>
                  {i > 0 && <br />}
                  {line}
                </>
              ))}</span>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

function FeatureNav(props: { activeIndex: number; visible: boolean }) {
  return (
    <div
      class="hidden lg:flex fixed z-40 flex-col items-start gap-1 py-4"
      style={{
        top: "50%",
        left: "0",
        transform: "translateY(-50%)",
        opacity: props.visible ? "1" : "0",
        "pointer-events": props.visible ? "auto" : "none",
        transition: "opacity 0.3s ease-out",
      }}
    >
      <For each={features}>
        {(feature, i) => {
          const isActive = () => props.activeIndex === i();
          return (
            <button
              onClick={() => {
                document.getElementById(feature.id)?.scrollIntoView({ behavior: "smooth" });
              }}
              class="cursor-pointer bg-transparent border-none flex items-center gap-3 group py-1.5 px-4"
            >
              {/* Indicator line */}
              <span
                style={{
                  width: isActive() ? "24px" : "12px",
                  height: "2px",
                  background: isActive()
                    ? "var(--text-primary)"
                    : "rgba(245, 240, 220, 0.25)",
                  transition: "width 0.2s ease-out, background 0.2s ease-out",
                  "flex-shrink": "0",
                }}
              />
              {/* Label */}
              <span
                class="label whitespace-nowrap"
                style={{
                  color: isActive()
                    ? "var(--text-primary)"
                    : "rgba(245, 240, 220, 0.3)",
                  "font-size": "10px",
                  transition: "color 0.2s ease-out",
                }}
              >
                {feature.label}
              </span>
            </button>
          );
        }}
      </For>
    </div>
  );
}

export default function FeatureShowcase() {
  const [activeIndex, setActiveIndex] = createSignal(0);
  const [navVisible, setNavVisible] = createSignal(false);

  createEffect(() => {
    if (typeof window === "undefined") return;

    const handleScroll = () => {
      const section = document.getElementById("features");
      if (section) {
        const rect = section.getBoundingClientRect();
        const inView = rect.top < window.innerHeight * 0.6 && rect.bottom > window.innerHeight * 0.3;
        setNavVisible(inView);
      }

      const ids = features.map((f) => f.id);
      let current = 0;

      for (let i = ids.length - 1; i >= 0; i--) {
        const el = document.getElementById(ids[i]);
        if (el) {
          const rect = el.getBoundingClientRect();
          if (rect.top <= window.innerHeight * 0.4) {
            current = i;
            break;
          }
        }
      }

      setActiveIndex(current);
    };

    window.addEventListener("scroll", handleScroll, { passive: true });
    onCleanup(() => window.removeEventListener("scroll", handleScroll));
  });

  return (
    <section id="features">
      <FeatureNav activeIndex={activeIndex()} visible={navVisible()} />
      <For each={features}>
        {(feature, i) => <FeatureBlockComponent feature={feature} index={i()} />}
      </For>
    </section>
  );
}
