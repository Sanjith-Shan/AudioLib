// Mac AudioLib — screen views

// ─── Book Grid (Library main view) ─────────────────────────
function MBookCard({ book, big = false, onClick }) {
  const cs = big ? 168 : 132;
  return (
    <div onClick={onClick} style={{
      width: cs, cursor: 'pointer', position: 'relative',
    }}>
      <div style={{ position: 'relative' }}>
        <Cover which={book.id} size={cs} radius={8} />
        {/* Hover play overlay (simulate one card as hovered) */}
        {book.hover && (
          <div style={{
            position: 'absolute', inset: 0, borderRadius: 8,
            background: 'rgba(0,0,0,0.35)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
          }}>
            <div style={{
              width: 44, height: 44, borderRadius: 22, background: '#F4ECDB',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              boxShadow: '0 4px 12px rgba(0,0,0,0.35)',
            }}>
              <Icon name="play" size={18} color={T.ink} />
            </div>
          </div>
        )}
        {book.progress > 0 && book.progress < 1 && (
          <div style={{
            position: 'absolute', left: 6, right: 6, bottom: 6,
            height: 3, borderRadius: 2, background: 'rgba(0,0,0,0.45)',
          }}>
            <div style={{ width: `${book.progress * 100}%`, height: '100%', background: '#F4ECDB', borderRadius: 2 }} />
          </div>
        )}
        {book.progress === 1 && (
          <div style={{
            position: 'absolute', top: 6, right: 6,
            width: 20, height: 20, borderRadius: 10, background: T.teal,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            boxShadow: '0 2px 6px rgba(0,0,0,0.3)',
          }}>
            <Icon name="check" size={12} color="#fff" strokeWidth={2.6} />
          </div>
        )}
      </div>
      <div style={{
        fontSize: 13, fontWeight: 600, color: T.ink, marginTop: 8,
        letterSpacing: -0.2, lineHeight: 1.2,
        overflow: 'hidden', display: '-webkit-box', WebkitLineClamp: 2, WebkitBoxOrient: 'vertical',
      }}>{book.title}</div>
      <div style={{
        fontSize: 11.5, color: T.inkSoft, marginTop: 2,
        whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis',
      }}>{book.author}</div>
      {book.progress > 0 && book.progress < 1 && (
        <div style={{ fontSize: 10.5, color: T.inkMute, marginTop: 1, fontVariantNumeric: 'tabular-nums' }}>{book.remain} left</div>
      )}
    </div>
  );
}

function MLibraryGrid({ onOpenBook }) {
  const featured = { ...BOOKS.habits, hover: true };
  const cards = [
    BOOKS.sapiens, BOOKS.hailmary, BOOKS.dune, BOOKS.threebody,
    BOOKS.gatsby, BOOKS.educated, BOOKS.becoming,
    { ...BOOKS.habits },
  ];
  return (
    <div style={{ padding: '20px 24px 36px' }}>
      {/* Continue Listening hero strip */}
      <div style={{
        background: 'linear-gradient(135deg, #11332E 0%, #1B5751 100%)',
        borderRadius: 14, padding: 22,
        color: '#F4ECDB',
        display: 'flex', gap: 22, alignItems: 'center',
        marginBottom: 28,
        boxShadow: '0 4px 20px rgba(17,51,46,0.18)',
      }}>
        <Cover which={featured.id} size={132} radius={10} />
        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{ fontSize: 10.5, fontWeight: 700, letterSpacing: 1.2, textTransform: 'uppercase', color: 'rgba(244,236,219,0.55)' }}>Continue listening</div>
          <div style={{
            fontFamily: 'Georgia, serif', fontSize: 28, fontWeight: 700,
            letterSpacing: -0.5, marginTop: 4, lineHeight: 1.1,
          }}>{featured.title}</div>
          <div style={{ fontSize: 14, color: 'rgba(244,236,219,0.7)', marginTop: 4 }}>{featured.author}</div>
          <div style={{ marginTop: 14, display: 'flex', alignItems: 'center', gap: 14 }}>
            <button style={{
              padding: '8px 18px', borderRadius: 10, border: 'none', cursor: 'pointer',
              background: '#F4ECDB', color: T.ink, fontSize: 13, fontWeight: 600, letterSpacing: -0.1,
              display: 'flex', alignItems: 'center', gap: 6, whiteSpace: 'nowrap',
            }}>
              <Icon name="play" size={12} color={T.ink} />
              Resume · {featured.remain} left
            </button>
            <button style={{
              padding: '8px 14px', borderRadius: 10, border: '0.5px solid rgba(244,236,219,0.25)',
              cursor: 'pointer', background: 'transparent', color: '#F4ECDB',
              fontSize: 13, fontWeight: 600, letterSpacing: -0.1,
            }}>Open</button>
          </div>
        </div>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 10, alignItems: 'flex-end', minWidth: 160 }}>
          <div style={{ fontSize: 11, color: 'rgba(244,236,219,0.6)' }}>Chapter 4 · The Man Who…</div>
          <div style={{ width: 180 }}>
            <ProgressBar value={featured.progress} height={3} color="#F4ECDB" track="rgba(244,236,219,0.18)" />
          </div>
          <div style={{ fontSize: 10.5, color: 'rgba(244,236,219,0.55)', fontVariantNumeric: 'tabular-nums' }}>2:14:08 / 5:58:12</div>
        </div>
      </div>

      {/* All books header */}
      <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between', marginBottom: 14 }}>
        <div style={{ fontFamily: 'Georgia, serif', fontSize: 20, fontWeight: 700, color: T.ink, letterSpacing: -0.3 }}>
          All Books
        </div>
        <div style={{ fontSize: 12, color: T.inkSoft }}>Sorted by Last Played</div>
      </div>

      {/* Grid */}
      <div style={{
        display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(132px, 1fr))',
        gap: '22px 22px',
      }}>
        {cards.map((b, i) => <MBookCard key={i} book={b} onClick={onOpenBook} />)}
      </div>
    </div>
  );
}

