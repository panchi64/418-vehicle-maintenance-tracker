/*
 * List | detail — Services and Costs at regular width.
 *
 * Stand-in for a NavigationSplitView's content + detail columns: tapping a row
 * shows its detail beside the list instead of pushing. The list column is a
 * fixed LIST_COLUMN_WIDTH (334pt) so, on the Duo's inner display, the divider
 * sits on the fold and no row's text straddles it. The detail column reads
 * through `ReadableColumn`, so a 1376pt iPad never sets a 1000pt line.
 *
 * Nothing selected shows a ContentUnavailableView stand-in: one centered
 * message, no action — the list beside it is the action.
 */
import type { JSX } from 'solid-js'
import { Show } from 'solid-js'
import { Emphasis, Secondary } from '../ui/Text'
import { LIST_COLUMN_WIDTH, READABLE_WIDTH } from '../layout/sizeClass'

export function ListDetail(props: {
  list: JSX.Element
  detail?: JSX.Element
  placeholder: { title: string; message: string }
}) {
  return (
    <div style={{ display: 'flex', flex: '1 1 auto', 'min-height': '0' }}>
      <div
        style={{
          display: 'flex',
          'flex-direction': 'column',
          flex: `0 0 ${LIST_COLUMN_WIDTH}px`,
          'min-width': '0',
          'border-right': '1px solid var(--grid-line)',
        }}
      >
        {props.list}
      </div>
      <div style={{ display: 'flex', 'flex-direction': 'column', flex: '1 1 auto', 'min-width': '0' }}>
        <Show when={props.detail} fallback={<DetailPlaceholder {...props.placeholder} />}>
          {props.detail}
        </Show>
      </div>
    </div>
  )
}

/** ContentUnavailableView stand-in. */
function DetailPlaceholder(props: { title: string; message: string }) {
  return (
    <div
      style={{
        flex: '1 1 auto',
        display: 'flex',
        'flex-direction': 'column',
        'align-items': 'center',
        'justify-content': 'center',
        gap: 'var(--space-sm)',
        padding: 'var(--space-xl) var(--space-screen-h)',
        'text-align': 'center',
      }}
    >
      <Emphasis rank="primary">{props.title}</Emphasis>
      <Secondary color="tertiary" style={{ 'max-width': '280px' }}>
        {props.message}
      </Secondary>
    </div>
  )
}

/**
 * readableContentGuide stand-in: a scroll whose content is capped at
 * READABLE_WIDTH and centered. Detail screens, and forms and settings as
 * sheets, sit in one.
 */
export function ReadableColumn(props: { children: JSX.Element }) {
  return (
    <div style={{ flex: '1 1 auto', 'min-height': '0', 'overflow-y': 'auto' }}>
      <div
        style={{
          'max-width': `${READABLE_WIDTH}px`,
          margin: '0 auto',
          'container-type': 'inline-size',
          display: 'flex',
          'flex-direction': 'column',
          gap: 'var(--space-xl)',
          padding: 'var(--space-md) var(--space-screen-h) var(--space-xl)',
        }}
      >
        {props.children}
      </div>
    </div>
  )
}
