import { createSignal, createEffect, onCleanup } from "solid-js";
import { A, useLocation, useNavigate } from "@solidjs/router";

export default function Navbar() {
  const [scrolled, setScrolled] = createSignal(false);
  const [menuOpen, setMenuOpen] = createSignal(false);
  const location = useLocation();
  const navigate = useNavigate();

  const frameSize = () =>
    typeof window !== "undefined" && window.innerWidth <= 768 ? "16px" : "35px";

  createEffect(() => {
    const handleScroll = () => setScrolled(window.scrollY > 20);
    window.addEventListener("scroll", handleScroll, { passive: true });
    onCleanup(() => window.removeEventListener("scroll", handleScroll));
  });

  const scrollTo = (id: string) => {
    setMenuOpen(false);
    if (location.pathname !== "/") {
      navigate(`/#${id}`);
      return;
    }
    const el = document.getElementById(id);
    el?.scrollIntoView({ behavior: "smooth" });
  };

  return (
    <nav
      class="fixed z-50"
      style={{
        top: scrolled() ? "0" : frameSize(),
        left: scrolled() ? "0" : frameSize(),
        right: scrolled() ? "0" : frameSize(),
        background: scrolled()
          ? "rgba(0, 51, 190, 0.92)"
          : "rgba(0, 51, 190, 1)",
        "backdrop-filter": scrolled() ? "blur(12px)" : "none",
        "-webkit-backdrop-filter": scrolled() ? "blur(12px)" : "none",
        transition: "top 0.2s ease-out, left 0.2s ease-out, right 0.2s ease-out, background 0.2s ease-out",
      }}
    >
      <div class="flex items-center justify-between px-6 py-4 max-w-[1400px] mx-auto">
        {/* Logo */}
        <A href="/" class="flex items-center gap-3" style={{ "text-decoration": "none" }}>
          <img
            src="/418-checkpoint-app-icon-v1.avif"
            alt="Checkpoint app icon"
            class="w-8 h-8"
          />
          <span class="label-lg" style={{ color: "var(--text-primary)" }}>
            CHECKPOINT
          </span>
        </A>

        {/* Desktop Nav */}
        <div class="hidden md:flex items-center gap-8">
          <button
            onClick={() => scrollTo("features")}
            class="nav-link label cursor-pointer bg-transparent border-none"
            style={{ color: "var(--text-primary)" }}
          >
            FEATURES
          </button>
          <button
            onClick={() => scrollTo("pricing")}
            class="nav-link label cursor-pointer bg-transparent border-none"
            style={{ color: "var(--text-primary)" }}
          >
            PRICING
          </button>
          <button
            onClick={() => scrollTo("faq")}
            class="nav-link label cursor-pointer bg-transparent border-none"
            style={{ color: "var(--text-primary)" }}
          >
            FAQ
          </button>
          <a
            href="#"
            class="label px-5 py-2"
            style={{
              color: "var(--text-primary)",
              border: "2px solid var(--text-primary)",
              "text-decoration": "none",
            }}
          >
            DOWNLOAD
          </a>
        </div>

        {/* Mobile Hamburger */}
        <button
          class="md:hidden flex flex-col gap-1.5 bg-transparent border-none cursor-pointer p-2"
          onClick={() => setMenuOpen(!menuOpen())}
          aria-label="Toggle menu"
        >
          <span
            class="hamburger-line"
            style={{
              transform: menuOpen() ? "translateY(8px) rotate(45deg)" : "none",
            }}
          />
          <span
            class="hamburger-line"
            style={{ opacity: menuOpen() ? "0" : "1" }}
          />
          <span
            class="hamburger-line"
            style={{
              transform: menuOpen() ? "translateY(-8px) rotate(-45deg)" : "none",
            }}
          />
        </button>
      </div>

      {/* Mobile Menu */}
      <div
        class="md:hidden overflow-hidden transition-all"
        style={{
          "max-height": menuOpen() ? "300px" : "0",
          opacity: menuOpen() ? "1" : "0",
        }}
      >
        <div class="flex flex-col gap-6 px-6 py-8">
          <button
            onClick={() => scrollTo("features")}
            class="label text-left cursor-pointer bg-transparent border-none"
            style={{ color: "var(--text-primary)" }}
          >
            FEATURES
          </button>
          <button
            onClick={() => scrollTo("pricing")}
            class="label text-left cursor-pointer bg-transparent border-none"
            style={{ color: "var(--text-primary)" }}
          >
            PRICING
          </button>
          <button
            onClick={() => scrollTo("faq")}
            class="label text-left cursor-pointer bg-transparent border-none"
            style={{ color: "var(--text-primary)" }}
          >
            FAQ
          </button>
          <a
            href="#"
            class="label px-5 py-3 text-center"
            style={{
              color: "var(--text-primary)",
              border: "2px solid var(--text-primary)",
              "text-decoration": "none",
            }}
          >
            DOWNLOAD
          </a>
        </div>
      </div>
    </nav>
  );
}
