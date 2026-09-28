/*
 * Size class — derived ONCE in App from the device width and read through
 * context, the way SwiftUI's `horizontalSizeClass` environment value is.
 *
 * Regular starts at 669pt: the iPhone Duo's inner display, the narrowest
 * regular-width surface the app targets. Everything below renders exactly as
 * the phone layout did before regular width existed.
 *
 * The constants are the settled regular-width numbers; the SwiftUI port reads
 * the same values (see tools/sketchpad/CLAUDE.md, "Regular width").
 */
import { createContext, useContext } from 'solid-js'

export type SizeClass = 'compact' | 'regular'

export const REGULAR_MIN_WIDTH = 669

/** Sidebar column. Docked beside the content only where it leaves room for list | detail. */
export const SIDEBAR_WIDTH = 260
export const SIDEBAR_DOCK_MIN_WIDTH = 1100

/**
 * Services / Costs list column. Half the Duo's inner display, so the divider
 * lands ON the fold rather than a row's text straddling it.
 */
export const LIST_COLUMN_WIDTH = 334

/** Detail screens, forms, and settings never set a line longer than this. */
export const READABLE_WIDTH = 680

export const sizeClassFor = (width: number): SizeClass => (width >= REGULAR_MIN_WIDTH ? 'regular' : 'compact')

const SizeClassContext = createContext<() => SizeClass>((): SizeClass => 'compact')
export const SizeClassProvider = SizeClassContext.Provider
export const useSizeClass = () => useContext(SizeClassContext)
