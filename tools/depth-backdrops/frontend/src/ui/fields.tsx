function clampFinite(raw: string, fallback: number, min: number, max: number): number {
  const n = Number(raw);
  if (!Number.isFinite(n)) return fallback;
  return Math.min(max, Math.max(min, n));
}

export function NumberSlider({
  label,
  value,
  min,
  max,
  step,
  onChange,
}: {
  label: string;
  value: number;
  min: number;
  max: number;
  step: number;
  onChange: (n: number) => void;
}) {
  return (
    <div className="field">
      <label>{label}</label>
      <input
        type="range"
        min={min}
        max={max}
        step={step}
        value={value}
        onChange={(e) => onChange(clampFinite(e.target.value, value, min, max))}
      />
      <input
        type="number"
        value={value}
        step={step}
        min={min}
        max={max}
        onChange={(e) => onChange(clampFinite(e.target.value, value, min, max))}
      />
    </div>
  );
}

export function RangePair({
  label,
  value,
  min,
  max,
  step,
  onChange,
}: {
  label: string;
  value: [number, number];
  min: number;
  max: number;
  step: number;
  onChange: (v: [number, number]) => void;
}) {
  return (
    <div className="field range-pair">
      <label>{label}</label>
      <div className="pair">
        <input
          type="number"
          step={step}
          min={min}
          max={max}
          value={value[0]}
          onChange={(e) =>
            onChange([clampFinite(e.target.value, value[0], min, max), value[1]])
          }
        />
        <input
          type="number"
          step={step}
          min={min}
          max={max}
          value={value[1]}
          onChange={(e) =>
            onChange([value[0], clampFinite(e.target.value, value[1], min, max)])
          }
        />
      </div>
    </div>
  );
}

export function CheckboxField({
  label,
  value,
  onChange,
}: {
  label: string;
  value: boolean;
  onChange: (b: boolean) => void;
}) {
  return (
    <div className="field checkbox">
      <label>{label}</label>
      <input type="checkbox" checked={value} onChange={(e) => onChange(e.target.checked)} />
    </div>
  );
}

export function ColorField({
  label,
  value,
  onChange,
}: {
  label: string;
  value: string;
  onChange: (s: string) => void;
}) {
  return (
    <div className="field">
      <label>{label}</label>
      <input type="color" value={value} onChange={(e) => onChange(e.target.value)} />
      <input
        type="text"
        value={value}
        onChange={(e) => onChange(e.target.value)}
        style={{ gridColumn: "auto" }}
      />
    </div>
  );
}
