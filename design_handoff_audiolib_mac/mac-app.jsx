// Mac AudioLib — design canvas composition

function MacFrame({ width = 1280, height = 820, children, sidebarCollapsed }) {
  return (
    <AudioLibWindow
      width={width} height={height}
      sidebar={!sidebarCollapsed && <MSidebar />}
      sidebarCollapsed={sidebarCollapsed}
      playerBar={<MPlayerBar />}>
      {children}
    </AudioLibWindow>
  );
}

// ── Library full layout ────────────────────────────────────
function LibraryView() {
  return (
    <>
      <MToolbar
        title="All Books"
        subtitle="7 books · 2.84 GB"
        trailing={<div style={{ display: 'flex', gap: 6, alignItems: 'center' }}>
          <MSegmented value="grid" options={[
            { value: 'grid', icon: 'books', label: 'Grid' },
            { value: 'list', icon: 'list',  label: 'List' },
          ]} />
          <div style={{ width: 1, height: 18, background: 'rgba(27,24,20,0.1)', margin: '0 4px' }} />
          <MIconButton icon="sort" label="Recent" />
          <MIconButton icon="search" />
        </div>}
      />
      <div style={{ flex: 1, display: 'flex', minHeight: 0 }}>
        <div style={{ flex: 1, overflowY: 'auto' }}>
          <MLibraryGrid />
        </div>
        <MBookInspector book={BOOKS.habits} />
      </div>
    </>
  );
}

