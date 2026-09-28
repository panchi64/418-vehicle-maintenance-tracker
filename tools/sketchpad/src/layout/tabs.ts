/** The root tabs — shared by the compact tab bar and the regular-width sidebar. */
export type TabId = 'home' | 'services' | 'costs'

export const TABS: { id: TabId; label: string }[] = [
  { id: 'home', label: 'Home' },
  { id: 'services', label: 'Services' },
  { id: 'costs', label: 'Costs' },
]
