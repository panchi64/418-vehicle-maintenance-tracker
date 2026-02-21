import { onMount, onCleanup } from "solid-js";

export function useScrollFade() {
  let observer: IntersectionObserver | undefined;

  onMount(() => {
    const staggerGroup = new Map<string, number>();

    observer = new IntersectionObserver(
      (entries) => {
        for (const entry of entries) {
          if (entry.isIntersecting) {
            const el = entry.target as HTMLElement;

            // Group elements by their parent section for stagger
            const section = el.closest("section, div.grid, div.flex.flex-col") || el.parentElement;
            const key = section ? section.className.slice(0, 30) : "root";

            const count = staggerGroup.get(key) || 0;
            staggerGroup.set(key, count + 1);

            const delay = count * 80; // 80ms stagger between siblings
            el.style.transitionDelay = `${delay}ms`;
            el.classList.add("is-visible");

            // Reset group after a pause so re-scrolling works naturally
            setTimeout(() => staggerGroup.set(key, 0), 600);
          }
        }
      },
      { threshold: 0.1 }
    );

    const elements = document.querySelectorAll(".fade-in-on-scroll");
    elements.forEach((el) => observer!.observe(el));
  });

  onCleanup(() => {
    observer?.disconnect();
  });
}