function LibraryListView() {
  const books = [BOOKS.habits, BOOKS.sapiens, BOOKS.hailmary, BOOKS.dune, BOOKS.threebody, BOOKS.gatsby, BOOKS.educated, BOOKS.becoming];
  return (
    <>
      <MToolbar
        title="All Books"
        subtitle="7 books · 2.84 GB"
        trailing={<div style={{ display: 'flex', gap: 6, alignItems: 'center' }}>
          <MSegmented value="list" options={[
            { value: 'grid', icon: 'books', label: 'Grid' },
            { value: 'list', icon: 'list',  label: 'List' },
          ]} />
          <div style={{ width: 1, height: 18, background: 'rgba(27,24,20,0.1)', margin: '0 4px' }} />
          <MIconButton icon="sort" label="Recent" />
        </div>}
      />
      <div style={{ flex: 1, overflowY: 'auto' }}>
        {/* Table header */}
        <div style={{
          display: 'grid', gridTemplateColumns: '40px 2.4fr 1.6fr 0.8fr 1.3fr 1.4fr',
          padding: '8px 24px', fontSize: 10.5, fontWeight: 700,
          color: T.inkMute, letterSpacing: 0.5, textTransform: 'uppercase',
          borderBottom: '0.5px solid rgba(27,24,20,0.08)',
          position: 'sticky', top: 0, background: 'rgba(241,236,226,0.94)', backdropFilter: 'blur(20px)',
        }}>
          <div></div>
          <div>Title</div>
          <div>Author</div>
          <div style={{ textAlign: 'right' }}>Duration</div>
          <div>Progress</div>
          <div style={{ textAlign: 'right' }}>Last played</div>
        </div>
        {books.map((b, i) => (
          <div key={b.id} style={{
            display: 'grid', gridTemplateColumns: '40px 2.4fr 1.6fr 0.8fr 1.3fr 1.4fr',
            padding: '10px 24px',
            borderBottom: i < books.length - 1 ? '0.5px solid ' + T.hair : 'none',
            alignItems: 'center', cursor: 'pointer',
            background: i === 0 ? 'rgba(30,144,133,0.07)' : 'transparent',
          }}>
            <Cover which={b.id} size={32} radius={4} />
            <div style={{ fontSize: 13, fontWeight: 600, color: T.ink, letterSpacing: -0.2, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis', paddingRight: 8 }}>{b.title}</div>
            <div style={{ fontSize: 12.5, color: T.inkSoft, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis', paddingRight: 8 }}>{b.author}</div>
            <div style={{ fontSize: 12, color: T.inkSoft, fontVariantNumeric: 'tabular-nums', fontFamily: 'ui-monospace, monospace', textAlign: 'right', paddingRight: 16 }}>
              {b.progress === 0 ? '—' : b.progress === 1 ? '6h 22m' : b.remain}
            </div>
            <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
              <div style={{ flex: 1 }}>
                <ProgressBar value={b.progress} height={3} color={b.progress === 1 ? T.teal : T.ink} />
              </div>
              <span style={{ fontSize: 10.5, color: T.inkMute, width: 30, textAlign: 'right', fontVariantNumeric: 'tabular-nums' }}>{Math.round(b.progress * 100)}%</span>
            </div>
            <div style={{ fontSize: 11.5, color: T.inkMute, textAlign: 'right', fontVariantNumeric: 'tabular-nums' }}>
              {['Just now', '2h ago', 'Yesterday', '3d ago', '1w ago', 'Sep 12', 'Aug 28', 'Never'][i]}
            </div>
          </div>
        ))}
      </div>
    </>
  );
}

// ── Empty library ──────────────────────────────────────────
function EmptyLibraryView() {
  return (
    <>
      <MToolbar title="All Books" subtitle="No books yet" />
      <div style={{
        flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center',
        flexDirection: 'column', padding: 40, textAlign: 'center',
      }}>
        <div style={{
          width: 120, height: 120, borderRadius: 30,
          background: T.cardSoft, display: 'flex', alignItems: 'center', justifyContent: 'center',
          marginBottom: 22,
        }}>
          <Icon name="books" size={56} color={T.inkMute} strokeWidth={1.4} />
        </div>
        <div style={{ fontFamily: 'Georgia, serif', fontSize: 28, fontWeight: 700, color: T.ink, letterSpacing: -0.5, lineHeight: 1.1 }}>
          Your library is empty
        </div>
        <div style={{ fontSize: 14, color: T.inkSoft, marginTop: 8, maxWidth: 360, lineHeight: 1.45 }}>
          Paste a YouTube link in the Downloads tab to start building your audiobook collection.
        </div>
        <div style={{ display: 'flex', gap: 10, marginTop: 24 }}>
          <button style={{
            padding: '10px 18px', borderRadius: 10, border: 'none', cursor: 'pointer',
            background: T.ink, color: '#F4ECDB', fontSize: 13, fontWeight: 600,
            display: 'flex', alignItems: 'center', gap: 6,
          }}>
            <Icon name="arrow-down-circle" size={14} color="#F4ECDB" strokeWidth={1.9} />
            Download a book
          </button>
          <button style={{
            padding: '10px 18px', borderRadius: 10,
            background: 'rgba(255,255,255,0.7)', color: T.ink,
            border: '0.5px solid rgba(27,24,20,0.08)', cursor: 'pointer',
            fontSize: 13, fontWeight: 600,
          }}>Import audio files…</button>
        </div>
      </div>
    </>
  );
}

// ── Onboarding window ─────────────────────────────────────
function MOnboarding() {
  return (
    <div style={{
      width: 800, height: 560, borderRadius: 14, overflow: 'hidden',
      background: 'linear-gradient(180deg, #F5F2EB 0%, #E8DFC9 100%)',
      boxShadow: '0 0 0 0.5px rgba(0,0,0,0.22), 0 24px 60px rgba(0,0,0,0.30)',
      display: 'flex', flexDirection: 'column', position: 'relative',
      fontFamily: MAC,
    }}>
      <div style={{ height: 38, display: 'flex', alignItems: 'center', padding: '0 14px' }}>
        <div style={{ display: 'flex', gap: 8 }}>
          <span style={{ width: 12, height: 12, borderRadius: 6, background: '#FF5F57' }} />
          <span style={{ width: 12, height: 12, borderRadius: 6, background: '#FEBC2E', opacity: 0.4 }} />
          <span style={{ width: 12, height: 12, borderRadius: 6, background: '#28C840', opacity: 0.4 }} />
        </div>
      </div>
      <div style={{ flex: 1, display: 'flex', alignItems: 'center', padding: '0 80px 24px', gap: 56 }}>
        <div style={{ flex: 1 }}>
          <div style={{
            width: 96, height: 96, borderRadius: 22,
            background: 'linear-gradient(160deg, #0F5751 0%, #1E9085 100%)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            boxShadow: '0 12px 32px rgba(15,87,81,0.32), inset 0 1px 0 rgba(255,255,255,0.2)',
            marginBottom: 24,
          }}>
            <svg width="54" height="54" viewBox="0 0 64 64" fill="none">
              <path d="M12 36 V32 a20 20 0 0 1 40 0 V36" stroke="#F4ECDB" strokeWidth="3.5" strokeLinecap="round"/>
              <rect x="8" y="36" width="12" height="18" rx="4" fill="#F4ECDB"/>
              <rect x="44" y="36" width="12" height="18" rx="4" fill="#F4ECDB"/>
            </svg>
          </div>
          <div style={{ fontFamily: 'Georgia, serif', fontSize: 44, fontWeight: 700, color: T.ink, letterSpacing: -0.8, lineHeight: 1, marginBottom: 14 }}>
            Welcome to<br/>AudioLib.
          </div>
          <div style={{ fontSize: 16, color: T.inkSoft, lineHeight: 1.45, maxWidth: 320 }}>
            Download YouTube audiobooks, listen on your Mac, and your iPhone picks up exactly where you left off.
          </div>
          <button style={{
            marginTop: 28, padding: '12px 22px', borderRadius: 10, border: 'none',
            background: T.ink, color: '#F4ECDB', fontSize: 14, fontWeight: 600, letterSpacing: -0.1,
            cursor: 'pointer', boxShadow: '0 4px 14px rgba(27,24,20,0.18)',
          }}>Get Started</button>
        </div>
        <div style={{ flex: 1, display: 'flex', flexDirection: 'column', gap: 14 }}>
          {[
            { icon: 'arrow-down-circle', t: 'Faster downloads',    s: 'Companion mode lets your Mac pull books directly — no throttling.' },
            { icon: 'books',             t: 'A library worth owning', s: 'Grid, list, sort, search. Series support. Real progress tracking.' },
            { icon: 'note',              t: 'Notes linked to time',  s: 'Stamp thoughts to a position. Re-open the book, jump right there.' },
            { icon: 'link',              t: 'Continuity with iPhone',  s: 'Sync progress, bookmarks, notes via iCloud automatically.' },
          ].map(f => (
            <div key={f.t} style={{
              display: 'flex', alignItems: 'flex-start', gap: 14,
              padding: 14, borderRadius: 12,
              background: 'rgba(255,255,255,0.55)',
              border: '0.5px solid rgba(27,24,20,0.05)',
            }}>
              <div style={{
                width: 36, height: 36, borderRadius: 10, flexShrink: 0,
                background: T.tealSoft,
                display: 'flex', alignItems: 'center', justifyContent: 'center',
              }}><Icon name={f.icon} size={18} color={T.tealInk} strokeWidth={1.9} /></div>
              <div>
                <div style={{ fontSize: 13.5, fontWeight: 600, color: T.ink, letterSpacing: -0.2 }}>{f.t}</div>
                <div style={{ fontSize: 12, color: T.inkSoft, lineHeight: 1.4, marginTop: 2 }}>{f.s}</div>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}

// ── Design System ─────────────────────────────────────────
function MacDesignSystem() {
  return (
    <div style={{ width: 880, height: 720, background: T.bg, padding: 32, fontFamily: MAC, overflow: 'hidden' }}>
      <div style={{
        fontFamily: 'Georgia, serif', fontSize: 28, fontWeight: 700, color: T.ink,
        letterSpacing: -0.4, marginBottom: 4,
      }}>AudioLib for Mac — design system</div>
      <div style={{ fontSize: 13, color: T.inkSoft, marginBottom: 24 }}>
        Inherits iOS tokens. Adjustments: tighter type, denser controls, glass sidebar, persistent player bar.
      </div>

      {/* Type */}
      <div style={{ marginBottom: 24 }}>
        <SectionLabel>Type</SectionLabel>
        <div style={{ background: T.card, borderRadius: 10, padding: 16, display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 18 }}>
          <div>
            <div style={{ fontFamily: 'Georgia, serif', fontSize: 28, fontWeight: 700, color: T.ink, letterSpacing: -0.5 }}>Atomic Habits</div>
            <div style={{ fontSize: 11, color: T.inkMute, marginTop: 2 }}>Serif display · Georgia 28/700/-0.5</div>
            <div style={{ fontFamily: 'Georgia, serif', fontSize: 18, fontWeight: 700, color: T.ink, letterSpacing: -0.3, marginTop: 14 }}>All Books</div>
            <div style={{ fontSize: 11, color: T.inkMute, marginTop: 2 }}>View title · Georgia 18/700/-0.3</div>
          </div>
          <div>
            <div style={{ fontSize: 12.5, fontWeight: 600, color: T.ink, letterSpacing: -0.2 }}>Sidebar item · 12.5/600</div>
            <div style={{ fontSize: 13, fontWeight: 600, color: T.ink, marginTop: 6 }}>Row title · 13/600</div>
            <div style={{ fontSize: 11.5, color: T.inkSoft, marginTop: 6 }}>Row secondary · 11.5/regular/62%</div>
            <div style={{ fontSize: 10.5, color: T.inkMute, marginTop: 6, fontFamily: 'ui-monospace, monospace', fontVariantNumeric: 'tabular-nums' }}>02:14:08 · mono tabular</div>
            <div style={{ fontSize: 10.5, color: T.inkMute, marginTop: 6, fontWeight: 700, letterSpacing: 0.8, textTransform: 'uppercase' }}>SECTION HEADER · 10.5/700/+0.8</div>
          </div>
        </div>
      </div>

      {/* Window dimensions */}
      <div style={{ marginBottom: 24 }}>
        <SectionLabel>Window dimensions</SectionLabel>
        <div style={{ background: T.card, borderRadius: 10, padding: 16, display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 14, fontSize: 12 }}>
          {[
            { l: 'Main',        v: '1280 × 820',  d: 'min 1080 × 680' },
            { l: 'Preferences', v: '720 × 540',   d: 'fixed' },
            { l: 'Mini Player', v: '360 × 100',   d: 'always on top' },
            { l: 'Menu bar',    v: '320 × auto',  d: 'NSMenu popover' },
          ].map(r => (
            <div key={r.l}>
              <div style={{ fontSize: 11, color: T.inkMute, textTransform: 'uppercase', letterSpacing: 0.4, fontWeight: 700, marginBottom: 2 }}>{r.l}</div>
              <div style={{ fontSize: 14, color: T.ink, fontWeight: 600, fontVariantNumeric: 'tabular-nums', fontFamily: 'ui-monospace, monospace' }}>{r.v}</div>
              <div style={{ fontSize: 10.5, color: T.inkSoft, marginTop: 2 }}>{r.d}</div>
            </div>
          ))}
        </div>
      </div>

      {/* Palette */}
      <div style={{ marginBottom: 24 }}>
        <SectionLabel>Palette</SectionLabel>
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(8, 1fr)', gap: 10 }}>
          {[
            { c: T.bg,        n: 'Paper',       v: '#F1ECE2' },
            { c: 'rgba(232, 226, 212, 0.62)', n: 'Sidebar glass', v: 'paper 62%' },
            { c: T.card,      n: 'Card',        v: '#FFFFFF' },
            { c: T.ink,       n: 'Ink',         v: '#1B1814' },
            { c: T.teal,      n: 'Teal',        v: '#1E9085' },
            { c: T.tealSoft,  n: 'Teal soft',   v: '#D4ECE9' },
            { c: 'rgba(27, 24, 20, 0.97)', n: 'Player bar', v: 'ink 97%' },
            { c: T.red,       n: 'Alert',       v: '#C8443A' },
          ].map(s => (
            <div key={s.n}>
              <div style={{ height: 46, borderRadius: 8, background: s.c, border: '0.5px solid ' + T.hair }} />
              <div style={{ fontSize: 11.5, color: T.ink, fontWeight: 600, marginTop: 5 }}>{s.n}</div>
              <div style={{ fontSize: 10, color: T.inkMute, fontFamily: 'ui-monospace, monospace' }}>{s.v}</div>
            </div>
          ))}
        </div>
      </div>

      {/* Controls */}
      <div>
        <SectionLabel>Controls</SectionLabel>
        <div style={{ background: T.card, borderRadius: 10, padding: 16, display: 'flex', flexWrap: 'wrap', gap: 12, alignItems: 'center' }}>
          <MIconButton icon="play" label="Resume" primary />
          <MIconButton icon="sort" label="Recent" />
          <MIconButton icon="search" />
          <MSegmented value="grid" options={[{ value: 'grid', icon: 'books', label: 'Grid' }, { value: 'list', icon: 'list', label: 'List' }]} />
          <Checkbox checked label="Resume the last book" />
          <Hotkey label="Play / Pause" keys={['Space']} />
          <Hotkey label="Bookmark" keys={['⌘', 'B']} />
        </div>
      </div>
    </div>
  );
}

function SectionLabel({ children }) {
  return (
    <div style={{ fontSize: 11, fontWeight: 700, color: T.inkMute, letterSpacing: 0.6, textTransform: 'uppercase', marginBottom: 8 }}>{children}</div>
  );
}

// ── Interactive prototype (Mac) ───────────────────────────
function MacInteractive() {
  const [view, setView] = React.useState('all-books');
  const [grid, setGrid] = React.useState('grid');
  const [playing, setPlaying] = React.useState(true);
  const [expanded, setExpanded] = React.useState(false);
  const [prefs, setPrefs] = React.useState(false);

  const handleSelect = (v) => {
    if (v === 'settings') setPrefs(true);
    else setView(v);
  };

  return (
    <div style={{ position: 'relative', width: 1280, height: 820 }}>
      <AudioLibWindow
        width={1280} height={820}
        sidebar={<MSidebar active={view} onSelect={handleSelect} />}
        playerBar={<MPlayerBar playing={playing} onTogglePlay={() => setPlaying(p => !p)} onExpand={() => setExpanded(true)} />}>
        {(view === 'all-books' || view === 'continue' || view === 'recent' || view === 'finished') && (
          <>
            <MToolbar
              title={{ 'all-books': 'All Books', continue: 'Continue Listening', recent: 'Recently Added', finished: 'Finished' }[view]}
              subtitle="7 books · 2.84 GB"
              trailing={<div style={{ display: 'flex', gap: 6, alignItems: 'center' }}>
                <MSegmented value={grid} onChange={setGrid} options={[
                  { value: 'grid', icon: 'books', label: 'Grid' },
                  { value: 'list', icon: 'list',  label: 'List' },
                ]} />
                <div style={{ width: 1, height: 18, background: 'rgba(27,24,20,0.1)', margin: '0 4px' }} />
                <MIconButton icon="sort" label="Recent" />
                <MIconButton icon="search" />
              </div>}
            />
            <div style={{ flex: 1, display: 'flex', minHeight: 0 }}>
              <div style={{ flex: 1, overflowY: 'auto' }}>
                {grid === 'grid' ? <MLibraryGrid /> : <LibraryListBody />}
              </div>
              <MBookInspector book={BOOKS.habits} />
            </div>
          </>
        )}
        {(view === 'downloads' || view === 'completed') && <MDownloadsView />}
        {(view === 'all-notes' || view === 'linked-notes') && <MNotesView />}
        {(view === 'series-dune' || view === 'series-rep') && (
          <>
            <MToolbar title={view === 'series-dune' ? 'Dune' : 'Remembrance of Earth\'s Past'} subtitle="Series · 1 book" />
            <div style={{ padding: 24 }}><MBookCard book={view === 'series-dune' ? BOOKS.dune : BOOKS.threebody} big /></div>
          </>
        )}
      </AudioLibWindow>

      {expanded && <MPlayerExpanded onCollapse={() => setExpanded(false)} />}
      {prefs && (
        <div style={{ position: 'absolute', inset: 0, display: 'flex', alignItems: 'center', justifyContent: 'center', background: 'rgba(0,0,0,0.18)' }} onClick={() => setPrefs(false)}>
          <div onClick={(e) => e.stopPropagation()}><MPreferences /></div>
        </div>
      )}
    </div>
  );
}

function LibraryListBody() {
  const books = [BOOKS.habits, BOOKS.sapiens, BOOKS.hailmary, BOOKS.dune, BOOKS.threebody, BOOKS.gatsby, BOOKS.educated, BOOKS.becoming];
  return (
    <>
      <div style={{
        display: 'grid', gridTemplateColumns: '40px 2.4fr 1.6fr 0.8fr 1.3fr 1.4fr',
        padding: '8px 24px', fontSize: 10.5, fontWeight: 700,
        color: T.inkMute, letterSpacing: 0.5, textTransform: 'uppercase',
        borderBottom: '0.5px solid rgba(27,24,20,0.08)',
        position: 'sticky', top: 0, background: 'rgba(241,236,226,0.94)', backdropFilter: 'blur(20px)',
      }}>
        <div></div><div>Title</div><div>Author</div>
        <div style={{ textAlign: 'right' }}>Duration</div>
        <div>Progress</div>
        <div style={{ textAlign: 'right' }}>Last played</div>
      </div>
      {books.map((b, i) => (
        <div key={b.id} style={{
          display: 'grid', gridTemplateColumns: '40px 2.4fr 1.6fr 0.8fr 1.3fr 1.4fr',
          padding: '10px 24px',
          borderBottom: i < books.length - 1 ? '0.5px solid ' + T.hair : 'none',
          alignItems: 'center', cursor: 'pointer',
          background: i === 0 ? 'rgba(30,144,133,0.07)' : 'transparent',
        }}>
          <Cover which={b.id} size={32} radius={4} />
          <div style={{ fontSize: 13, fontWeight: 600, color: T.ink, letterSpacing: -0.2, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis', paddingRight: 8 }}>{b.title}</div>
          <div style={{ fontSize: 12.5, color: T.inkSoft, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis', paddingRight: 8 }}>{b.author}</div>
          <div style={{ fontSize: 12, color: T.inkSoft, fontVariantNumeric: 'tabular-nums', fontFamily: 'ui-monospace, monospace', textAlign: 'right', paddingRight: 16 }}>
            {b.progress === 0 ? '—' : b.progress === 1 ? '6h 22m' : b.remain}
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
            <div style={{ flex: 1 }}><ProgressBar value={b.progress} height={3} color={b.progress === 1 ? T.teal : T.ink} /></div>
            <span style={{ fontSize: 10.5, color: T.inkMute, width: 30, textAlign: 'right', fontVariantNumeric: 'tabular-nums' }}>{Math.round(b.progress * 100)}%</span>
          </div>
          <div style={{ fontSize: 11.5, color: T.inkMute, textAlign: 'right', fontVariantNumeric: 'tabular-nums' }}>
            {['Just now', '2h ago', 'Yesterday', '3d ago', '1w ago', 'Sep 12', 'Aug 28', 'Never'][i]}
          </div>
        </div>
      ))}
    </>
  );
}

// ── App composition ───────────────────────────────────────
function App() {
  return (
    <DesignCanvas>
      <DCSection id="prototype" title="Interactive Prototype"
        subtitle="Click sidebar items, tap the player bar's chevron-up to expand, the Preferences… link in the sidebar footer, etc.">
        <DCArtboard id="live" label="Live Mac app" width={1280} height={820}>
          <MacInteractive />
        </DCArtboard>
      </DCSection>

      <DCSection id="library" title="Library" subtitle="Three-column layout: source list · book grid/list · inspector. Persistent player bar at the bottom.">
        <DCArtboard id="grid" label="Library — Grid (default)" width={1280} height={820}>
          <MacFrame><LibraryView /></MacFrame>
        </DCArtboard>
        <DCArtboard id="list" label="Library — List" width={1280} height={820}>
          <MacFrame><LibraryListView /></MacFrame>
        </DCArtboard>
        <DCArtboard id="empty-lib" label="Library — Empty" width={1280} height={820}>
          <MacFrame><EmptyLibraryView /></MacFrame>
        </DCArtboard>
      </DCSection>

      <DCSection id="downloads" title="Downloads">
        <DCArtboard id="dl" label="Downloads" width={1280} height={820}>
          <MacFrame><MDownloadsView /></MacFrame>
        </DCArtboard>
      </DCSection>

      <DCSection id="notes" title="Notes">
        <DCArtboard id="notes-edit" label="Notes — Two-pane editor" width={1280} height={820}>
          <MacFrame><MNotesView /></MacFrame>
        </DCArtboard>
      </DCSection>

      <DCSection id="player" title="Player — Now Playing (expanded)" subtitle="Full-window dark immersive view. Player bar hides; press ⇩ to collapse back.">
        <DCArtboard id="player-exp" label="Now Playing" width={1280} height={820}>
          <div style={{ width: 1280, height: 820, borderRadius: 14, overflow: 'hidden', position: 'relative', boxShadow: '0 0 0 0.5px rgba(0,0,0,0.22), 0 24px 60px rgba(0,0,0,0.30)' }}>
            <MPlayerExpanded />
          </div>
        </DCArtboard>
      </DCSection>

      <DCSection id="aux" title="Auxiliary Windows" subtitle="Preferences, mini-player floating window, menu bar extra.">
        <DCArtboard id="prefs" label="Preferences" width={720} height={540}>
          <MPreferences />
        </DCArtboard>
        <DCArtboard id="mini" label="Mini Player (floating)" width={360} height={100}>
          <MMiniPlayer />
        </DCArtboard>
        <DCArtboard id="menu" label="Menu Bar Extra" width={320} height={320}>
          <div style={{ padding: 16 }}><MMenubarExtra /></div>
        </DCArtboard>
      </DCSection>

      <DCSection id="onboarding" title="Onboarding">
        <DCArtboard id="welcome" label="First launch" width={800} height={560}>
          <MOnboarding />
        </DCArtboard>
      </DCSection>

      <DCSection id="ds" title="Design System">
        <DCArtboard id="tokens" label="Tokens & components" width={880} height={720}>
          <MacDesignSystem />
        </DCArtboard>
      </DCSection>
    </DesignCanvas>
  );
}

ReactDOM.createRoot(document.getElementById('root')).render(<App />);
