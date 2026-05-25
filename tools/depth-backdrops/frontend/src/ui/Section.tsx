import { useState, type ReactNode } from "react";

export function Section({
  title,
  defaultOpen = true,
  children,
}: {
  title: string;
  defaultOpen?: boolean;
  children: ReactNode;
}) {
  const [open, setOpen] = useState(defaultOpen);
  return (
    <div className="section">
      <header onClick={() => setOpen((v) => !v)}>
        <span>{title}</span>
        <span>{open ? "−" : "+"}</span>
      </header>
      {open && <div className="body">{children}</div>}
    </div>
  );
}
