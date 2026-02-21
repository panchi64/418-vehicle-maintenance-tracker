import { Title, Meta } from "@solidjs/meta";
import { useScrollFade } from "~/hooks/useScrollFade";
import Navbar from "~/components/Navbar";
import Hero from "~/components/Hero";
import ValueProps from "~/components/ValueProps";
import FeatureShowcase from "~/components/FeatureShowcase";
import ThemesGallery from "~/components/ThemesGallery";
import Pricing from "~/components/Pricing";
import ImportSection from "~/components/ImportSection";
import Privacy from "~/components/Privacy";
import FAQ from "~/components/FAQ";
import FinalCTA from "~/components/FinalCTA";
import Footer from "~/components/Footer";

export default function Home() {
  useScrollFade();

  return (
    <>
      <Title>Checkpoint — Vehicle Maintenance Tracker for iPhone & Apple Watch</Title>
      <Meta
        name="description"
        content="Track vehicle maintenance, costs, and schedules. Smart reminders, Apple Watch support, widgets, and Siri. Free with no ads."
      />
      <Meta
        name="keywords"
        content="vehicle maintenance tracker, car maintenance app, iPhone, Apple Watch, service log, oil change reminder, mileage tracker, cost tracker"
      />
      <Meta property="og:title" content="Checkpoint — Vehicle Maintenance Tracker for iPhone & Apple Watch" />
      <Meta
        property="og:description"
        content="Track vehicle maintenance, costs, and schedules. Smart reminders, Apple Watch support, widgets, and Siri. Free with no ads."
      />
      <Meta property="og:type" content="website" />
      <Meta property="og:url" content="https://checkpoint.franciscocasiano.com" />
      <Meta property="og:image" content="https://checkpoint.franciscocasiano.com/og-image.png" />
      <Meta property="og:image:width" content="1200" />
      <Meta property="og:image:height" content="630" />
      <Meta name="twitter:card" content="summary_large_image" />
      <Meta name="twitter:image" content="https://checkpoint.franciscocasiano.com/og-image.png" />

      <div class="frame">
        <Navbar />
        <main>
          <Hero />
          <ValueProps />
          <FeatureShowcase />
          <ThemesGallery />
          <Pricing />
          <ImportSection />
          <Privacy />
          <FAQ />
          <FinalCTA />
        </main>
        <Footer />
      </div>
    </>
  );
}
