import * as twgl from "twgl.js";
import fragSrc from "./backdrop.frag.glsl?raw";
import vertSrc from "./backdrop.vert.glsl?raw";
import type { Params, ViewMode } from "../types";

const VIEW_MODE_TO_INT: Record<ViewMode, number> = {
  source: 0,
  depth: 1,
  styled: 2,
};

function hexToRgb(hex: string): [number, number, number] {
  const v = parseInt(hex.replace("#", "").slice(0, 6), 16);
  return [((v >> 16) & 0xff) / 255, ((v >> 8) & 0xff) / 255, (v & 0xff) / 255];
}

const PLACEHOLDER = new Uint8Array([0, 0, 0, 255]);

type Channel = "source" | "depth";

export class BackdropRenderer {
  private gl: WebGL2RenderingContext;
  private programInfo: twgl.ProgramInfo;
  private bufferInfo: twgl.BufferInfo;
  private placeholderTex: WebGLTexture;
  private sourceTex: WebGLTexture;
  private depthTex: WebGLTexture;
  private hasSource = false;
  private hasDepth = false;
  private sourceGen = 0;
  private depthGen = 0;

  constructor(canvas: HTMLCanvasElement) {
    const gl = canvas.getContext("webgl2", { preserveDrawingBuffer: true });
    if (!gl) throw new Error("WebGL2 unavailable");
    this.gl = gl;
    this.programInfo = twgl.createProgramInfo(gl, [vertSrc, fragSrc]);
    this.bufferInfo = twgl.createBufferInfoFromArrays(gl, {
      a_position: { numComponents: 2, data: [-1, -1, 1, -1, -1, 1, 1, 1] },
      indices: [0, 1, 2, 2, 1, 3],
    });
    this.placeholderTex = twgl.createTexture(gl, {
      src: PLACEHOLDER,
      width: 1,
      height: 1,
    });
    this.sourceTex = this.placeholderTex;
    this.depthTex = this.placeholderTex;
  }

  loadSource(url: string): Promise<void> {
    const gen = ++this.sourceGen;
    return this.loadInto("source", url, gen);
  }

  loadDepth(url: string): Promise<void> {
    const gen = ++this.depthGen;
    return this.loadInto("depth", url, gen);
  }

  /** Resize the backing canvas/framebuffer. The caller should `render()` afterwards. */
  setSize(width: number, height: number): void {
    const canvas = this.gl.canvas as HTMLCanvasElement;
    const w = Math.max(1, Math.floor(width));
    const h = Math.max(1, Math.floor(height));
    if (canvas.width !== w) canvas.width = w;
    if (canvas.height !== h) canvas.height = h;
  }

  clearSource(): void {
    this.sourceGen += 1; // invalidate in-flight loads
    if (this.sourceTex !== this.placeholderTex) {
      this.gl.deleteTexture(this.sourceTex);
      this.sourceTex = this.placeholderTex;
    }
    this.hasSource = false;
  }

  clearDepth(): void {
    this.depthGen += 1;
    if (this.depthTex !== this.placeholderTex) {
      this.gl.deleteTexture(this.depthTex);
      this.depthTex = this.placeholderTex;
    }
    this.hasDepth = false;
  }

  private loadInto(channel: Channel, url: string, gen: number): Promise<void> {
    return new Promise((resolve, reject) => {
      twgl.createTexture(
        this.gl,
        {
          src: url,
          crossOrigin: "",
          minMag: this.gl.LINEAR,
          wrap: this.gl.CLAMP_TO_EDGE,
        },
        (err, tex) => {
          const liveGen = channel === "source" ? this.sourceGen : this.depthGen;
          if (gen !== liveGen) {
            // a newer load (or a clear) superseded us — drop the texture and bail
            if (tex) this.gl.deleteTexture(tex);
            return resolve();
          }
          if (err || !tex) return reject(err ?? new Error("texture load failed"));
          if (channel === "source") {
            if (this.sourceTex !== this.placeholderTex) this.gl.deleteTexture(this.sourceTex);
            this.sourceTex = tex;
            this.hasSource = true;
          } else {
            if (this.depthTex !== this.placeholderTex) this.gl.deleteTexture(this.depthTex);
            this.depthTex = tex;
            this.hasDepth = true;
          }
          resolve();
        },
      );
    });
  }

  render(params: Params, view: ViewMode): void {
    const { gl, programInfo, bufferInfo } = this;
    const canvas = gl.canvas as HTMLCanvasElement;
    const width = canvas.width || 1;
    const height = canvas.height || 1;

    const uniforms = {
      u_source: this.sourceTex,
      u_depth: this.depthTex,
      u_hasSource: this.hasSource,
      u_hasDepth: this.hasDepth,
      u_canvasSize: [width, height],
      u_viewMode: VIEW_MODE_TO_INT[view],
      u_gridSize: Math.max(1, params.grid.size),
      u_gapPx: Math.max(0, params.grid.gap),
      u_inMin: params.depth.inMin,
      u_inMax: params.depth.inMax,
      u_gamma: params.depth.gamma,
      u_contrast: params.depth.contrast,
      u_invert: params.depth.invert,
      u_nearColor: hexToRgb(params.color.near),
      u_farColor: hexToRgb(params.color.far),
      u_valueRange: params.color.valueRange,
    };

    gl.viewport(0, 0, width, height);
    gl.useProgram(programInfo.program);
    twgl.setBuffersAndAttributes(gl, programInfo, bufferInfo);
    twgl.setUniforms(programInfo, uniforms);
    twgl.drawBufferInfo(gl, bufferInfo);
  }

  async snapshotPng(): Promise<Blob> {
    const canvas = this.gl.canvas as HTMLCanvasElement;
    return new Promise((resolve, reject) => {
      canvas.toBlob((b) => (b ? resolve(b) : reject(new Error("toBlob failed"))), "image/png");
    });
  }
}
