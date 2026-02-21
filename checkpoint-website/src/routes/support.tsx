import { Title, Meta } from "@solidjs/meta";
import { For, createSignal } from "solid-js";
import Navbar from "~/components/Navbar";
import Footer from "~/components/Footer";

const supportFaqs = [
  {
    question: "How do I add a new vehicle?",
    answer:
      "Open Checkpoint and tap on the vehicle name, you will see an option at the bottom of the list to add a new vehicle. Enter your vehicle's year, make, and model. You can also add a nickname, and license plate to make it easy to identify.",
  },
  {
    question: "How do I log a service record?",
    answer:
      'Select a vehicle from your dashboard, then tap "Add Service." Choose the service type (oil change, tire rotation, etc.), enter the date, mileage, cost, and any notes. Once you press the save button on the top right, the record is saved instantly.',
  },
  {
    question: "How do reminders work?",
    answer:
      "Checkpoint tracks your mileage patterns and service history to send notifications when maintenance is due. You can also set custom reminders based on time intervals or mileage thresholds in each vehicle's settings.",
  },
  {
    question: "My data isn't syncing between devices. What should I do?",
    answer:
      "Make sure iCloud is enabled for Checkpoint on all your devices. Go to Settings > [Your Name] > iCloud and verify Checkpoint is toggled on. Both devices must be signed into the same Apple ID. Sync may take a few minutes over a slow connection.",
  },
  {
    question: "How do I import data from another app?",
    answer:
      "Checkpoint supports CSV imports from Fuelly, Drivvo, and Simply Auto. Export your data from the other app as a CSV file, then open Checkpoint, go to Settings > Import Data, and select the file. The import wizard will map your data automatically.",
  },
  {
    question: "How do I restore my Checkpoint Pro purchase?",
    answer:
      'Go to Settings > Checkpoint Pro and tap "Restore Purchase." This uses your Apple ID to verify the purchase. Make sure you\'re signed into the same Apple ID you used for the original purchase.',
  },
  {
    question: "Can I export my data?",
    answer:
      "Yes. Go to Settings > Export Data. Checkpoint will generate a CSV file containing all your vehicles, service records, and costs. You can share the file via AirDrop, email, or save it to the Files app.",
  },
  {
    question: "How do I delete my data?",
    answer:
      "To delete a single vehicle and its records, long press the vehicle on the dashboard or tap the ellipsis (···) button to the right of the vehicle name to open the menu, then tap Delete. To delete all data, go to Settings > Delete All Data. Deleting the app also removes all locally stored data. To remove iCloud data, manage it through Settings > [Your Name] > iCloud > Manage Storage.",
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
