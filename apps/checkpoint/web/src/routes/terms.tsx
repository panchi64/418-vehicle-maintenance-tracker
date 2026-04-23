import { Title, Meta } from "@solidjs/meta";
import Navbar from "~/components/Navbar";
import Footer from "~/components/Footer";

export default function Terms() {
  return (
    <>
      <Title>Terms of Service — Checkpoint</Title>
      <Meta name="description" content="Terms of service for the Checkpoint vehicle maintenance app." />

      <div class="frame">
        <Navbar />
        <main
          class="section-padding legal-prose"
          style={{ background: "var(--bg-primary)", "padding-top": "140px" }}
        >
          <div class="max-w-[720px] mx-auto">
            <h1>Terms of Service</h1>
            <p class="effective-date">Effective February 15, 2026</p>
            <p><strong>App:</strong> Checkpoint</p>
            <p><strong>Developer:</strong> Francisco Casiano</p>

            <h2>1. Acceptance of Terms</h2>
            <p>
              By downloading, installing, or using Checkpoint ("the App"), you agree to these Terms
              of Service ("Terms"). If you do not agree to these Terms, do not use the App.
            </p>

            <h2>2. Description of Service</h2>
            <p>
              Checkpoint is a vehicle maintenance tracking application for iOS. The App allows you to:
            </p>
            <ul>
              <li>Record and manage vehicle information</li>
              <li>Schedule and track maintenance services</li>
              <li>Log service history with costs, notes, and attachments</li>
              <li>Scan odometers, VINs, and receipts using your device camera</li>
              <li>Receive local notifications for upcoming services</li>
              <li>Look up vehicle recalls via the NHTSA public database</li>
              <li>Sync data across your devices via iCloud</li>
              <li>View maintenance summaries on home screen widgets and Apple Watch</li>
            </ul>

            <h2>3. User Data and Ownership</h2>
            <p>
              You retain full ownership of all data you enter into the App. Francisco Casiano does not
              claim any rights to your vehicle information, service records, photos, or any other
              content you create within the App.
            </p>
            <p>
              Your data is stored on your device and, if iCloud sync is enabled, in your personal
              iCloud account. Francisco Casiano does not have access to your data. See our{" "}
              <a href="/privacy">Privacy Policy</a> for details.
            </p>

            <h2>4. In-App Purchases</h2>
            <p>The App offers optional in-app purchases:</p>
            <ul>
              <li>
                <strong>Checkpoint Pro</strong> — a one-time, non-consumable purchase that unlocks
                additional features
              </li>
              <li>
                <strong>Tips</strong> — optional consumable purchases to support development
              </li>
            </ul>
            <p>
              All purchases are processed through the Apple App Store and are subject to Apple's{" "}
              <a href="https://www.apple.com/legal/internet-services/itunes/" target="_blank" rel="noopener noreferrer">
                terms and conditions
              </a>
              . Refund requests must be directed to Apple.
            </p>

            <h2>5. Third-Party Services</h2>
            <p>The App integrates with the following third-party services:</p>
            <ul>
              <li>
                <strong>Apple iCloud / CloudKit</strong> — for optional data sync, governed by
                Apple's terms
              </li>
              <li>
                <strong>Apple StoreKit</strong> — for in-app purchases, governed by Apple's terms
              </li>
              <li>
                <strong>NHTSA Public API</strong> — for VIN decoding and recall lookups. NHTSA is a
                U.S. government service; Francisco Casiano is not responsible for its availability or
                accuracy
              </li>
              <li>
                <strong>PostHog</strong> — for anonymous usage analytics (opt-out available in
                Settings)
              </li>
            </ul>
            <p>
              Francisco Casiano is not responsible for the availability, accuracy, or policies of
              third-party services.
            </p>

            <h2>6. Accuracy and Disclaimers</h2>
            <p>
              The App is a personal record-keeping tool. Information provided by the App, including
              but not limited to:
            </p>
            <ul>
              <li><strong>OCR readings</strong> (odometer, VIN, receipt scanning)</li>
              <li><strong>NHTSA recall data</strong></li>
              <li><strong>Service due date and mileage estimates</strong></li>
              <li><strong>Cost calculations and summaries</strong></li>
            </ul>
            <p>
              ...is provided for convenience and informational purposes only. Francisco Casiano does not
              guarantee the accuracy, completeness, or timeliness of this information.
            </p>
            <p><strong>You are solely responsible for:</strong></p>
            <ul>
              <li>Verifying the accuracy of scanned or estimated data</li>
              <li>Maintaining your vehicle according to manufacturer recommendations</li>
              <li>Making decisions about vehicle safety and maintenance</li>
            </ul>
            <p>
              The App is not a substitute for professional automotive advice, manufacturer service
              schedules, or official government recall notices.
            </p>

            <h2>7. Limitation of Liability</h2>
            <p>
              TO THE MAXIMUM EXTENT PERMITTED BY APPLICABLE LAW, FRANCISCO CASIANO SHALL NOT BE LIABLE FOR
              ANY INDIRECT, INCIDENTAL, SPECIAL, CONSEQUENTIAL, OR PUNITIVE DAMAGES, OR ANY LOSS OF
              DATA, PROFITS, OR GOODWILL, ARISING OUT OF OR RELATED TO YOUR USE OF THE APP.
            </p>
            <p>THIS INCLUDES, WITHOUT LIMITATION, DAMAGES ARISING FROM:</p>
            <ul>
              <li>RELIANCE ON OCR READINGS, RECALL DATA, OR SERVICE ESTIMATES</li>
              <li>DATA LOSS DUE TO DEVICE FAILURE, iCLOUD SYNC ISSUES, OR APP UPDATES</li>
              <li>MISSED MAINTENANCE REMINDERS DUE TO NOTIFICATION FAILURES</li>
              <li>INTERRUPTION OR UNAVAILABILITY OF THIRD-PARTY SERVICES</li>
            </ul>

            <h2>8. Warranty Disclaimer</h2>
            <p>
              THE APP IS PROVIDED "AS IS" AND "AS AVAILABLE" WITHOUT WARRANTIES OF ANY KIND, WHETHER
              EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO IMPLIED WARRANTIES OF MERCHANTABILITY,
              FITNESS FOR A PARTICULAR PURPOSE, AND NON-INFRINGEMENT.
            </p>
            <p>
              Francisco Casiano does not warrant that the App will be uninterrupted, error-free, or free of
              harmful components.
            </p>

            <h2>9. Acceptable Use</h2>
            <p>You agree not to:</p>
            <ul>
              <li>Reverse engineer, decompile, or disassemble the App</li>
              <li>Use the App for any unlawful purpose</li>
              <li>Attempt to interfere with the App's functionality or security</li>
              <li>Redistribute or resell the App or its content</li>
            </ul>

            <h2>10. Intellectual Property</h2>
            <p>
              The App, including its design, code, icons, and branding, is the intellectual property
              of Francisco Casiano. These Terms do not grant you any rights to Francisco Casiano's trademarks,
              logos, or other brand elements.
            </p>

            <h2>11. Data Loss</h2>
            <p>
              While the App uses SwiftData and iCloud for reliable data storage, Francisco Casiano is not
              responsible for data loss caused by device failure, operating system updates, iCloud
              service disruptions, or other circumstances beyond our control. You are encouraged to
              keep iCloud sync enabled and to periodically export your service history as a PDF
              backup.
            </p>

            <h2>12. Termination</h2>
            <p>
              You may stop using the App at any time by uninstalling it. Francisco Casiano reserves the
              right to discontinue the App or any of its features at any time without prior notice.
            </p>

            <h2>13. Changes to These Terms</h2>
            <p>
              We may update these Terms from time to time. Changes will be reflected in the
              effective date at the top of this page. Continued use of the App after changes
              constitutes acceptance of the revised Terms.
            </p>

            <h2>14. Governing Law</h2>
            <p>
              These Terms shall be governed by and construed in accordance with the laws of the
              United States and the Commonwealth of Puerto Rico, without regard to conflict of law
              principles.
            </p>

            <h2>15. Severability</h2>
            <p>
              If any provision of these Terms is found to be unenforceable or invalid, that
              provision shall be limited or eliminated to the minimum extent necessary, and the
              remaining provisions shall remain in full effect.
            </p>

            <h2>16. Contact</h2>
            <p>
              If you have questions about these Terms, contact us at:
            </p>
            <p>
              <strong>Francisco Casiano</strong>
              <br />
              Email: <a href="mailto:support@franciscocasiano.com">support@franciscocasiano.com</a>
            </p>
          </div>
        </main>
        <Footer />
      </div>
    </>
  );
}
