// Main app — composes all screens into a design_canvas

// One phone with a single state, no internal navigation.
function Phone({ children, dark = false, width = 390, height = 832 }) {
  return (
    <IOSDevice width={width} height={height} dark={dark}>
      {children}
    </IOSDevice>
  );
}

// ─── Interactive prototype phone (Library → Player → Sheets) ───
function InteractivePhone() {
  const [tab, setTab] = React.useState('library');
  const [playerOpen, setPlayerOpen] = React.useState(false);
  const [sheet, setSheet] = React.useState(null);
  const [playing, setPlaying] = React.useState(true);
  const [settingsOpen, setSettingsOpen] = React.useState(false);
  const [editorOpen, setEditorOpen] = React.useState(false);
  const [editBookOpen, setEditBookOpen] = React.useState(false);

  return (
    <IOSDevice width={390} height={832} dark={playerOpen}>
      {/* Tab content */}
      {tab === 'download' && (
        <div style={{ position: 'absolute', inset: 0 }}>
          <DownloadInteractive onGear={() => setSettingsOpen(true)} />
        </div>
      )}
      {tab === 'library' && (
        <div style={{ position: 'absolute', inset: 0 }}>
          <LibraryInteractive
            onGear={() => setSettingsOpen(true)}
            onPlayBook={() => { setPlayerOpen(true); setPlaying(true); }}
            onEditBook={() => setEditBookOpen(true)}
          />
        </div>
      )}
      {tab === 'notes' && (
        <div style={{ position: 'absolute', inset: 0 }}>
          <NotesInteractive
            onGear={() => setSettingsOpen(true)}
            onOpenNote={() => setEditorOpen(true)}
          />
        </div>
      )}

      {/* Mini Player (visible on any tab when player is closed) */}
      {!playerOpen && (
        <MiniPlayer
          book={BOOKS.habits}
          playing={playing}
          onTap={() => setPlayerOpen(true)}
          onPlay={() => setPlaying(p => !p)}
        />
      )}

      {/* Tab bar */}
      <TabBar active={tab} onChange={setTab} />

      {/* Full Player overlay */}
      {playerOpen && (
        <div style={{ position: 'absolute', inset: 0, zIndex: 20, animation: 'slideUp 0.32s cubic-bezier(0.2,0.7,0.3,1)' }}>
          <PlayerInteractive
            playing={playing}
            onPlay={() => setPlaying(p => !p)}
            onClose={() => setPlayerOpen(false)}
            onSheet={(s) => setSheet(s)}
            sheet={sheet}
            onCloseSheet={() => setSheet(null)}
            onMore={() => setEditBookOpen(true)}
          />
        </div>
      )}

      {/* Settings overlay */}
      {settingsOpen && (
        <div style={{ position: 'absolute', inset: 0, zIndex: 25, animation: 'slideUp 0.28s cubic-bezier(0.2,0.7,0.3,1)' }}>
          <SettingsScreen />
          <button onClick={() => setSettingsOpen(false)} style={{
            position: 'absolute', top: 64, left: 16, zIndex: 5,
            width: 36, height: 36, borderRadius: 18, border: 'none', cursor: 'pointer',
            background: 'rgba(255,255,255,0.6)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
          }}>
            <Icon name="chevron-left" size={18} color={T.ink} strokeWidth={2.2} />
          </button>
        </div>
      )}

      {/* Note editor overlay */}
      {editorOpen && (
        <div style={{ position: 'absolute', inset: 0, zIndex: 25, animation: 'slideRight 0.28s cubic-bezier(0.2,0.7,0.3,1)' }}>
          <NoteEditor />
          <button onClick={() => setEditorOpen(false)} style={{
            position: 'absolute', top: 64, left: 12, zIndex: 5,
            width: 36, height: 36, borderRadius: 18, border: 'none', cursor: 'pointer',
            background: 'rgba(255,255,255,0.6)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
          }}>
            <Icon name="chevron-left" size={18} color={T.ink} strokeWidth={2.2} />
          </button>
        </div>
      )}

      {/* Edit book sheet */}
      {editBookOpen && (
        <div style={{ position: 'absolute', inset: 0, zIndex: 40 }} onClick={() => setEditBookOpen(false)}>
          <div style={{ position: 'absolute', inset: 0, background: 'rgba(0,0,0,0.45)' }} />
          <div onClick={(e) => e.stopPropagation()} style={{
            position: 'absolute', left: 0, right: 0, bottom: 0, height: '88%',
            background: T.bg, borderTopLeftRadius: 18, borderTopRightRadius: 18,
            overflow: 'hidden', display: 'flex', flexDirection: 'column',
            animation: 'sheetUp 0.32s cubic-bezier(0.2,0.7,0.3,1)',
          }}>
            <div style={{ display: 'flex', justifyContent: 'center', paddingTop: 6 }}>
              <div style={{ width: 36, height: 5, borderRadius: 3, background: 'rgba(0,0,0,0.18)' }} />
            </div>
            <div style={{ display: 'flex', alignItems: 'center', padding: '12px 16px 8px' }}>
              <button onClick={() => setEditBookOpen(false)} style={{ width: 60, fontSize: 16, color: T.ink, opacity: 0.7, background: 'none', border: 'none', textAlign: 'left', padding: 0, cursor: 'pointer' }}>Cancel</button>
              <div style={{ flex: 1, textAlign: 'center', fontSize: 16, fontWeight: 600, color: T.ink, letterSpacing: -0.3 }}>Edit Book</div>
              <button onClick={() => setEditBookOpen(false)} style={{ width: 60, textAlign: 'right', fontSize: 16, fontWeight: 600, color: T.teal, background: 'none', border: 'none', padding: 0, cursor: 'pointer' }}>Save</button>
            </div>
            <div style={{ flex: 1, overflow: 'auto' }}>
              <BookEditSheet standalone />
            </div>
          </div>
        </div>
      )}
    </IOSDevice>
  );
}

