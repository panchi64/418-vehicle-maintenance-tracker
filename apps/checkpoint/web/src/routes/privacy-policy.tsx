import { Title, Meta } from "@solidjs/meta";
import Navbar from "~/components/Navbar";
import Footer from "~/components/Footer";

export default function PrivacyPolicy() {
  return (
    <>
      <Title>Privacy Policy — Checkpoint</Title>
      <Meta name="description" content="Checkpoint privacy policy. Your data stays on your device." />

      <div class="frame">
        <Navbar />
        <main
          class="section-padding legal-prose"
          style={{ background: "var(--bg-primary)", "padding-top": "140px" }}
        >
          <div class="max-w-[720px] mx-auto">
            <h1>Privacy Policy</h1>
            <p class="effective-date">Effective February 15, 2026</p>

            <h2>Overview</h2>
            <p>
              Checkpoint is a vehicle maintenance tracker for iOS. Your data belongs to you. We do not
              collect personal information, do not require account registration, and do not sell or share
              your data with advertisers or data brokers.
            </p>

            <h2>Data We Store on Your Device</h2>
            <p>
              All of the following data is stored locally on your device using Apple's SwiftData framework:
            </p>
            <ul>
              <li><strong>Vehicle information</strong> — nickname, make, model, year, VIN, license plate, tire size, oil type, notes, and registration (marbete) expiration</li>
              <li><strong>Maintenance records</strong> — service names, due dates, mileage thresholds, recurrence intervals, and completion history</li>
              <li><strong>Service logs</strong> — date performed, mileage at time of service, cost, cost category, and notes</li>
              <li><strong>Attachments</strong> — photos and PDFs you attach to service logs, along with text extracted from scanned receipts</li>
              <li><strong>Mileage readings</strong> — timestamped mileage snapshots used to estimate driving pace</li>
            </ul>
            <p>
              You have full control over this data. Deleting a vehicle removes all associated services, logs,
              attachments, and mileage history.
            </p>

            <h2>iCloud Sync</h2>
            <p>
              If you enable iCloud sync (on by default), your data is stored in your personal iCloud account
              using Apple's CloudKit. This data is encrypted and managed by Apple under
              their <a href="https://www.apple.com/legal/privacy/" target="_blank" rel="noopener noreferrer">privacy policy</a>.
              Francisco Casiano does not have access to your iCloud data.
            </p>
            <p>
              You can disable iCloud sync at any time in the app's Settings. You can also remove synced data
              through your device's iCloud storage settings.
            </p>

            <h2>Camera and Photos</h2>
            <p>Checkpoint uses your device camera to:</p>
            <ul>
              <li><strong>Scan your odometer</strong> for quick mileage updates</li>
              <li><strong>Scan your VIN</strong> from door jamb stickers or dashboard plates</li>
              <li><strong>Scan receipts</strong> to extract text from service invoices</li>
            </ul>
            <p>
              All image processing uses Apple's on-device Vision framework. Photos captured for OCR scanning
              are processed entirely on your device and are not transmitted to any server. Only the extracted
              text (mileage reading, VIN, or receipt content) is retained.
            </p>
            <p>
              You may also select photos from your photo library to attach to service logs. These are stored
              within the app's local database (and in your iCloud if sync is enabled).
            </p>

            <h2>Analytics</h2>
            <p>
              Checkpoint uses PostHog for anonymous, aggregated usage analytics. This helps us understand
              which features are used and improve the app.
            </p>
            <p><strong>What we collect:</strong></p>
            <ul>
              <li>Screen views (e.g., "home", "services" — not your actual data)</li>
              <li>Feature usage flags (e.g., whether a vehicle was added with OCR, whether a log has attachments — as boolean yes/no values)</li>
              <li>Purchase events (product identifiers only, e.g., "pro.unlock")</li>
            </ul>
            <p><strong>What we never collect:</strong></p>
            <ul>
              <li>Vehicle names, makes, models, VINs, or license plates</li>
              <li>Service names, costs, notes, or dates</li>
              <li>Photos, attachments, or receipt text</li>
              <li>Mileage readings</li>
              <li>Any personally identifiable information</li>
            </ul>
            <p>
              <strong>You can opt out</strong> of analytics entirely in the app's Settings. When you opt out,
              no data is sent to PostHog.
            </p>

            <h2>Third-Party Services</h2>

            <h3>NHTSA (National Highway Traffic Safety Administration)</h3>
            <p>
              When you use VIN lookup or check for safety recalls, your vehicle's VIN or make/model/year is
              sent to the NHTSA's free public API (<code>vpic.nhtsa.dot.gov</code> and <code>api.nhtsa.gov</code>).
              This is a U.S. government service. Francisco Casiano does not control NHTSA's data handling. Results
              are cached locally on your device.
            </p>

            <h3>Apple App Store (StoreKit)</h3>
            <p>
              In-app purchases are processed entirely through Apple's App Store infrastructure. Francisco Casiano
              does not collect, process, or store any payment or billing information.
              Apple's <a href="https://www.apple.com/legal/internet-services/itunes/" target="_blank" rel="noopener noreferrer">App Store terms</a> govern
              these transactions.
            </p>

            <h3>Apple CloudKit</h3>
            <p>
              As described in the iCloud Sync section, data sync uses Apple's CloudKit service under Apple's
              privacy practices.
            </p>

            <h2>What We Do Not Do</h2>
            <ul>
              <li><strong>No account or registration required</strong> — the app works entirely without sign-up</li>
              <li><strong>No location tracking</strong> — the app does not access your location</li>
              <li><strong>No advertising</strong> — the app contains no ads and no ad-tracking SDKs</li>
              <li><strong>No data selling</strong> — we do not sell, rent, or trade your data to anyone</li>
              <li><strong>No server-side storage</strong> — Francisco Casiano does not operate servers that store your data</li>
              <li><strong>No microphone, contacts, health, or calendar access</strong></li>
            </ul>

            <h2>Notifications</h2>
            <p>
              Checkpoint sends local notifications to remind you about upcoming services, mileage updates,
              registration renewals, and annual cost summaries. These notifications are generated entirely on
              your device. No push notification servers are involved. You can manage notification permissions
              in your device's Settings.
            </p>

            <h2>Widgets and Apple Watch</h2>
            <p>
              The app shares limited data with its home screen widget and Apple Watch companion app through
              secure App Groups:
            </p>
            <ul>
              <li>Vehicle name and current mileage</li>
              <li>Up to three upcoming service names and their status</li>
            </ul>
            <p>This data stays on your devices and is not transmitted externally.</p>

            <h2>Siri Integration</h2>
            <p>
              Checkpoint supports Siri voice commands to check upcoming services and mileage. Siri reads from
              the same local data shared with widgets. Voice processing is handled by Apple under their
              privacy practices.
            </p>

            <h2>Data Import and Export</h2>
            <ul>
              <li><strong>CSV Import</strong> — You can import service history from files stored on your device. Parsing is done entirely on-device.</li>
              <li><strong>PDF Export</strong> — You can generate a service history PDF. The file is created locally and shared through the system share sheet.</li>
            </ul>

            <h2>Children's Privacy</h2>
            <p>
              Checkpoint is not directed at children under 13. We do not knowingly collect information
              from children.
            </p>

            <h2>Data Deletion</h2>
            <p>To delete your data:</p>
            <ol>
              <li><strong>In-app:</strong> Delete individual vehicles, services, or logs. Deleting a vehicle removes all its associated data.</li>
              <li><strong>Uninstall:</strong> Removing the app deletes all local data.</li>
              <li><strong>iCloud:</strong> Remove synced data via Settings &gt; [Your Name] &gt; iCloud &gt; Manage Account Storage.</li>
            </ol>

            <h2>Changes to This Policy</h2>
            <p>
              We may update this policy from time to time. Changes will be reflected in the "Effective Date"
              above. Continued use of the app after changes constitutes acceptance of the revised policy.
            </p>

            <h2>Contact</h2>
            <p>
              If you have questions about this Privacy Policy, contact us at:{" "}
              <a href="mailto:support@franciscocasiano.com">support@franciscocasiano.com</a>.
            </p>
          </div>
        </main>
        <Footer />
      </div>
    </>
  );
}
