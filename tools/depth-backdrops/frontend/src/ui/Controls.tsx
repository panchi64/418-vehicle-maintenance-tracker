import type { Params } from "../types";
import { Section } from "./Section";
import { CheckboxField, ColorField, NumberSlider, RangePair } from "./fields";

export function Controls({
  params,
  onChange,
}: {
  params: Params;
  onChange: (p: Params) => void;
}) {
  const patch = <K extends keyof Params>(key: K, value: Partial<Params[K]>) =>
    onChange({ ...params, [key]: { ...params[key], ...value } });

  return (
    <div className="controls">
      <Section title="Depth">
        <RangePair
          label="Range"
          value={[params.depth.inMin, params.depth.inMax]}
          min={0}
          max={1}
          step={0.01}
          onChange={([a, b]) => patch("depth", { inMin: a, inMax: b })}
        />
        <NumberSlider
          label="Gamma"
          value={params.depth.gamma}
          min={0.1}
          max={5}
          step={0.05}
          onChange={(n) => patch("depth", { gamma: n })}
        />
        <NumberSlider
          label="Contrast"
          value={params.depth.contrast}
          min={0}
          max={4}
          step={0.05}
          onChange={(n) => patch("depth", { contrast: n })}
        />
        <CheckboxField
          label="Invert"
          value={params.depth.invert}
          onChange={(b) => patch("depth", { invert: b })}
        />
      </Section>

      <Section title="Pixel grid">
        <NumberSlider
          label="Cell px"
          value={params.grid.size}
          min={1}
          max={256}
          step={1}
          onChange={(n) => {
            const size = Math.round(n);
            patch("grid", { size, gap: Math.min(params.grid.gap, Math.max(0, size - 1)) });
          }}
        />
        <NumberSlider
          label="Gap px"
          value={params.grid.gap}
          min={0}
          max={Math.max(0, params.grid.size - 1)}
          step={1}
          onChange={(n) => patch("grid", { gap: Math.round(n) })}
        />
      </Section>

      <Section title="Color">
        <ColorField
          label="Near"
          value={params.color.near}
          onChange={(c) => patch("color", { near: c })}
        />
        <ColorField
          label="Far"
          value={params.color.far}
          onChange={(c) => patch("color", { far: c })}
        />
        <RangePair
          label="Mix range"
          value={params.color.valueRange}
          min={0}
          max={1}
          step={0.01}
          onChange={(v) => patch("color", { valueRange: v })}
        />
      </Section>

    </div>
  );
}
