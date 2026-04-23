import { For, createSignal } from "solid-js";

const faqs = [
  {
    question: "Is Checkpoint really free?",
    answer:
      "Yes. Every core feature — service logging, reminders, cost tracking, widgets, Apple Watch, CarPlay, and Siri — is free with no ads. Checkpoint Pro unlocks extra themes and unlimited vehicles for a one-time purchase.",
  },
  {
    question: "Do I need to create an account?",
    answer:
      "No. Checkpoint works entirely on-device with no sign-up required. Your data stays on your phone, synced through iCloud to your other Apple devices.",
  },
  {
    question: "Can I track more than one vehicle?",
    answer:
      "Yes. The free tier supports up to 3 vehicles — cars, trucks, motorcycles, boats, whatever has a maintenance schedule. Need more? Checkpoint Pro unlocks unlimited vehicles for a one-time purchase. Each vehicle gets its own dashboard, history, and reminders.",
  },
  {
    question: "How do smart reminders work?",
    answer:
      "Checkpoint learns from your driving patterns and service history. It sends notifications when maintenance is actually due based on your real mileage and time intervals — not arbitrary guesses.",
  },
  {
    question: "Can I import data from another app?",
    answer:
      "Yes. Checkpoint supports CSV import from Fuelly, Drivvo, and Simply Auto. Export from your old app, drop the file into Checkpoint, and everything transfers in seconds.",
  },
  {
    question: "What Apple devices are supported?",
    answer:
      "iPhone (iOS 17.0+), Apple Watch, CarPlay, and Home Screen widgets. Your data syncs across all devices via iCloud automatically.",
  },
  {
    question: "Is my data private?",
    answer:
      "Completely. All data is stored locally on your device and synced via iCloud. There are no accounts, no ads, and no third-party tracking. Anonymous usage analytics (no personal data) help improve the app and can be disabled with one tap in Settings.",
  },
  {
    question: "What happens if I switch phones?",
    answer:
      "Your data syncs through iCloud. Sign into the same Apple ID on your new device and everything is already there.",
  },
];

function FAQItem(props: { question: string; answer: string }) {
  const [open, setOpen] = createSignal(false);

  return (
    <div
      style={{
        "border-bottom": "2px solid rgba(245, 240, 220, 0.1)",
      }}
    >
      <button
        onClick={() => setOpen(!open())}
        class="w-full flex items-center justify-between text-left bg-transparent border-none cursor-pointer py-6 px-0 gap-4"
        style={{ color: "var(--text-primary)" }}
        aria-expanded={open()}
      >
        <span class="text-sm md:text-base font-medium">{props.question}</span>
        <span
          class="text-2xl shrink-0 transition-transform duration-200 leading-none"
          style={{
            transform: open() ? "rotate(45deg)" : "none",
            color: "rgba(245, 240, 220, 0.5)",
          }}
        >
          +
        </span>
      </button>
      <div
        class="overflow-hidden transition-all duration-300"
        style={{
          "max-height": open() ? "200px" : "0",
          opacity: open() ? "1" : "0",
        }}
      >
        <p
          class="text-sm leading-relaxed pb-6"
          style={{ color: "rgba(245, 240, 220, 0.65)" }}
        >
          {props.answer}
        </p>
      </div>
    </div>
  );
}

export default function FAQ() {
  return (
    <section
      id="faq"
      class="section-padding"
      style={{ background: "var(--bg-primary)" }}
    >
      <div class="max-w-[800px] mx-auto">
        <h2
          class="fade-in-on-scroll text-3xl md:text-4xl font-light mb-12 text-center"
          style={{ color: "var(--text-primary)" }}
        >
          Frequently asked questions.
        </h2>

        <div
          class="fade-in-on-scroll"
          style={{
            "border-top": "2px solid rgba(245, 240, 220, 0.1)",
          }}
        >
          <For each={faqs}>
            {(faq) => <FAQItem question={faq.question} answer={faq.answer} />}
          </For>
        </div>
      </div>
    </section>
  );
}