// ─── Book inspector (right rail) ───────────────────────────
function MBookInspector({ book = BOOKS.habits }) {
  const chapters = [
    { n: 1, t: 'The Fundamentals',         start: '00:00:00' },
    { n: 2, t: 'The Surprising Power of Atomic Habits', start: '00:32:14' },
    { n: 3, t: 'How Your Habits Shape Your Identity',   start: '01:09:42' },
    { n: 4, t: 'The Man Who Didn\'t Look Right',         start: '01:48:11', active: true },
    { n: 5, t: 'How to Start a New Habit', start: '02:35:50' },
    { n: 6, t: 'Motivation Is Overrated',  start: '03:14:09' },
    { n: 7, t: 'How to Make a Habit Irresistible',  start: '03:51:33' },
    { n: 8, t: 'The Secret to Self-Control', start: '04:22:18' },
  ];
  return (
    <div style={{
      width: 340, flexShrink: 0, height: '100%',
      borderLeft: '0.5px solid rgba(27,24,20,0.08)',
      background: 'rgba(255,255,255,0.55)',
      backdropFilter: 'blur(20px)',
      display: 'flex', flexDirection: 'column',
    }}>
      <div style={{ padding: '20px 22px 0' }}>
        <div style={{ display: 'flex', justifyContent: 'center', marginBottom: 18 }}>
          <Cover which={book.id} size={180} radius={10} />
        </div>
        <div style={{ fontFamily: 'Georgia, serif', fontSize: 22, fontWeight: 700, color: T.ink, letterSpacing: -0.4, lineHeight: 1.15 }}>{book.title}</div>
        <div style={{ fontSize: 14, color: T.inkSoft, marginTop: 4 }}>{book.author}</div>

        <div style={{ display: 'flex', gap: 8, marginTop: 14 }}>
          <button style={{
            flex: 1, padding: '9px 14px', borderRadius: 10, border: 'none', cursor: 'pointer',
            background: T.ink, color: '#F4ECDB', fontSize: 13, fontWeight: 600, letterSpacing: -0.1,
            display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 6, whiteSpace: 'nowrap',
          }}>
            <Icon name="play" size={12} color="#F4ECDB" />
            Resume · 3h 47m
          </button>
          <button style={{
            width: 36, height: 36, borderRadius: 10,
            background: 'rgba(27,24,20,0.06)', border: 'none', cursor: 'pointer',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            color: T.ink,
          }}><Icon name="bookmark" size={15} color={T.ink} strokeWidth={1.9} /></button>
          <button style={{
            width: 36, height: 36, borderRadius: 10,
            background: 'rgba(27,24,20,0.06)', border: 'none', cursor: 'pointer',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            color: T.ink,
          }}><Icon name="more" size={15} color={T.ink} /></button>
        </div>

        {/* Stats */}
        <div style={{
          marginTop: 18, padding: '12px 14px',
          background: 'rgba(255,255,255,0.6)', borderRadius: 10,
          display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 4,
        }}>
          {[
            { l: 'Duration', v: '5:58:12' },
            { l: 'Progress', v: '62%' },
            { l: 'Speed',    v: '1.5×' },
          ].map((s) => (
            <div key={s.l} style={{ textAlign: 'center' }}>
              <div style={{ fontSize: 13, fontWeight: 700, color: T.ink, fontVariantNumeric: 'tabular-nums', letterSpacing: -0.2 }}>{s.v}</div>
              <div style={{ fontSize: 10, color: T.inkMute, marginTop: 1, textTransform: 'uppercase', letterSpacing: 0.4, fontWeight: 600 }}>{s.l}</div>
            </div>
          ))}
        </div>
      </div>

      <div style={{ padding: '18px 22px 6px', fontSize: 11, fontWeight: 700, letterSpacing: 0.5, textTransform: 'uppercase', color: T.inkMute }}>
        Chapters
      </div>
      <div style={{ flex: 1, overflowY: 'auto', padding: '0 14px 16px' }}>
        {chapters.map((c) => (
          <div key={c.n} style={{
            display: 'flex', alignItems: 'center', gap: 10,
            padding: '8px 10px', borderRadius: 7, marginBottom: 1,
            background: c.active ? 'rgba(30,144,133,0.13)' : 'transparent',
            cursor: 'pointer',
          }}>
            <div style={{
              width: 18, color: c.active ? T.teal : T.inkMute,
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              fontSize: 11, fontWeight: 600, fontVariantNumeric: 'tabular-nums',
            }}>
              {c.active ? <Icon name="speaker" size={14} color={T.teal} strokeWidth={1.9} /> : c.n}
            </div>
            <div style={{ flex: 1, minWidth: 0, fontSize: 12.5, color: c.active ? T.tealInk : T.ink, fontWeight: c.active ? 600 : 500, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis', letterSpacing: -0.1 }}>{c.t}</div>
            <div style={{ fontSize: 10.5, color: c.active ? T.tealInk : T.inkSoft, fontFamily: 'ui-monospace, monospace', fontVariantNumeric: 'tabular-nums' }}>{c.start}</div>
          </div>
        ))}
      </div>
    </div>
  );
}

// ─── Downloads pane (Mac) ──────────────────────────────────
function MDownloadsView() {
  return (
    <div style={{ display: 'flex', flexDirection: 'column', height: '100%' }}>
      <MToolbar
        title="Downloads"
        subtitle="3 active · 1 failed · 12 completed"
        trailing={<>
          <MIconButton icon="sort" label="Sort" />
        </>}
      />
      <div style={{ flex: 1, overflowY: 'auto', padding: '20px 24px 24px' }}>
        {/* Add card */}
        <div style={{
          background: T.ink, color: '#F4ECDB', borderRadius: 14, padding: 20,
          marginBottom: 24,
          display: 'flex', alignItems: 'center', gap: 16,
        }}>
          <div style={{
            width: 44, height: 44, borderRadius: 11,
            background: 'rgba(255,255,255,0.1)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            flexShrink: 0,
          }}>
            <Icon name="link" size={18} color="#F4ECDB" />
          </div>
          <div style={{ flex: 1, minWidth: 0 }}>
            <div style={{ fontSize: 14, fontWeight: 600, letterSpacing: -0.2, marginBottom: 6 }}>Add an audiobook from YouTube</div>
            <div style={{
              background: 'rgba(255,255,255,0.08)', borderRadius: 9,
              padding: '9px 12px',
              fontSize: 13, color: 'rgba(244,236,219,0.85)',
              fontFamily: 'ui-monospace, monospace',
              border: '0.5px solid rgba(255,255,255,0.1)',
              whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis',
            }}>youtube.com/watch?v=dQw4w9WgXcQ</div>
          </div>
          <button style={{
            padding: '10px 18px', borderRadius: 10, border: 'none', cursor: 'pointer',
            background: '#F4ECDB', color: T.ink, fontSize: 13, fontWeight: 600, letterSpacing: -0.1,
            display: 'flex', alignItems: 'center', gap: 6, flexShrink: 0,
          }}>
            <Icon name="arrow-down-circle" size={14} color={T.ink} strokeWidth={1.9} />
            Download
          </button>
        </div>

        {/* Active list */}
        <div style={{ fontSize: 11, fontWeight: 700, color: T.inkMute, letterSpacing: 0.5, textTransform: 'uppercase', marginBottom: 8, paddingLeft: 4 }}>Active</div>
        <div style={{ background: T.card, borderRadius: 12, overflow: 'hidden' }}>
          {[
            { title: 'Brandon Sanderson — Words of Radiance (Full)', sub: 'Downloading · 2.4 MB/s · ~3 min left', pct: 64, partial: true, source: 'On-device · m4a', state: 'active' },
            { title: 'The Midnight Library — Matt Haig', sub: 'Mac downloading · Companion · ~7 min left', pct: 28, source: 'Companion', state: 'active' },
            { title: 'dQw4w9WgXcQ', sub: 'Fetching info…', pct: 0, source: '', state: 'queued' },
            { title: 'The Power Broker — Pt. 1', sub: 'Could not reach YouTube after 30s. Retry?', state: 'failed' },
          ].map((d, i, arr) => (
            <div key={i} style={{
              display: 'flex', alignItems: 'center', gap: 14,
              padding: '14px 16px',
              borderBottom: i < arr.length - 1 ? '0.5px solid ' + T.hair : 'none',
            }}>
              <div style={{
                width: 32, height: 32, borderRadius: 8, flexShrink: 0,
                background: d.state === 'failed' ? 'rgba(200,68,58,0.1)' : T.cardSoft,
                display: 'flex', alignItems: 'center', justifyContent: 'center',
              }}>
                {d.state === 'failed' ? <Icon name="wifi-x" size={16} color={T.red} /> :
                  d.state === 'queued' ? <div style={{ width: 14, height: 14, borderRadius: 7, border: '2px solid rgba(27,24,20,0.15)', borderTopColor: T.ink, animation: 'spin 0.8s linear infinite' }} /> :
                    <Icon name="arrow-down-circle" size={16} color={T.ink} strokeWidth={1.9} />}
              </div>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ fontSize: 13.5, fontWeight: 600, color: T.ink, letterSpacing: -0.2, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{d.title}</div>
                <div style={{ fontSize: 11.5, color: d.state === 'failed' ? T.red : T.inkSoft, marginTop: 2, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{d.sub}</div>
              </div>
              {d.pct !== undefined && d.state !== 'failed' && (
                <div style={{ width: 140, flexShrink: 0 }}>
                  <ProgressBar value={d.pct / 100} height={4} color={T.ink} />
                  <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 10.5, color: T.inkMute, marginTop: 4, fontVariantNumeric: 'tabular-nums' }}>
                    <span>{d.pct}%</span>
                    <span>{d.source}</span>
                  </div>
                </div>
              )}
              {d.partial && (
                <button style={{
                  padding: '6px 10px', borderRadius: 7,
                  background: T.tealSoft, color: T.tealInk, border: 'none', cursor: 'pointer',
                  fontSize: 11, fontWeight: 600,
                  display: 'inline-flex', alignItems: 'center', gap: 4, flexShrink: 0,
                }}><Icon name="play" size={9} color={T.tealInk} />Listen</button>
              )}
              {d.state === 'failed' && (
                <button style={{
                  padding: '6px 12px', borderRadius: 7,
                  background: T.cardSoft, color: T.ink, border: 'none', cursor: 'pointer',
                  fontSize: 11, fontWeight: 600, flexShrink: 0,
                }}>Retry</button>
              )}
              <button style={{
                width: 22, height: 22, borderRadius: 11, flexShrink: 0,
                background: 'transparent', border: 'none', cursor: 'pointer',
                color: T.inkMute, display: 'flex', alignItems: 'center', justifyContent: 'center',
              }}><Icon name="x" size={12} color={T.inkMute} strokeWidth={2.4} /></button>
            </div>
          ))}
        </div>

        <div style={{ fontSize: 11, fontWeight: 700, color: T.inkMute, letterSpacing: 0.5, textTransform: 'uppercase', margin: '24px 4px 8px' }}>Recently completed</div>
        <div style={{ background: T.card, borderRadius: 12, overflow: 'hidden' }}>
          {[
            { title: 'Atomic Habits — James Clear', sub: 'Added to Library · 142 MB · 5h 58m', time: 'Just now' },
            { title: 'Educated — Tara Westover', sub: 'Added to Library · 168 MB · 7h 12m', time: '2h ago' },
            { title: 'Becoming — Michelle Obama', sub: 'Added to Library · 412 MB · 19h 03m', time: 'Yesterday' },
          ].map((d, i, arr) => (
            <div key={i} style={{
              display: 'flex', alignItems: 'center', gap: 14,
              padding: '12px 16px',
              borderBottom: i < arr.length - 1 ? '0.5px solid ' + T.hair : 'none',
            }}>
              <div style={{
                width: 28, height: 28, borderRadius: 8, flexShrink: 0,
                background: T.tealSoft,
                display: 'flex', alignItems: 'center', justifyContent: 'center',
              }}><Icon name="check-fill" size={18} color={T.teal} /></div>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ fontSize: 13, fontWeight: 600, color: T.ink, letterSpacing: -0.2, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{d.title}</div>
                <div style={{ fontSize: 11.5, color: T.inkSoft, marginTop: 2 }}>{d.sub}</div>
              </div>
              <div style={{ fontSize: 11, color: T.inkMute, flexShrink: 0 }}>{d.time}</div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}

// ─── Notes view (Mac) ──────────────────────────────────────
function MNotesView({ withEditor = true }) {
  const notes = [
    { id: '1', title: 'On habits & identity',  time: '2h ago', linked: true,  snippet: 'Every action is a vote for the type of person you wish to become.', active: true },
    { id: '2', title: 'Reading queue, Q3',     time: 'Yesterday', linked: false, snippet: 'Hail Mary → Three-Body Problem → Educated → Becoming.' },
    { id: '3', title: 'Gatsby — green light',  time: '3d ago', linked: true,  snippet: 'Symbol of unreachable hope. Compare to Daisy\'s dock.' },
    { id: '4', title: 'Sleep, attention, focus', time: '1w ago', linked: false, snippet: 'Three pillars from Huberman ep. Track for 30 days.' },
    { id: '5', title: 'Dune — the spice mélange', time: 'Sep 12', linked: true,  snippet: 'Geriatric, prescient, addictive. Economics of empire.' },
    { id: '6', title: 'Three-Body — sophons',  time: 'Aug 28', linked: true,  snippet: 'Subatomic surveillance, hard sci-fi par excellence.' },
    { id: '7', title: 'Random thought',        time: 'Aug 14', linked: false, snippet: 'Translate "amor fati" — love of one\'s fate.' },
  ];
  return (
    <div style={{ display: 'flex', flexDirection: 'column', height: '100%' }}>
      <MToolbar
        title="Notes"
        subtitle="14 notes · 9 linked"
        trailing={<>
          <MIconButton icon="sort" />
          <MIconButton icon="plus" label="New Note" primary />
        </>}
      />
      <div style={{ flex: 1, display: 'flex', minHeight: 0 }}>
        {/* Left: list */}
        <div style={{ width: 320, flexShrink: 0, borderRight: '0.5px solid rgba(27,24,20,0.08)', overflowY: 'auto' }}>
          <div style={{ padding: '12px 14px 8px' }}>
            <div style={{
              display: 'flex', alignItems: 'center', gap: 6,
              background: 'rgba(255,255,255,0.7)', borderRadius: 7, padding: '7px 10px',
              border: '0.5px solid rgba(27,24,20,0.06)',
            }}>
              <Icon name="search" size={13} color={T.inkSoft} />
              <span style={{ fontSize: 12, color: T.inkMute }}>Search notes</span>
            </div>
          </div>
          {notes.map((n, i) => (
            <div key={n.id} style={{
              padding: '10px 16px 12px',
              borderBottom: i < notes.length - 1 ? '0.5px solid ' + T.hair : 'none',
              background: n.active ? 'rgba(30,144,133,0.08)' : 'transparent',
              cursor: 'pointer',
              borderLeft: n.active ? `3px solid ${T.teal}` : '3px solid transparent',
              paddingLeft: 13,
            }}>
              <div style={{ display: 'flex', alignItems: 'baseline', gap: 8 }}>
                <div style={{ fontSize: 13.5, fontWeight: 600, color: T.ink, letterSpacing: -0.2, flex: 1, minWidth: 0, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{n.title}</div>
                <div style={{ fontSize: 10.5, color: T.inkMute, flexShrink: 0 }}>{n.time}</div>
              </div>
              <div style={{ fontSize: 11.5, color: T.inkSoft, marginTop: 3, lineHeight: 1.35, overflow: 'hidden', display: '-webkit-box', WebkitLineClamp: 2, WebkitBoxOrient: 'vertical' }}>{n.snippet}</div>
              {n.linked && (
                <div style={{ marginTop: 5, display: 'inline-flex', alignItems: 'center', gap: 4, fontSize: 10, fontWeight: 700, color: T.tealInk, background: T.tealSoft, padding: '2px 6px', borderRadius: 4, letterSpacing: 0.3, textTransform: 'uppercase' }}>
                  <Icon name="link" size={9} color={T.tealInk} strokeWidth={2} />
                  Linked
                </div>
              )}
            </div>
          ))}
        </div>

        {/* Right: editor */}
        {withEditor && <MNoteEditor />}
      </div>
    </div>
  );
}

function MNoteEditor() {
  return (
    <div style={{ flex: 1, display: 'flex', flexDirection: 'column', minWidth: 0 }}>
      {/* Editor toolbar */}
      <div style={{
        height: 42, padding: '0 16px', display: 'flex', alignItems: 'center', gap: 4,
        borderBottom: '0.5px solid rgba(27,24,20,0.08)',
        background: 'rgba(255,255,255,0.4)',
      }}>
        {[
          { icon: 'bold' }, { icon: 'italic' }, { icon: 'underline' },
          { divider: true },
          { icon: 'h1' }, { icon: 'h2' },
          { divider: true },
          { icon: 'bullet-list' }, { icon: 'num-list' },
          { divider: true },
        ].map((b, i) => b.divider ? (
          <div key={i} style={{ width: 1, height: 20, background: 'rgba(27,24,20,0.12)', margin: '0 4px' }} />
        ) : (
          <button key={i} style={{
            width: 28, height: 28, borderRadius: 6, border: 'none', cursor: 'pointer',
            background: 'transparent', color: T.ink,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
          }}><Icon name={b.icon} size={14} color={T.ink} strokeWidth={1.9} /></button>
        ))}
        <button style={{
          padding: '0 10px', height: 28, borderRadius: 6, border: 'none', cursor: 'pointer',
          background: T.tealSoft, color: T.tealInk,
          display: 'inline-flex', alignItems: 'center', gap: 5,
          fontSize: 11, fontWeight: 600, fontVariantNumeric: 'tabular-nums',
        }}>
          <Icon name="clock" size={13} color={T.tealInk} strokeWidth={1.9} />
          Insert · 02:14:08
        </button>
        <div style={{ flex: 1 }} />
        <div style={{ fontSize: 11, color: T.inkMute }}>Last saved · just now</div>
      </div>

      {/* Body */}
      <div style={{ flex: 1, overflowY: 'auto', padding: '28px 56px 40px', background: 'rgba(255,253,247,0.4)' }}>
        <div style={{
          fontFamily: 'Georgia, serif', fontSize: 32, fontWeight: 700, color: T.ink,
          letterSpacing: -0.5, marginBottom: 12, lineHeight: 1.05,
        }}>On habits &amp; identity</div>
        <div style={{
          display: 'inline-flex', alignItems: 'center', gap: 6,
          padding: '5px 10px', borderRadius: 7,
          background: T.tealSoft, color: T.tealInk,
          fontSize: 11.5, fontWeight: 600, marginBottom: 24,
        }}>
          <Icon name="link" size={12} color={T.tealInk} />
          Atomic Habits · James Clear
        </div>

        <div style={{ fontSize: 15.5, color: T.ink, lineHeight: 1.65, letterSpacing: -0.05, maxWidth: 640 }}>
          <p style={{ margin: 0 }}>
            <b>Identity-based habits</b> beat outcome-based ones. The goal isn't to read a book — it's to <i>become a reader</i>. Every action is a vote for the type of person you wish to become.
          </p>
          <div style={{ height: 18 }} />
          <div style={{
            display: 'inline-block', fontSize: 13, fontFamily: 'ui-monospace, monospace',
            color: T.tealInk, background: T.tealSoft,
            padding: '3px 9px', borderRadius: 6,
            fontVariantNumeric: 'tabular-nums',
          }}>[Atomic Habits @ 01:23:14]</div>
          <p style={{ margin: '18px 0 0' }}>
            Two-minute rule: scale habits down until they take less than two minutes. Mastery follows showing up. The most effective form of motivation is progress.
          </p>
          <div style={{ height: 18 }} />
          <p style={{ margin: 0 }}>
            Habit stacking: pair the new behavior with an existing routine — "after I pour my morning coffee, I will read for ten minutes."<span style={{ background: 'rgba(30,144,133,0.18)', display: 'inline-block', width: 1, height: '1.2em', verticalAlign: 'text-bottom', marginLeft: 1 }} />
          </p>
        </div>
      </div>
    </div>
  );
}

// ─── Player (expanded "Now Playing" view) ──────────────────
function MPlayerExpanded({ onCollapse }) {
  return (
    <div style={{
      position: 'absolute', inset: 0, zIndex: 10,
      background: 'radial-gradient(ellipse at 30% 20%, #2A4D6F 0%, #0E1E33 50%, #0A0A12 100%)',
      color: '#fff', overflow: 'hidden',
      display: 'flex', flexDirection: 'column',
    }}>
      {/* Top bar with traffic lights + close */}
      <div style={{
        height: 48, display: 'flex', alignItems: 'center',
        padding: '0 16px', flexShrink: 0,
      }}>
        <div style={{ display: 'flex', gap: 8 }}>
          <span style={{ width: 12, height: 12, borderRadius: 6, background: '#FF5F57' }} />
          <span style={{ width: 12, height: 12, borderRadius: 6, background: '#FEBC2E' }} />
          <span style={{ width: 12, height: 12, borderRadius: 6, background: '#28C840' }} />
        </div>
        <div style={{ flex: 1, textAlign: 'center' }}>
          <div style={{ fontSize: 11, letterSpacing: 1, textTransform: 'uppercase', color: 'rgba(255,255,255,0.55)', fontWeight: 600 }}>Now Playing</div>
        </div>
        <button onClick={onCollapse} style={{
          width: 28, height: 28, borderRadius: 7,
          background: 'rgba(255,255,255,0.1)', border: 'none', cursor: 'pointer',
          color: '#fff', display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}>
          <Icon name="chevron-down" size={14} color="#fff" strokeWidth={2.2} />
        </button>
      </div>

      {/* Body — split */}
      <div style={{ flex: 1, display: 'flex', minHeight: 0, padding: '20px 56px 12px', gap: 56 }}>
        {/* Cover */}
        <div style={{
          flex: '0 0 auto', display: 'flex', flexDirection: 'column',
          alignItems: 'center', justifyContent: 'center', gap: 28,
        }}>
          <Cover which="habits" size={420} radius={16} />
          <div style={{ textAlign: 'center', maxWidth: 420 }}>
            <div style={{ fontFamily: 'Georgia, serif', fontSize: 32, fontWeight: 700, letterSpacing: -0.6, lineHeight: 1.1 }}>Atomic Habits</div>
            <div style={{ fontSize: 16, color: 'rgba(255,255,255,0.65)', marginTop: 6 }}>James Clear</div>
            <div style={{ fontSize: 11, color: 'rgba(255,255,255,0.4)', marginTop: 14, letterSpacing: 0.6, textTransform: 'uppercase', fontWeight: 600 }}>Chapter 4 · The Man Who Didn't Look Right</div>
          </div>
        </div>

        {/* Right: chapters / bookmarks tabbed */}
        <div style={{ flex: 1, minWidth: 0, display: 'flex', flexDirection: 'column' }}>
          <div style={{
            display: 'inline-flex', gap: 0, marginBottom: 16,
            background: 'rgba(255,255,255,0.06)', padding: 3, borderRadius: 8, alignSelf: 'flex-start',
          }}>
            {[
              { l: 'Chapters', active: true },
              { l: 'Bookmarks' },
              { l: 'Notes' },
            ].map((t) => (
              <button key={t.l} style={{
                padding: '6px 14px', borderRadius: 6,
                background: t.active ? 'rgba(255,255,255,0.12)' : 'transparent',
                border: 'none', cursor: 'pointer',
                color: t.active ? '#fff' : 'rgba(255,255,255,0.6)',
                fontSize: 12, fontWeight: 600, fontFamily: MAC,
              }}>{t.l}</button>
            ))}
          </div>
          <div style={{ flex: 1, overflowY: 'auto', paddingRight: 6 }}>
            {[
              { n: 1, t: 'The Fundamentals',                       start: '00:00:00' },
              { n: 2, t: 'The Surprising Power of Atomic Habits',  start: '00:32:14' },
              { n: 3, t: 'How Your Habits Shape Your Identity',    start: '01:09:42' },
              { n: 4, t: 'The Man Who Didn\'t Look Right',         start: '01:48:11', active: true },
              { n: 5, t: 'How to Start a New Habit',               start: '02:35:50' },
              { n: 6, t: 'Motivation Is Overrated',                start: '03:14:09' },
              { n: 7, t: 'How to Make a Habit Irresistible',       start: '03:51:33' },
              { n: 8, t: 'The Secret to Self-Control',             start: '04:22:18' },
            ].map((c) => (
              <div key={c.n} style={{
                display: 'flex', alignItems: 'center', gap: 14,
                padding: '11px 14px', borderRadius: 8,
                background: c.active ? 'rgba(30,144,133,0.18)' : 'transparent',
                marginBottom: 1,
              }}>
                <div style={{
                  width: 22, color: c.active ? T.teal : 'rgba(255,255,255,0.4)',
                  fontSize: 13, fontWeight: 600, fontVariantNumeric: 'tabular-nums',
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                }}>
                  {c.active ? <Icon name="speaker" size={16} color={T.teal} strokeWidth={1.9} /> : c.n}
                </div>
                <div style={{ flex: 1, fontSize: 14, color: c.active ? T.teal : '#fff', fontWeight: c.active ? 600 : 500, letterSpacing: -0.2, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{c.t}</div>
                <div style={{ fontSize: 12, color: c.active ? T.teal : 'rgba(255,255,255,0.5)', fontFamily: 'ui-monospace, monospace', fontVariantNumeric: 'tabular-nums' }}>{c.start}</div>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* Scrubber + transport */}
      <div style={{ flexShrink: 0, padding: '8px 56px 28px' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 14, marginBottom: 22 }}>
          <span style={{ fontSize: 12, color: 'rgba(255,255,255,0.6)', fontVariantNumeric: 'tabular-nums', fontFamily: 'ui-monospace, monospace', width: 60, textAlign: 'right' }}>2:14:08</span>
          <div style={{ flex: 1, height: 4, borderRadius: 2, background: 'rgba(255,255,255,0.12)', position: 'relative' }}>
            <div style={{ width: '38%', height: '100%', borderRadius: 2, background: '#fff' }} />
            <div style={{ position: 'absolute', left: '38%', top: '50%', width: 13, height: 13, borderRadius: 7, background: '#fff', transform: 'translate(-50%, -50%)', boxShadow: '0 2px 6px rgba(0,0,0,0.3)' }} />
          </div>
          <span style={{ fontSize: 12, color: 'rgba(255,255,255,0.6)', fontVariantNumeric: 'tabular-nums', fontFamily: 'ui-monospace, monospace', width: 60 }}>-3:47:22</span>
        </div>

        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 36 }}>
          <button style={{ background: 'none', border: 'none', cursor: 'pointer', padding: 0, color: 'rgba(255,255,255,0.8)' }}>
            <MacSkip dir="back" seconds={15} size={36} />
          </button>
          <button style={{
            width: 64, height: 64, borderRadius: 32, border: 'none', cursor: 'pointer',
            background: '#fff', color: T.ink,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            boxShadow: '0 6px 20px rgba(0,0,0,0.35)',
          }}><Icon name="pause" size={24} color={T.ink} /></button>
          <button style={{ background: 'none', border: 'none', cursor: 'pointer', padding: 0, color: 'rgba(255,255,255,0.8)' }}>
            <MacSkip dir="fwd" seconds={15} size={36} />
          </button>
        </div>

        <div style={{ display: 'flex', justifyContent: 'center', gap: 28, marginTop: 22 }}>
          <ExpSecondary icon={<span style={{ fontSize: 13, fontWeight: 700 }}>1.5×</span>} label="Speed" />
          <ExpSecondary icon={<Icon name="moon" size={16} color={T.teal} fill={T.teal} strokeWidth={0} />} label="22:13" active />
          <ExpSecondary icon={<Icon name="bookmark" size={16} color="rgba(255,255,255,0.65)" strokeWidth={1.9} />} label="Bookmark" />
          <ExpSecondary icon={<Icon name="edit" size={16} color="rgba(255,255,255,0.65)" strokeWidth={1.9} />} label="New Note" />
        </div>
      </div>
    </div>
  );
}

function ExpSecondary({ icon, label, active }) {
  return (
    <button style={{
      background: 'none', border: 'none', cursor: 'pointer', padding: 0,
      display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 6, minWidth: 70,
    }}>
      <div style={{
        width: 52, height: 36, borderRadius: 10,
        background: active ? 'rgba(30,144,133,0.22)' : 'rgba(255,255,255,0.08)',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        color: active ? T.teal : 'rgba(255,255,255,0.7)',
      }}>{icon}</div>
      <div style={{ fontSize: 11, color: active ? T.teal : 'rgba(255,255,255,0.6)', fontWeight: 500, fontVariantNumeric: 'tabular-nums' }}>{label}</div>
    </button>
  );
}

// ─── Preferences window ────────────────────────────────────
function MPreferences() {
  const sections = [
    { id: 'general',   icon: 'gear',              label: 'General' },
    { id: 'playback',  icon: 'play',              label: 'Playback', active: true },
    { id: 'companion', icon: 'link',              label: 'Companion' },
    { id: 'storage',   icon: 'arrow-down-circle', label: 'Storage' },
    { id: 'about',     icon: 'check',             label: 'About' },
  ];
  return (
    <div style={{
      width: 720, height: 540, borderRadius: 12, overflow: 'hidden',
      background: T.bg,
      boxShadow: '0 0 0 0.5px rgba(0,0,0,0.22), 0 18px 48px rgba(0,0,0,0.30)',
      display: 'flex', flexDirection: 'column',
      fontFamily: MAC,
    }}>
      {/* title bar */}
      <div style={{
        height: 38, display: 'flex', alignItems: 'center',
        padding: '0 14px', gap: 14, flexShrink: 0,
        borderBottom: '0.5px solid rgba(27,24,20,0.08)',
      }}>
        <div style={{ display: 'flex', gap: 8 }}>
          <span style={{ width: 12, height: 12, borderRadius: 6, background: '#FF5F57' }} />
          <span style={{ width: 12, height: 12, borderRadius: 6, background: '#FEBC2E' }} />
          <span style={{ width: 12, height: 12, borderRadius: 6, background: '#28C840', opacity: 0.5 }} />
        </div>
        <div style={{ flex: 1, textAlign: 'center', fontSize: 13, fontWeight: 600, color: T.ink, letterSpacing: -0.1 }}>Preferences</div>
        <div style={{ width: 50 }} />
      </div>

      {/* Toolbar tabs */}
      <div style={{
        display: 'flex', justifyContent: 'center', gap: 4,
        padding: '8px 0',
        background: 'rgba(241,236,226,0.6)',
        borderBottom: '0.5px solid rgba(27,24,20,0.08)',
        flexShrink: 0,
      }}>
        {sections.map((s) => (
          <button key={s.id} style={{
            padding: '8px 14px', borderRadius: 8, border: 'none', cursor: 'pointer',
            background: s.active ? 'rgba(255,255,255,0.85)' : 'transparent',
            display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 4,
            minWidth: 78,
            boxShadow: s.active ? '0 1px 3px rgba(0,0,0,0.06), 0 0 0 0.5px rgba(0,0,0,0.04)' : 'none',
          }}>
            <Icon name={s.icon} size={20} color={T.ink} strokeWidth={1.7} />
            <span style={{ fontSize: 11, color: T.ink, fontWeight: 500 }}>{s.label}</span>
          </button>
        ))}
      </div>

      {/* Body */}
      <div style={{ flex: 1, overflowY: 'auto', padding: '24px 40px' }}>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 20 }}>
          <FormGroup label="Skip interval"
            description="How far the 15-second buttons should jump.">
            <div style={{ display: 'flex', gap: 6 }}>
              {['10s', '15s', '30s', '60s'].map((v, i) => (
                <button key={v} style={{
                  padding: '6px 14px', borderRadius: 7,
                  background: i === 1 ? T.ink : 'rgba(255,255,255,0.7)',
                  color: i === 1 ? '#F4ECDB' : T.ink,
                  border: '0.5px solid ' + (i === 1 ? T.ink : 'rgba(27,24,20,0.08)'),
                  cursor: 'pointer', fontSize: 12.5, fontWeight: 600, letterSpacing: -0.1,
                }}>{v}</button>
              ))}
            </div>
          </FormGroup>

          <FormGroup label="Default playback speed"
            description="Applied when opening any book for the first time.">
            <div style={{ display: 'inline-flex', background: 'rgba(255,255,255,0.7)', borderRadius: 7, border: '0.5px solid rgba(27,24,20,0.08)', padding: 3 }}>
              {[0.75, 1.0, 1.25, 1.5, 1.75, 2.0].map((s, i) => (
                <button key={s} style={{
                  padding: '5px 11px', borderRadius: 5, border: 'none',
                  background: i === 3 ? '#fff' : 'transparent',
                  boxShadow: i === 3 ? '0 1px 2px rgba(0,0,0,0.08)' : 'none',
                  color: T.ink, fontSize: 12, fontWeight: 600, fontVariantNumeric: 'tabular-nums',
                  cursor: 'pointer',
                }}>{s.toFixed(s % 1 === 0 ? 1 : 2)}×</button>
              ))}
            </div>
          </FormGroup>

          <FormGroup label="On launch resume"
            description="Pick up where you left off when AudioLib opens.">
            <Checkbox checked label="Resume the last book automatically" />
          </FormGroup>

          <FormGroup label="Sleep timer when paused"
            description="Sleep timer keeps counting down when you pause.">
            <Checkbox label="Pause the sleep timer when playback pauses" />
          </FormGroup>

          <FormGroup label="Hotkeys"
            description="Keyboard shortcuts work globally on macOS when AudioLib is the active app.">
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 8 }}>
              <Hotkey label="Play / Pause"   keys={['Space']} />
              <Hotkey label="Back 15s"       keys={['⌘', '←']} />
              <Hotkey label="Forward 15s"    keys={['⌘', '→']} />
              <Hotkey label="New Note"       keys={['⌘', 'N']} />
              <Hotkey label="Bookmark"       keys={['⌘', 'B']} />
              <Hotkey label="Sleep Timer"    keys={['⌘', '⌥', 'S']} />
            </div>
          </FormGroup>
        </div>
      </div>
    </div>
  );
}

function FormGroup({ label, description, children }) {
  return (
    <div style={{ display: 'grid', gridTemplateColumns: '180px 1fr', gap: 16, alignItems: 'flex-start' }}>
      <div style={{ paddingTop: 4 }}>
        <div style={{ fontSize: 12.5, fontWeight: 600, color: T.ink, letterSpacing: -0.1, textAlign: 'right' }}>{label}</div>
      </div>
      <div>
        <div>{children}</div>
        {description && <div style={{ fontSize: 11, color: T.inkMute, marginTop: 6, lineHeight: 1.4 }}>{description}</div>}
      </div>
    </div>
  );
}

function Checkbox({ checked, label }) {
  return (
    <label style={{ display: 'inline-flex', alignItems: 'center', gap: 8, cursor: 'pointer' }}>
      <span style={{
        width: 16, height: 16, borderRadius: 4,
        background: checked ? T.teal : '#fff',
        border: '0.5px solid ' + (checked ? T.teal : 'rgba(27,24,20,0.25)'),
        boxShadow: checked ? '0 1px 2px rgba(30,144,133,0.3)' : 'inset 0 1px 0 rgba(0,0,0,0.05)',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
      }}>{checked && <Icon name="check" size={10} color="#fff" strokeWidth={3} />}</span>
      <span style={{ fontSize: 12.5, color: T.ink }}>{label}</span>
    </label>
  );
}

function Hotkey({ label, keys }) {
  return (
    <div style={{
      display: 'flex', alignItems: 'center', gap: 8,
      padding: '6px 10px', background: 'rgba(255,255,255,0.55)', borderRadius: 7,
      border: '0.5px solid rgba(27,24,20,0.06)',
    }}>
      <span style={{ flex: 1, fontSize: 12, color: T.ink }}>{label}</span>
      <span style={{ display: 'inline-flex', gap: 4 }}>
        {keys.map((k, i) => (
          <span key={i} style={{
            minWidth: 22, height: 22, padding: '0 6px',
            background: '#fff', borderRadius: 4,
            border: '0.5px solid rgba(27,24,20,0.12)',
            boxShadow: 'inset 0 -1px 0 rgba(27,24,20,0.06)',
            display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
            fontSize: 11, fontWeight: 600, color: T.ink,
            fontFamily: 'ui-monospace, SF Mono, monospace',
          }}>{k}</span>
        ))}
      </span>
    </div>
  );
}

// ─── Mini Player (floating window) ─────────────────────────
function MMiniPlayer() {
  return (
    <div style={{
      width: 360, height: 100, borderRadius: 14, overflow: 'hidden',
      background: 'rgba(20, 18, 16, 0.94)',
      backdropFilter: 'blur(40px)',
      color: '#F4ECDB',
      boxShadow: '0 0 0 0.5px rgba(0,0,0,0.4), 0 16px 40px rgba(0,0,0,0.5)',
      fontFamily: MAC,
      display: 'flex', alignItems: 'center', padding: '0 14px', gap: 12,
      position: 'relative',
    }}>
      <div style={{ position: 'absolute', top: 8, left: 10, display: 'flex', gap: 6 }}>
        <span style={{ width: 9, height: 9, borderRadius: 5, background: '#FF5F57' }} />
        <span style={{ width: 9, height: 9, borderRadius: 5, background: '#FEBC2E' }} />
        <span style={{ width: 9, height: 9, borderRadius: 5, background: '#28C840' }} />
      </div>

      <Cover which="habits" size={60} radius={7} />
      <div style={{ flex: 1, minWidth: 0, paddingTop: 8 }}>
        <div style={{ fontSize: 13, fontWeight: 600, color: '#fff', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis', letterSpacing: -0.2 }}>Atomic Habits</div>
        <div style={{ fontSize: 11, color: 'rgba(244,236,219,0.6)', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>James Clear · Ch. 4</div>
        <div style={{ marginTop: 6, display: 'flex', alignItems: 'center', gap: 8 }}>
          <div style={{ flex: 1, height: 2.5, background: 'rgba(255,255,255,0.12)', borderRadius: 2 }}>
            <div style={{ width: '38%', height: '100%', background: '#F4ECDB', borderRadius: 2 }} />
          </div>
          <span style={{ fontSize: 10, color: 'rgba(244,236,219,0.5)', fontVariantNumeric: 'tabular-nums', fontFamily: 'ui-monospace, monospace' }}>-3:47</span>
        </div>
      </div>
      <div style={{ display: 'flex', alignItems: 'center', gap: 4 }}>
        <button style={{ width: 28, height: 28, borderRadius: 14, background: 'transparent', border: 'none', color: 'rgba(244,236,219,0.8)', cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          <MacSkip dir="back" seconds={15} size={20} />
        </button>
        <button style={{ width: 36, height: 36, borderRadius: 18, background: '#F4ECDB', border: 'none', cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center', boxShadow: '0 2px 6px rgba(0,0,0,0.3)' }}>
          <Icon name="pause" size={14} color={T.ink} />
        </button>
        <button style={{ width: 28, height: 28, borderRadius: 14, background: 'transparent', border: 'none', color: 'rgba(244,236,219,0.8)', cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          <MacSkip dir="fwd" seconds={15} size={20} />
        </button>
      </div>
    </div>
  );
}

// ─── Menu bar extra ────────────────────────────────────────
function MMenubarExtra() {
  return (
    <div style={{
      width: 320, borderRadius: 12, overflow: 'hidden',
      background: 'rgba(245,242,235,0.94)',
      backdropFilter: 'blur(40px) saturate(180%)',
      boxShadow: '0 0 0 0.5px rgba(0,0,0,0.18), 0 12px 36px rgba(0,0,0,0.32)',
      fontFamily: MAC,
      padding: 6,
    }}>
      <div style={{ display: 'flex', gap: 10, padding: 8, alignItems: 'center' }}>
        <Cover which="habits" size={42} radius={6} />
        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{ fontSize: 12.5, fontWeight: 600, color: T.ink, letterSpacing: -0.2, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>Atomic Habits</div>
          <div style={{ fontSize: 10.5, color: T.inkSoft }}>James Clear · 2:14:08 / 5:58:12</div>
        </div>
        <button style={{
          width: 30, height: 30, borderRadius: 15, border: 'none', cursor: 'pointer',
          background: T.ink, color: '#F4ECDB',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}>
          <Icon name="pause" size={12} color="#F4ECDB" />
        </button>
      </div>
      <div style={{ padding: '0 8px 8px' }}>
        <ProgressBar value={0.38} height={3} color={T.teal} />
      </div>
      <div style={{ height: 0.5, background: 'rgba(27,24,20,0.1)', margin: '4px 0' }} />
      {[
        { l: 'Sleep Timer · 22 min',  icon: 'moon', accent: true },
        { l: 'Bookmark this position',   icon: 'bookmark' },
        { l: 'Open in AudioLib',          icon: 'chevron-up' },
        { l: 'Quit AudioLib',             icon: 'x' },
      ].map((m, i) => (
        <button key={i} style={{
          display: 'flex', alignItems: 'center', gap: 8,
          width: '100%', padding: '7px 10px',
          background: 'transparent', border: 'none', cursor: 'pointer',
          borderRadius: 6, color: m.accent ? T.tealInk : T.ink,
          fontSize: 12.5, fontWeight: 500, textAlign: 'left', letterSpacing: -0.1,
        }}>
          <Icon name={m.icon} size={13} color={m.accent ? T.teal : T.inkSoft} strokeWidth={1.9} />
          <span>{m.l}</span>
        </button>
      ))}
    </div>
  );
}

Object.assign(window, {
  MLibraryGrid, MBookCard, MBookInspector, MDownloadsView, MNotesView, MNoteEditor,
  MPlayerExpanded, MPreferences, MMiniPlayer, MMenubarExtra,
});
