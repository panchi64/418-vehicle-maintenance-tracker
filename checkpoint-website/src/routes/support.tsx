import { Title, Meta } from "@solidjs/meta";
import { For, createSignal } from "solid-js";
import Navbar from "~/components/Navbar";
import Footer from "~/components/Footer";

const supportFaqs = [
  {
    question: "How do I add a new vehicle?",
    answer:
      "Tap the vehicle name at the top of any tab to open the vehicle picker. At the bottom, tap Add Vehicle. You'll walk through a short setup: nickname, make, model, year, and current mileage. You can also scan your VIN or odometer with the camera. Optional fields include license plate, tire size, oil type, and notes.",
  },
  {
    question: "How do I log a service record?",
    answer:
      'Tap the "Log" button in the bottom tab bar to record a completed service, or "Schedule" to set up a future reminder. Choose a service type (or create your own), then fill in the date, mileage, cost, and category. You can also attach receipts or photos and add notes. Tap Save in the top right when you\'re done.',
  },
  {
    question: "How do reminders work?",
    answer:
      'When you log or schedule a service, toggle "Remind me next time" and set a time interval (e.g., every 6 months) and/or a mileage interval (e.g., every 5,000 miles). Checkpoint calculates the next due date automatically and sends notifications as the deadline approaches — at 30 days, 7 days, and 1 day before.',
  },
  {
    question: "My data isn't syncing between devices. What should I do?",
    answer:
      "Make sure iCloud is enabled for Checkpoint on all your devices. Go to Settings > [Your Name] > iCloud and verify Checkpoint is toggled on. Both devices must be signed into the same Apple ID. Sync may take a few minutes over a slow connection.",
  },
  {
    question: "How do I import data from another app?",
    answer:
      "Checkpoint supports CSV imports from Fuelly, Drivvo, and Simply Auto. Export your data from the other app as a CSV file, then open Checkpoint, go to Settings > Import Service History (under Data & Sync), and select the file. The import wizard will map your data automatically.",
  },
  {
    question: "How do I restore my Checkpoint Pro purchase?",
    answer:
      'Go to Settings and scroll to the Support section. Tap "Restore Purchases." This uses your Apple ID to verify the purchase. Make sure you\'re signed into the same Apple ID you used for the original purchase.',
  },
  {
    question: "Can I export my data?",
    answer:
      'Yes. Go to the Services tab and tap "Export" at the top of your service history. Checkpoint generates a PDF with your complete maintenance record — dates, mileage, costs, and categories. You can share it via AirDrop, email, or save it to the Files app.',
  },
  {
    question: "How do I delete my data?",
    answer:
      "To delete a vehicle and all its records, tap the vehicle name to open the vehicle picker, then tap the ellipsis (···) menu next to the vehicle and select Delete. You can also long-press a vehicle for the same option. Deleting the app removes all locally stored data. To remove iCloud data, go to iOS Settings > [Your Name] > iCloud > Manage Storage.",
  },
];

function SupportFAQItem(props: { question: string; answer: string }) {
  const [open, setOpen] = createSignal(false);

  return (
    <div style={{ "border-bottom": "2px solid rgba(245, 240, 220, 0.1)" }}>
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
          "max-height": open() ? "300px" : "0",
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

export default function Support() {
  return (
    <>
      <Title>Support — Checkpoint</Title>
      <Meta
        name="description"
        content="Get help with Checkpoint. Browse common questions or contact support."
      />

      <div class="frame">
        <Navbar />
        <main
          class="section-padding"
          style={{ background: "var(--bg-primary)", "padding-top": "140px" }}
        >
          <div class="max-w-200 mx-auto">
            {/* Header */}
            <h1
              class="text-3xl md:text-4xl font-light mb-4"
              style={{ color: "var(--text-primary)" }}
            >
              Support
            </h1>
            <p
              class="text-base mb-16"
              style={{ color: "rgba(245, 240, 220, 0.6)" }}
            >
              Find answers to common questions below, or contact us directly.
            </p>

            {/* FAQ Accordion */}
            <section class="mb-20">
              <h2
                class="label-lg mb-6"
                style={{ color: "rgba(245, 240, 220, 0.5)" }}
              >
                COMMON QUESTIONS
              </h2>
              <div
                style={{ "border-top": "2px solid rgba(245, 240, 220, 0.1)" }}
              >
                <For each={supportFaqs}>
                  {(faq) => (
                    <SupportFAQItem
                      question={faq.question}
                      answer={faq.answer}
                    />
                  )}
                </For>
              </div>
            </section>

            {/* Contact */}
            <section class="text-center">
              <h2
                class="text-xl md:text-2xl font-light mb-4"
                style={{ color: "var(--text-primary)" }}
              >
                Still need help?
              </h2>
              <p
                class="text-sm mb-8"
                style={{ color: "rgba(245, 240, 220, 0.6)" }}
              >
                We typically respond within 24 hours.
              </p>
              <a
                href="mailto:support@franciscocasiano.com"
                class="btn-primary inline-block"
              >
                Email Support
              </a>
              <p
                class="text-xs mt-4"
                style={{ color: "rgba(245, 240, 220, 0.4)" }}
              >
                support@franciscocasiano.com
              </p>
            </section>
          </div>
        </main>
        <Footer />
      </div>
    </>
  );
}