// Interactive wrappers — variants that accept handlers
function DownloadInteractive({ onGear }) {
  return (
    <div style={{ position: 'absolute', inset: 0, background: T.bg, paddingTop: 54, display: 'flex', flexDirection: 'column' }}>
      <div style={{ padding: '8px 16px 4px', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
        <div style={{ fontFamily: 'Georgia, serif', fontSize: 28, fontWeight: 700, color: T.ink, letterSpacing: -0.5 }}>Download</div>
        <button onClick={onGear} style={{
          width: 36, height: 36, borderRadius: 18, border: 'none', cursor: 'pointer',
          background: 'rgba(255,255,255,0.6)', display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}><Icon name="gear" size={18} color={T.ink} /></button>
      </div>
      <div style={{ overflowY: 'auto', flex: 1, paddingBottom: 200 }}>
        <div style={{ paddingTop: 8 }}>
          <DownloadCard url={'youtube.com/watch?v=dQw4w9WgXcQ'} />
        </div>
        <SectionHeader>Active</SectionHeader>
        <div style={{ padding: '0 16px' }}>
          <DownloadRow title="Brandon Sanderson — Words of Radiance" state="Downloading 64%" pct={64} speed="2.4 MB/s" eta="~3 min left" sizeText="184 MB of 287 MB" canStream source="m4a" />
          <DownloadRow title="The Midnight Library — Matt Haig" state="Mac downloading…" pct={28} speed="—" eta="~7 min left" sizeText="41 MB of 146 MB" source="Companion" />
          <DownloadRow title="Atomic Habits — James Clear" state="Done" pct={100} sizeText="142 MB" eta="Just added" />
        </div>
      </div>
    </div>
  );
}

function LibraryInteractive({ onGear, onPlayBook }) {
  const books = [BOOKS.sapiens, BOOKS.hailmary, BOOKS.dune, BOOKS.threebody, BOOKS.gatsby, BOOKS.educated];
  return (
    <div style={{ position: 'absolute', inset: 0, background: T.bg, paddingTop: 54, display: 'flex', flexDirection: 'column' }}>
      <div style={{ padding: '8px 16px 4px', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
        <div style={{ fontFamily: 'Georgia, serif', fontSize: 28, fontWeight: 700, color: T.ink, letterSpacing: -0.5 }}>Library</div>
        <div style={{ display: 'flex', gap: 8 }}>
          <button style={{ width: 36, height: 36, borderRadius: 18, border: 'none', cursor: 'pointer', background: 'rgba(255,255,255,0.6)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}><Icon name="sort" size={18} color={T.ink} /></button>
          <button onClick={onGear} style={{ width: 36, height: 36, borderRadius: 18, border: 'none', cursor: 'pointer', background: 'rgba(255,255,255,0.6)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}><Icon name="gear" size={18} color={T.ink} /></button>
        </div>
      </div>
      <div style={{ padding: '10px 16px 8px' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8, background: 'rgba(255,255,255,0.7)', borderRadius: 12, padding: '10px 12px' }}>
          <Icon name="search" size={16} color={T.inkSoft} />
          <span style={{ flex: 1, fontSize: 14.5, color: T.inkMute }}>Search title or author</span>
        </div>
      </div>
      <div style={{ overflowY: 'auto', flex: 1, paddingBottom: 168 }}>
        <div onClick={onPlayBook} style={{ cursor: 'pointer' }}>
          <ContinueListening book={BOOKS.habits} />
        </div>
        <SectionHeader>All books · 7</SectionHeader>
        <div style={{ margin: '0 16px', background: T.card, borderRadius: 18, overflow: 'hidden' }}>
          {books.map((b, i) => (
            <div key={b.id} onClick={onPlayBook} style={{ cursor: 'pointer' }}>
              <LibraryRow book={b} />
              {i < books.length - 1 && <div style={{ height: 0.5, background: T.hair, marginLeft: 92 }} />}
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}

function NotesInteractive({ onGear, onOpenNote }) {
  const notes = [
    { title: 'On habits & identity', time: '2 hours ago', linked: true,  snippet: 'Every action is a vote for the type of person you wish to become.' },
    { title: 'Reading queue, Q3',    time: 'Yesterday',   linked: false, snippet: 'Hail Mary → Three-Body Problem → Educated → Becoming.' },
    { title: 'Gatsby — green light', time: '3 days ago',  linked: true,  snippet: 'Symbol of unreachable hope. Compare to Daisy\'s dock.' },
    { title: 'Sleep, attention, focus', time: 'Last week', linked: false, snippet: 'Three pillars from Huberman ep. Track for 30 days.' },
  ];
  return (
    <div style={{ position: 'absolute', inset: 0, background: T.bg, paddingTop: 54, display: 'flex', flexDirection: 'column' }}>
      <div style={{ padding: '8px 16px 4px', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
        <div style={{ fontFamily: 'Georgia, serif', fontSize: 28, fontWeight: 700, color: T.ink, letterSpacing: -0.5 }}>Notes</div>
        <div style={{ display: 'flex', gap: 8 }}>
          <button onClick={onGear} style={{ width: 36, height: 36, borderRadius: 18, border: 'none', cursor: 'pointer', background: 'rgba(255,255,255,0.6)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}><Icon name="gear" size={18} color={T.ink} /></button>
          <button onClick={onOpenNote} style={{ width: 36, height: 36, borderRadius: 18, border: 'none', cursor: 'pointer', background: T.ink, display: 'flex', alignItems: 'center', justifyContent: 'center' }}><Icon name="plus" size={18} color="#F4ECDB" strokeWidth={2.2} /></button>
        </div>
      </div>
      <div style={{ overflowY: 'auto', flex: 1, paddingBottom: 168 }}>
        <div style={{ margin: '8px 16px 0', background: T.card, borderRadius: 18, overflow: 'hidden' }}>
          {notes.map((n, i) => (
            <div key={n.title} onClick={onOpenNote} style={{ cursor: 'pointer' }}>
              <NoteRow {...n} />
              {i < notes.length - 1 && <div style={{ height: 0.5, background: T.hair, marginLeft: 36 }} />}
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}

function PlayerInteractive({ playing, onPlay, onClose, onSheet, sheet, onCloseSheet, onMore }) {
  return (
    <div style={{
      position: 'absolute', inset: 0,
      background: 'linear-gradient(180deg, #1B4B7A 0%, #0E1E33 60%, #0A0A12 100%)',
      paddingTop: 54, color: T.dInk,
      display: 'flex', flexDirection: 'column', overflow: 'hidden',
    }}>
      <div style={{ padding: '10px 16px', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
        <button onClick={onClose} style={{
          width: 36, height: 36, borderRadius: 18, border: 'none', cursor: 'pointer',
          background: 'rgba(255,255,255,0.12)', display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}><Icon name="chevron-down" size={18} color="#fff" strokeWidth={2.2} /></button>
        <div style={{ textAlign: 'center' }}>
          <div style={{ fontSize: 11, color: T.dInkSoft, letterSpacing: 0.6, textTransform: 'uppercase', fontWeight: 600 }}>Playing from Library</div>
          <div style={{ fontSize: 13, color: '#fff', fontWeight: 600, letterSpacing: -0.1, marginTop: 1 }}>Atomic Habits</div>
        </div>
        <button onClick={onMore} style={{
          width: 36, height: 36, borderRadius: 18, border: 'none', cursor: 'pointer',
          background: 'rgba(255,255,255,0.12)', display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}><Icon name="more" size={18} color="#fff" /></button>
      </div>
      <div style={{ flex: '0 0 auto', display: 'flex', justifyContent: 'center', padding: '24px 32px 12px' }}>
        <Cover which="habits" size={310} radius={14} />
      </div>
      <div style={{ padding: '20px 24px 0' }}>
        <div style={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between', gap: 12 }}>
          <div style={{ flex: 1, minWidth: 0 }}>
            <div style={{ fontFamily: 'Georgia, serif', fontSize: 24, fontWeight: 700, letterSpacing: -0.4, color: '#fff', lineHeight: 1.1 }}>Atomic Habits</div>
            <div style={{ fontSize: 14.5, color: T.dInkSoft, marginTop: 4 }}>James Clear</div>
          </div>
        </div>
      </div>
      <div style={{ padding: '24px 24px 8px' }}>
        <div style={{ height: 4, borderRadius: 2, background: 'rgba(255,255,255,0.15)', position: 'relative' }}>
          <div style={{ width: '38%', height: '100%', borderRadius: 2, background: '#fff' }} />
          <div style={{ position: 'absolute', left: '38%', top: '50%', width: 12, height: 12, borderRadius: 6, background: '#fff', transform: 'translate(-50%, -50%)', boxShadow: '0 2px 6px rgba(0,0,0,0.3)' }} />
        </div>
        <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: 6, fontSize: 11, color: T.dInkMute, fontVariantNumeric: 'tabular-nums' }}>
          <span>2:14:08</span><span>-3:47:22</span>
        </div>
      </div>
      <div style={{ padding: '12px 24px 24px', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
        <button style={{ background: 'none', border: 'none', cursor: 'pointer', padding: 0 }}><SkipIcon dir="back" seconds={15} /></button>
        <button onClick={onPlay} style={{
          width: 72, height: 72, borderRadius: 36, border: 'none', cursor: 'pointer',
          background: '#fff', display: 'flex', alignItems: 'center', justifyContent: 'center',
          boxShadow: '0 6px 20px rgba(0,0,0,0.35)',
        }}><Icon name={playing ? 'pause' : 'play'} size={28} color={T.ink} /></button>
        <button style={{ background: 'none', border: 'none', cursor: 'pointer', padding: 0 }}><SkipIcon dir="fwd" seconds={15} /></button>
      </div>
      <div style={{ padding: '0 16px 36px', display: 'flex', justifyContent: 'space-around', alignItems: 'center' }}>
        <ClickableSecondary onClick={() => onSheet('speed')} icon={<span style={{ fontSize: 14, fontWeight: 700, letterSpacing: -0.2 }}>1.5×</span>} label="Speed" />
        <ClickableSecondary onClick={() => onSheet('sleep')} icon={<Icon name="moon" size={18} color={T.teal} fill={T.teal} strokeWidth={0} />} label="22:13" active />
        <ClickableSecondary onClick={() => onSheet('chapters')} icon={<Icon name="list" size={20} color={T.dInkSoft} strokeWidth={1.9} />} label="Chapters" />
        <ClickableSecondary onClick={() => onSheet('bookmarks')} icon={<Icon name="bookmark" size={18} color={T.dInkSoft} strokeWidth={1.9} />} label="Marks" />
      </div>

      {sheet && (
        <div onClick={onCloseSheet} style={{ position: 'absolute', inset: 0, zIndex: 30 }}>
          <div onClick={(e) => e.stopPropagation()} style={{ position: 'absolute', inset: 0, animation: 'sheetUp 0.3s cubic-bezier(0.2,0.7,0.3,1)' }}>
            <PlayerSheet which={sheet} />
            <button onClick={onCloseSheet} style={{
              position: 'absolute', top: 'auto', bottom: 0, left: 16, padding: 0,
              background: 'transparent', border: 'none', color: T.teal, cursor: 'pointer',
              fontSize: 16, fontWeight: 600,
              display: 'none',
            }}>Done</button>
          </div>
        </div>
      )}
    </div>
  );
}

function ClickableSecondary({ icon, label, active, onClick }) {
  return (
    <button onClick={onClick} style={{
      background: 'none', border: 'none', cursor: 'pointer', padding: 0,
      display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 5, minWidth: 56,
    }}>
      <div style={{
        width: 44, height: 32, borderRadius: 16,
        background: active ? 'rgba(30,144,133,0.2)' : 'rgba(255,255,255,0.06)',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        color: active ? T.teal : T.dInkSoft,
      }}>{icon}</div>
      <div style={{ fontSize: 10.5, color: active ? T.teal : T.dInkMute, fontWeight: 500, fontVariantNumeric: 'tabular-nums' }}>{label}</div>
    </button>
  );
}

// ─── Compose canvas ────────────────────────────────────────
function App() {
  return (
    <DesignCanvas>
      <DCSection id="prototype" title="Interactive Prototype" subtitle="Tap anything — Library → Player → Sheets all wired up. Try the gear icon, the + on Notes, the ••• on the player.">
        <DCArtboard id="live" label="Live prototype" width={390} height={832}>
          <InteractivePhone />
        </DCArtboard>
      </DCSection>

      <DCSection id="onboarding" title="Onboarding & First Launch" subtitle="Shown once, then never again.">
        <DCArtboard id="onboard" label="Welcome" width={390} height={832}>
          <Phone><OnboardingScreen /></Phone>
        </DCArtboard>
      </DCSection>

      <DCSection id="empty" title="Empty States" subtitle="What every tab looks like on a fresh install.">
        <DCArtboard id="dl-empty" label="Download · empty" width={390} height={832}>
          <Phone><DownloadScreen populated={false} /></Phone>
        </DCArtboard>
        <DCArtboard id="lib-empty" label="Library · empty" width={390} height={832}>
          <Phone><LibraryScreen empty /></Phone>
        </DCArtboard>
        <DCArtboard id="notes-empty" label="Notes · empty" width={390} height={832}>
          <Phone><NotesScreen empty /></Phone>
        </DCArtboard>
      </DCSection>

      <DCSection id="tabs" title="Three Tabs" subtitle="Populated states. MiniPlayer is persistent above the tab bar whenever a book is loaded.">
        <DCArtboard id="dl" label="Download · active" width={390} height={832}>
          <Phone><DownloadScreen populated /></Phone>
        </DCArtboard>
        <DCArtboard id="lib" label="Library · w/ MiniPlayer" width={390} height={832}>
          <Phone><LibraryScreen withMiniPlayer /></Phone>
        </DCArtboard>
        <DCArtboard id="notes" label="Notes · populated" width={390} height={832}>
          <Phone><NotesScreen /></Phone>
        </DCArtboard>
        <DCArtboard id="editor" label="Note Editor" width={390} height={832}>
          <Phone><NoteEditor /></Phone>
        </DCArtboard>
      </DCSection>

      <DCSection id="player" title="Player" subtitle="Full-screen sheet, dark theme, four secondary controls each open a modal.">
        <DCArtboard id="player-main" label="Player" width={390} height={832}>
          <Phone dark><PlayerScreen /></Phone>
        </DCArtboard>
        <DCArtboard id="player-speed" label="+ Speed" width={390} height={832}>
          <Phone dark><PlayerScreen activeSheet="speed" /></Phone>
        </DCArtboard>
        <DCArtboard id="player-sleep" label="+ Sleep Timer" width={390} height={832}>
          <Phone dark><PlayerScreen activeSheet="sleep" /></Phone>
        </DCArtboard>
        <DCArtboard id="player-chapters" label="+ Chapters" width={390} height={832}>
          <Phone dark><PlayerScreen activeSheet="chapters" /></Phone>
        </DCArtboard>
        <DCArtboard id="player-bookmarks" label="+ Bookmarks" width={390} height={832}>
          <Phone dark><PlayerScreen activeSheet="bookmarks" /></Phone>
        </DCArtboard>
      </DCSection>

      <DCSection id="modals" title="Modals & Settings">
        <DCArtboard id="edit-book" label="Edit Book" width={390} height={832}>
          <Phone>
            <div style={{ position: 'absolute', inset: 0, background: 'rgba(0,0,0,0.45)' }}>
              {/* Show library faintly behind */}
            </div>
            <div style={{ position: 'absolute', inset: 0, opacity: 0.3 }}>
              <LibraryScreen withMiniPlayer />
            </div>
            <BookEditSheet />
          </Phone>
        </DCArtboard>
        <DCArtboard id="settings" label="Settings" width={390} height={832}>
          <Phone><SettingsScreen /></Phone>
        </DCArtboard>
      </DCSection>

      <DCSection id="system" title="Design System" subtitle="Type, color, components.">
        <DCArtboard id="ds" label="Tokens" width={760} height={832}>
          <DesignSystem />
        </DCArtboard>
      </DCSection>
    </DesignCanvas>
  );
}

// ─── Design system reference ──────────────────────────────
function DesignSystem() {
  return (
    <div style={{ width: 760, height: 832, background: T.bg, padding: 32, fontFamily: '-apple-system, system-ui', overflow: 'hidden' }}>
      <div style={{
        fontFamily: 'Georgia, serif', fontSize: 32, fontWeight: 700, color: T.ink,
        letterSpacing: -0.5, marginBottom: 4,
      }}>AudioLib — design tokens</div>
      <div style={{ fontSize: 14, color: T.inkSoft, marginBottom: 28 }}>
        Warm paper light · ink near-black · teal accent · deep-blue player.
      </div>

      {/* Type */}
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 24, marginBottom: 28 }}>
        <div>
          <div style={{ fontSize: 11, color: T.inkMute, textTransform: 'uppercase', letterSpacing: 0.5, fontWeight: 700, marginBottom: 10 }}>Display · Georgia</div>
          <div style={{ fontFamily: 'Georgia, serif', fontSize: 36, fontWeight: 700, color: T.ink, letterSpacing: -0.6, lineHeight: 1.05 }}>Atomic Habits</div>
          <div style={{ fontFamily: 'Georgia, serif', fontSize: 22, fontWeight: 700, color: T.ink, letterSpacing: -0.4, marginTop: 4 }}>The Three-Body Problem</div>
          <div style={{ fontFamily: 'Georgia, serif', fontSize: 14, fontStyle: 'italic', color: T.inkSoft, marginTop: 6 }}>F. Scott Fitzgerald</div>
        </div>
        <div>
          <div style={{ fontSize: 11, color: T.inkMute, textTransform: 'uppercase', letterSpacing: 0.5, fontWeight: 700, marginBottom: 10 }}>UI · SF Pro</div>
          <div style={{ fontSize: 22, fontWeight: 700, color: T.ink, letterSpacing: -0.4 }}>Continue listening</div>
          <div style={{ fontSize: 15, fontWeight: 600, color: T.ink, marginTop: 6 }}>Body — 15/600 letter-spacing -0.2</div>
          <div style={{ fontSize: 13.5, color: T.inkSoft, marginTop: 4 }}>Secondary — 13.5 regular, 62% ink</div>
          <div style={{ fontSize: 11, color: T.inkMute, marginTop: 4, fontFamily: 'ui-monospace, monospace', fontVariantNumeric: 'tabular-nums' }}>02:14:08 · monospace tabular</div>
        </div>
      </div>

      {/* Color swatches */}
      <div style={{ fontSize: 11, color: T.inkMute, textTransform: 'uppercase', letterSpacing: 0.5, fontWeight: 700, marginBottom: 10 }}>Palette</div>
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(7, 1fr)', gap: 10, marginBottom: 24 }}>
        {[
          { c: T.bg,    n: 'Paper',  v: '#F1ECE2' },
          { c: T.card,  n: 'Card',   v: '#FFFFFF' },
          { c: T.ink,   n: 'Ink',    v: '#1B1814' },
          { c: T.teal,  n: 'Teal',   v: '#1E9085' },
          { c: T.tealSoft, n: 'Teal soft', v: '#D4ECE9' },
          { c: T.dBg,   n: 'Player', v: '#0D0D10' },
          { c: T.red,   n: 'Alert',  v: '#C8443A' },
        ].map(s => (
          <div key={s.n}>
            <div style={{ height: 56, borderRadius: 10, background: s.c, border: '0.5px solid ' + T.hair }} />
            <div style={{ fontSize: 11.5, color: T.ink, fontWeight: 600, marginTop: 6 }}>{s.n}</div>
            <div style={{ fontSize: 10, color: T.inkMute, fontFamily: 'ui-monospace, monospace' }}>{s.v}</div>
          </div>
        ))}
      </div>

      {/* Components */}
      <div style={{ fontSize: 11, color: T.inkMute, textTransform: 'uppercase', letterSpacing: 0.5, fontWeight: 700, marginBottom: 10 }}>Components</div>
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 20 }}>
        <div style={{ background: T.card, borderRadius: 14, padding: 14 }}>
          <div style={{ fontSize: 11, color: T.inkMute, marginBottom: 8 }}>Buttons</div>
          <div style={{ display: 'flex', gap: 8, alignItems: 'center', flexWrap: 'wrap' }}>
            <button style={{ background: T.ink, color: '#F4ECDB', border: 'none', borderRadius: 12, padding: '10px 18px', fontSize: 14, fontWeight: 600, cursor: 'pointer' }}>Primary</button>
            <button style={{ background: T.teal, color: '#fff', border: 'none', borderRadius: 12, padding: '10px 18px', fontSize: 14, fontWeight: 600, cursor: 'pointer' }}>Teal</button>
            <button style={{ background: T.tealSoft, color: T.tealInk, border: 'none', borderRadius: 12, padding: '10px 18px', fontSize: 14, fontWeight: 600, cursor: 'pointer' }}>Soft</button>
            <button style={{ background: 'transparent', color: T.red, border: 'none', borderRadius: 12, padding: '10px 14px', fontSize: 14, fontWeight: 600, cursor: 'pointer' }}>Destructive</button>
          </div>
        </div>
        <div style={{ background: T.card, borderRadius: 14, padding: 14 }}>
          <div style={{ fontSize: 11, color: T.inkMute, marginBottom: 8 }}>Progress</div>
          <ProgressBar value={0.34} height={4} />
          <div style={{ height: 8 }} />
          <ProgressBar value={0.72} height={3} color={T.ink} />
          <div style={{ height: 8 }} />
          <ProgressBar value={1.0} height={3} color={T.teal} />
        </div>
        <div style={{ background: T.card, borderRadius: 14, padding: 14, gridColumn: 'span 2', display: 'flex', gap: 14, alignItems: 'center' }}>
          <div style={{ fontSize: 11, color: T.inkMute, width: 80 }}>Covers</div>
          {['gatsby','sapiens','habits','hailmary','dune','threebody','educated'].map(c => <Cover key={c} which={c} size={56} radius={6} />)}
        </div>
      </div>
    </div>
  );
}

ReactDOM.createRoot(document.getElementById('root')).render(<App />);
