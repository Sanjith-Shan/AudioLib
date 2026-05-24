// Notes Tab + Note Editor + Player + Sheets + Settings + Edit Book

// ─── Notes Tab ─────────────────────────────────────────────
function NoteRow({ title, time, linked, snippet }) {
  return (
    <div style={{
      display: 'flex', alignItems: 'flex-start', gap: 14,
      padding: '14px 16px',
    }}>
      <div style={{
        width: 6, alignSelf: 'stretch', borderRadius: 3,
        background: linked ? T.teal : T.inkFaint, flexShrink: 0, marginTop: 2,
      }} />
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ display: 'flex', alignItems: 'baseline', gap: 8 }}>
          <div style={{
            fontSize: 16, fontWeight: 600, color: T.ink, letterSpacing: -0.2,
            whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis', flex: 1, minWidth: 0,
          }}>{title}</div>
          {linked && (
            <span style={{
              padding: '2px 7px', borderRadius: 6,
              background: T.tealSoft, color: T.tealInk,
              fontSize: 10, fontWeight: 700, letterSpacing: 0.3, textTransform: 'uppercase',
              flexShrink: 0,
            }}>Linked</span>
          )}
        </div>
        {snippet && (
          <div style={{
            fontSize: 13.5, color: T.inkSoft, marginTop: 3, lineHeight: 1.35,
            overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap',
          }}>{snippet}</div>
        )}
        <div style={{ fontSize: 12, color: T.inkMute, marginTop: 4 }}>{time}</div>
      </div>
    </div>
  );
}

function NotesScreen({ empty = false }) {
  const notes = [
    { title: 'On habits & identity', time: '2 hours ago', linked: true,  snippet: 'Every action is a vote for the type of person you wish to become.' },
    { title: 'Reading queue, Q3',    time: 'Yesterday',   linked: false, snippet: 'Hail Mary → Three-Body Problem → Educated → Becoming.' },
    { title: 'Gatsby — green light', time: '3 days ago',  linked: true,  snippet: 'Symbol of unreachable hope. Compare to Daisy\'s dock.' },
    { title: 'Sleep, attention, focus', time: 'Last week', linked: false, snippet: 'Three pillars from Huberman ep. Track for 30 days.' },
    { title: 'Dune — the spice mélange', time: 'Sep 12',  linked: true,  snippet: 'Geriatric, prescient, addictive. Economics of empire.' },
  ];
  return (
    <div style={{
      position: 'absolute', inset: 0, background: T.bg,
      paddingTop: 54,
      display: 'flex', flexDirection: 'column',
    }}>
      <div style={{
        padding: '8px 16px 4px', display: 'flex', alignItems: 'center', justifyContent: 'space-between',
      }}>
        <div style={{
          fontFamily: 'Georgia, serif', fontSize: 28, fontWeight: 700,
          color: T.ink, letterSpacing: -0.5,
        }}>Notes</div>
        <div style={{ display: 'flex', gap: 8 }}>
          <button style={{
            width: 36, height: 36, borderRadius: 18, border: 'none', cursor: 'pointer',
            background: 'rgba(255,255,255,0.6)', display: 'flex', alignItems: 'center', justifyContent: 'center',
          }}>
            <Icon name="gear" size={18} color={T.ink} />
          </button>
          <button style={{
            width: 36, height: 36, borderRadius: 18, border: 'none', cursor: 'pointer',
            background: T.ink, color: '#F4ECDB',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
          }}>
            <Icon name="plus" size={18} color="#F4ECDB" strokeWidth={2.2} />
          </button>
        </div>
      </div>

      <div style={{ overflowY: 'auto', flex: 1, paddingBottom: 110 }}>
        {empty ? (
          <div style={{
            display: 'flex', flexDirection: 'column', alignItems: 'center',
            padding: '90px 32px 24px', textAlign: 'center',
          }}>
            <div style={{
              width: 84, height: 84, borderRadius: 24,
              background: T.cardSoft, display: 'flex', alignItems: 'center', justifyContent: 'center',
              marginBottom: 18,
            }}>
              <Icon name="note" size={40} color={T.inkMute} strokeWidth={1.5} />
            </div>
            <div style={{ fontSize: 19, fontWeight: 700, color: T.ink, letterSpacing: -0.3, fontFamily: 'Georgia, serif' }}>No Notes Yet</div>
            <div style={{ fontSize: 14, color: T.inkSoft, marginTop: 6, maxWidth: 240, lineHeight: 1.4 }}>
              Tap + to create your first note.
            </div>
          </div>
        ) : (
          <div style={{ margin: '8px 16px 0', background: T.card, borderRadius: 18, overflow: 'hidden' }}>
            {notes.map((n, i) => (
              <React.Fragment key={n.title}>
                <NoteRow {...n} />
                {i < notes.length - 1 && <div style={{ height: 0.5, background: T.hair, marginLeft: 36 }} />}
              </React.Fragment>
            ))}
          </div>
        )}
      </div>

      <TabBar active="notes" />
    </div>
  );
}

// ─── Note Editor ───────────────────────────────────────────
function NoteEditor() {
  return (
    <div style={{
      position: 'absolute', inset: 0, background: T.bg,
      display: 'flex', flexDirection: 'column',
    }}>
      {/* Nav */}
      <div style={{
        paddingTop: 54, padding: '54px 12px 8px',
        display: 'flex', alignItems: 'center', gap: 4,
      }}>
        <button style={{
          width: 36, height: 36, borderRadius: 18, border: 'none', cursor: 'pointer',
          background: 'rgba(255,255,255,0.6)',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}>
          <Icon name="chevron-left" size={18} color={T.ink} strokeWidth={2.2} />
        </button>
        <div style={{
          flex: 1, padding: '0 8px', fontSize: 16, fontWeight: 600,
          color: T.ink, letterSpacing: -0.2,
        }}>On habits & identity</div>
        <button style={{
          padding: '8px 14px', borderRadius: 14, border: 'none', cursor: 'pointer',
          background: T.teal, color: '#fff',
          fontSize: 14, fontWeight: 600, letterSpacing: -0.1,
        }}>Done</button>
      </div>

      {/* Body */}
      <div style={{ flex: 1, overflowY: 'auto', padding: '8px 20px 12px' }}>
        <div style={{
          fontFamily: 'Georgia, "Iowan Old Style", serif',
          fontSize: 26, fontWeight: 700, color: T.ink, letterSpacing: -0.4,
          marginBottom: 12, lineHeight: 1.1,
        }}>On habits & identity</div>

        <div style={{
          display: 'inline-flex', alignItems: 'center', gap: 6,
          padding: '6px 10px', borderRadius: 8,
          background: T.tealSoft, color: T.tealInk,
          fontSize: 12, fontWeight: 600, marginBottom: 16,
        }}>
          <Icon name="link" size={12} color={T.tealInk} />
          Atomic Habits · James Clear
        </div>

        <div style={{ fontSize: 16, color: T.ink, lineHeight: 1.55, letterSpacing: -0.1 }}>
          <p style={{ margin: 0 }}>
            <b>Identity-based habits</b> beat outcome-based ones. The goal isn't to read a book — it's to <i>become a reader</i>.
          </p>
          <div style={{ height: 14 }} />
          <p style={{ margin: 0 }}>Every action is a vote for the type of person you wish to become.</p>
          <div style={{ height: 14 }} />
          <div style={{
            fontSize: 13, fontFamily: 'ui-monospace, SF Mono, monospace',
            color: T.tealInk, background: T.tealSoft,
            padding: '6px 10px', borderRadius: 8, display: 'inline-block',
          }}>[Atomic Habits @ 01:23:14]</div>
          <div style={{ height: 14 }} />
          <p style={{ margin: 0 }}>
            Two-minute rule: scale habits down until they take less than two minutes. Mastery follows showing up<span style={{ background: 'rgba(30,144,133,0.18)' }}>|</span>
          </p>
        </div>
      </div>

      {/* Formatting toolbar */}
      <div style={{
        background: 'rgba(245,242,235,0.85)', backdropFilter: 'blur(20px)',
        borderTop: '0.5px solid ' + T.hair,
        padding: '8px 8px',
        display: 'flex', alignItems: 'center', gap: 4, overflowX: 'auto',
      }}>
        {[
          { icon: 'bold', size: 18 },
          { icon: 'italic', size: 18 },
          { icon: 'underline', size: 18 },
          { divider: true },
          { icon: 'h1', size: 19 },
          { icon: 'h2', size: 19 },
          { divider: true },
          { icon: 'bullet-list', size: 19 },
          { icon: 'num-list', size: 19 },
          { divider: true },
          { icon: 'clock', size: 18, accent: true, label: '01:23' },
        ].map((b, i) => b.divider ? (
          <div key={i} style={{ width: 1, height: 20, background: T.hair, margin: '0 2px' }} />
        ) : (
          <button key={i} style={{
            minWidth: 36, height: 36, padding: b.label ? '0 10px' : 0,
            borderRadius: 8, border: 'none', cursor: 'pointer',
            background: b.accent ? T.tealSoft : 'transparent',
            color: b.accent ? T.tealInk : T.ink,
            display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 5,
            fontSize: 12, fontWeight: 600,
            fontVariantNumeric: 'tabular-nums',
          }}>
            <Icon name={b.icon} size={b.size} color={b.accent ? T.tealInk : T.ink} strokeWidth={1.9} />
            {b.label && <span>{b.label}</span>}
          </button>
        ))}
      </div>
    </div>
  );
}

// ─── Full Player ───────────────────────────────────────────
function PlayerScreen({ activeSheet }) {
  const book = BOOKS.habits;
  return (
    <div style={{
      position: 'absolute', inset: 0,
      background: 'linear-gradient(180deg, #1B4B7A 0%, #0E1E33 60%, #0A0A12 100%)',
      paddingTop: 54, color: T.dInk,
      display: 'flex', flexDirection: 'column', overflow: 'hidden',
    }}>
      {/* Nav */}
      <div style={{ padding: '10px 16px', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
        <button style={{
          width: 36, height: 36, borderRadius: 18, border: 'none', cursor: 'pointer',
          background: 'rgba(255,255,255,0.12)', backdropFilter: 'blur(20px)',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}>
          <Icon name="chevron-down" size={18} color="#fff" strokeWidth={2.2} />
        </button>
        <div style={{ textAlign: 'center' }}>
          <div style={{ fontSize: 11, color: T.dInkSoft, letterSpacing: 0.6, textTransform: 'uppercase', fontWeight: 600 }}>Playing from Library</div>
          <div style={{ fontSize: 13, color: '#fff', fontWeight: 600, letterSpacing: -0.1, marginTop: 1 }}>Atomic Habits</div>
        </div>
        <button style={{
          width: 36, height: 36, borderRadius: 18, border: 'none', cursor: 'pointer',
          background: 'rgba(255,255,255,0.12)',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}>
          <Icon name="more" size={18} color="#fff" />
        </button>
      </div>

      {/* Cover */}
      <div style={{ flex: '0 0 auto', display: 'flex', justifyContent: 'center', padding: '24px 32px 12px' }}>
        <Cover which="habits" size={310} radius={14} />
      </div>

      {/* Title + author */}
      <div style={{ padding: '20px 24px 0', textAlign: 'left' }}>
        <div style={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between', gap: 12 }}>
          <div style={{ flex: 1, minWidth: 0 }}>
            <div style={{
              fontFamily: 'Georgia, serif', fontSize: 24, fontWeight: 700,
              letterSpacing: -0.4, color: '#fff', lineHeight: 1.1,
            }}>Atomic Habits</div>
            <div style={{ fontSize: 14.5, color: T.dInkSoft, marginTop: 4 }}>James Clear</div>
          </div>
          <button style={{
            width: 32, height: 32, border: 'none', background: 'transparent', cursor: 'pointer',
            color: T.dInkSoft, padding: 0,
          }}>
            <Icon name="bookmark" size={22} color={T.dInkSoft} strokeWidth={1.8} />
          </button>
        </div>
      </div>

      {/* Scrubber */}
      <div style={{ padding: '24px 24px 8px' }}>
        <div style={{
          height: 4, borderRadius: 2, background: 'rgba(255,255,255,0.15)',
          position: 'relative',
        }}>
          <div style={{
            width: '38%', height: '100%', borderRadius: 2,
            background: '#fff',
          }} />
          <div style={{
            position: 'absolute', left: '38%', top: '50%',
            width: 12, height: 12, borderRadius: 6,
            background: '#fff',
            transform: 'translate(-50%, -50%)',
            boxShadow: '0 2px 6px rgba(0,0,0,0.3)',
          }} />
        </div>
        <div style={{
          display: 'flex', justifyContent: 'space-between',
          marginTop: 6, fontSize: 11, color: T.dInkMute,
          fontVariantNumeric: 'tabular-nums',
        }}>
          <span>2:14:08</span>
          <span>-3:47:22</span>
        </div>
      </div>

      {/* Primary controls */}
      <div style={{
        padding: '12px 24px 24px',
        display: 'flex', alignItems: 'center', justifyContent: 'space-between',
      }}>
        <button style={{ background: 'none', border: 'none', cursor: 'pointer', color: '#fff', padding: 0 }}>
          <SkipIcon dir="back" seconds={15} />
        </button>
        <button style={{
          width: 72, height: 72, borderRadius: 36, border: 'none', cursor: 'pointer',
          background: '#fff', display: 'flex', alignItems: 'center', justifyContent: 'center',
          boxShadow: '0 6px 20px rgba(0,0,0,0.35)',
        }}>
          <Icon name="pause" size={28} color={T.ink} />
        </button>
        <button style={{ background: 'none', border: 'none', cursor: 'pointer', color: '#fff', padding: 0 }}>
          <SkipIcon dir="fwd" seconds={15} />
        </button>
      </div>

      {/* Secondary controls */}
      <div style={{
        padding: '0 24px 36px',
        display: 'flex', justifyContent: 'space-around', alignItems: 'center',
      }}>
        <SecondaryButton icon={<span style={{ fontSize: 14, fontWeight: 700, letterSpacing: -0.2 }}>1.5×</span>} label="Speed" />
        <SecondaryButton icon={<Icon name="moon" size={18} color={T.teal} fill={T.teal} strokeWidth={0} />} label="22:13" active />
        <SecondaryButton icon={<Icon name="list" size={20} color={T.dInkSoft} strokeWidth={1.9} />} label="Chapters" />
        <SecondaryButton icon={<Icon name="bookmark" size={18} color={T.dInkSoft} strokeWidth={1.9} />} label="Marks" />
      </div>

      {activeSheet && <PlayerSheet which={activeSheet} />}
    </div>
  );
}

function SkipIcon({ dir = 'back', seconds = 15 }) {
  // Circular arrow with number inside
  return (
    <div style={{ position: 'relative', width: 48, height: 48 }}>
      <svg width="48" height="48" viewBox="0 0 48 48" fill="none">
        {dir === 'back' ? (
          <>
            <path d="M24 10 a14 14 0 1 0 12 7" stroke="#fff" strokeWidth="2" strokeLinecap="round" fill="none"/>
            <path d="M24 6 l4 4 -4 4" stroke="#fff" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" fill="none"/>
          </>
        ) : (
          <>
            <path d="M24 10 a14 14 0 1 1 -12 7" stroke="#fff" strokeWidth="2" strokeLinecap="round" fill="none"/>
            <path d="M24 6 l-4 4 4 4" stroke="#fff" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" fill="none"/>
          </>
        )}
      </svg>
      <span style={{
        position: 'absolute', inset: 0, display: 'flex', alignItems: 'center', justifyContent: 'center',
        fontSize: 13, fontWeight: 700, color: '#fff', paddingTop: 4,
        fontFamily: '-apple-system, system-ui',
      }}>{seconds}</span>
    </div>
  );
}

function SecondaryButton({ icon, label, active }) {
  return (
    <button style={{
      background: 'none', border: 'none', cursor: 'pointer', padding: 0,
      display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 5,
      minWidth: 56,
    }}>
      <div style={{
        width: 44, height: 32, borderRadius: 16,
        background: active ? 'rgba(30,144,133,0.2)' : 'rgba(255,255,255,0.06)',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        color: active ? T.teal : T.dInkSoft,
      }}>{icon}</div>
      <div style={{ fontSize: 10.5, color: active ? T.teal : T.dInkMute, fontWeight: 500, letterSpacing: 0.1, fontVariantNumeric: 'tabular-nums' }}>{label}</div>
    </button>
  );
}

// ─── Player Sheets ────────────────────────────────────────
function PlayerSheet({ which }) {
  if (which === 'speed') return <SpeedSheet />;
  if (which === 'sleep') return <SleepSheet />;
  if (which === 'bookmarks') return <BookmarksSheet />;
  if (which === 'chapters') return <ChaptersSheet />;
  return null;
}

function SpeedSheet() {
  const speeds = [0.75, 1.0, 1.25, 1.5, 1.75, 2.0, 2.5, 3.0];
  const active = 1.5;
  return (
    <Sheet title="Playback Speed" dark height="58%" trailing="Done">
      <div style={{ padding: '8px 16px 24px' }}>
        <div style={{ fontSize: 13, color: T.dInkSoft, textAlign: 'center', marginBottom: 16, lineHeight: 1.4 }}>
          Adjust how fast the narrator reads.
        </div>
        <div style={{
          display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 8,
        }}>
          {speeds.map((s) => {
            const isActive = s === active;
            return (
              <button key={s} style={{
                aspectRatio: '1.1',
                background: isActive ? T.teal : 'rgba(255,255,255,0.06)',
                border: isActive ? 'none' : '1px solid rgba(255,255,255,0.08)',
                borderRadius: 14, cursor: 'pointer',
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                color: isActive ? '#fff' : '#fff',
                fontSize: 18, fontWeight: 700, letterSpacing: -0.3,
                boxShadow: isActive ? '0 4px 14px rgba(30,144,133,0.4)' : 'none',
              }}>{s.toFixed(s % 1 === 0 ? 1 : 2).replace(/0+$/, '').replace(/\.$/, '.0')}×</button>
            );
          })}
        </div>
        <div style={{ marginTop: 18, padding: '10px 14px', background: 'rgba(255,255,255,0.04)', borderRadius: 12, fontSize: 12.5, color: T.dInkSoft, lineHeight: 1.4 }}>
          Speed changes apply instantly to all books. Most listeners settle at <b style={{ color: '#fff' }}>1.5×</b>.
        </div>
      </div>
    </Sheet>
  );
}

function SleepSheet() {
  const opts = ['Off', '5 min', '10 min', '15 min', '30 min', '45 min', '1 hour'];
  const active = '15 min';
  return (
    <Sheet title="Sleep Timer" dark height="75%" trailing="Done">
      <div style={{ padding: '4px 0 24px' }}>
        <div style={{ padding: '0 16px', marginBottom: 12 }}>
          <div style={{ background: '#2A2A2F', borderRadius: 14, overflow: 'hidden' }}>
            {opts.map((o, i) => {
              const a = o === active;
              return (
                <div key={o} style={{
                  display: 'flex', alignItems: 'center',
                  padding: '13px 16px',
                  borderBottom: i < opts.length - 1 ? '0.5px solid rgba(255,255,255,0.08)' : 'none',
                }}>
                  <div style={{ flex: 1, color: '#fff', fontSize: 16, letterSpacing: -0.2 }}>{o}</div>
                  {a && <Icon name="check" size={18} color={T.teal} strokeWidth={2.4} />}
                </div>
              );
            })}
          </div>
        </div>

        <div style={{ padding: '0 16px', marginTop: 18 }}>
          <div style={{ fontSize: 11, fontWeight: 700, letterSpacing: 0.5, textTransform: 'uppercase', color: T.dInkSoft, padding: '0 6px 8px' }}>Custom</div>
          <div style={{
            background: '#2A2A2F', borderRadius: 14, padding: '12px 14px',
            display: 'flex', alignItems: 'center', gap: 10,
          }}>
            <input style={{
              flex: 1, background: 'transparent', border: 'none', outline: 'none',
              color: '#fff', fontSize: 16, fontFamily: 'inherit',
              fontVariantNumeric: 'tabular-nums',
            }} defaultValue="20" />
            <span style={{ color: T.dInkSoft, fontSize: 14 }}>minutes</span>
            <button style={{
              padding: '8px 16px', borderRadius: 10, border: 'none', cursor: 'pointer',
              background: T.teal, color: '#fff', fontSize: 14, fontWeight: 600,
            }}>Set</button>
          </div>
          <div style={{ fontSize: 12, color: T.dInkMute, marginTop: 8, padding: '0 4px' }}>1–999 min</div>
        </div>
      </div>
    </Sheet>
  );
}

function BookmarksSheet() {
  const marks = [
    { t: '00:24:08', note: 'The 1% rule — daily improvements compound.' },
    { t: '01:12:33', note: 'Identity-based habits beat outcome-based.' },
    { t: '02:14:08', note: 'Two-minute rule — start so small you can\'t fail.' },
    { t: '03:48:51', note: null },
    { t: '04:21:02', note: 'Habit stacking — pair with existing routine.' },
  ];
  return (
    <Sheet title="Bookmarks" dark height="75%" trailing="Done">
      <div style={{ padding: '4px 16px 24px' }}>
        <button style={{
          width: '100%', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8,
          background: T.teal, color: '#fff',
          border: 'none', borderRadius: 14, padding: '14px',
          fontSize: 15, fontWeight: 600, cursor: 'pointer', letterSpacing: -0.1,
          marginBottom: 16,
          boxShadow: '0 4px 14px rgba(30,144,133,0.3)',
        }}>
          <Icon name="bookmark-fill" size={16} color="#fff" />
          Bookmark this position · 02:14:08
        </button>
        <div style={{ background: '#2A2A2F', borderRadius: 14, overflow: 'hidden' }}>
          {marks.map((m, i) => (
            <div key={i} style={{
              display: 'flex', alignItems: 'flex-start', gap: 12,
              padding: '14px 14px',
              borderBottom: i < marks.length - 1 ? '0.5px solid rgba(255,255,255,0.08)' : 'none',
            }}>
              <div style={{
                fontFamily: 'ui-monospace, monospace',
                fontSize: 13, color: T.teal, fontWeight: 600,
                fontVariantNumeric: 'tabular-nums', flexShrink: 0, marginTop: 2,
              }}>{m.t}</div>
              <div style={{ flex: 1, color: m.note ? '#fff' : T.dInkMute, fontSize: 14, lineHeight: 1.4 }}>
                {m.note || 'No note'}
              </div>
            </div>
          ))}
        </div>
      </div>
    </Sheet>
  );
}

function ChaptersSheet() {
  const chapters = [
    { n: 1, t: 'The Fundamentals',         start: '00:00:00' },
    { n: 2, t: 'The Surprising Power…',    start: '00:32:14' },
    { n: 3, t: 'How Your Habits Shape…',   start: '01:09:42' },
    { n: 4, t: 'The Man Who Didn\'t…',     start: '01:48:11', active: true },
    { n: 5, t: 'How to Start a New Habit', start: '02:35:50' },
    { n: 6, t: 'Motivation Is Overrated',  start: '03:14:09' },
    { n: 7, t: 'How to Make a Habit…',     start: '03:51:33' },
    { n: 8, t: 'The Secret to Self-Control', start: '04:22:18' },
  ];
  return (
    <Sheet title="Chapters" dark height="75%" trailing="Done">
      <div style={{ padding: '4px 16px 24px' }}>
        <div style={{ background: '#2A2A2F', borderRadius: 14, overflow: 'hidden' }}>
          {chapters.map((c, i) => (
            <div key={c.n} style={{
              display: 'flex', alignItems: 'center', gap: 12,
              padding: '13px 14px',
              background: c.active ? 'rgba(30,144,133,0.13)' : 'transparent',
              borderBottom: i < chapters.length - 1 ? '0.5px solid rgba(255,255,255,0.08)' : 'none',
            }}>
              <div style={{
                width: 22, height: 22, flexShrink: 0,
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                color: c.active ? T.teal : T.dInkMute,
              }}>
                {c.active ? <Icon name="speaker" size={18} color={T.teal} strokeWidth={1.9} /> : <span style={{ fontSize: 13, fontWeight: 600, fontVariantNumeric: 'tabular-nums' }}>{c.n}</span>}
              </div>
              <div style={{ flex: 1, fontSize: 14.5, color: c.active ? T.teal : '#fff', fontWeight: c.active ? 600 : 500, letterSpacing: -0.2, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{c.t}</div>
              <div style={{
                fontFamily: 'ui-monospace, monospace', fontSize: 12,
                color: c.active ? T.teal : T.dInkSoft, fontVariantNumeric: 'tabular-nums',
              }}>{c.start}</div>
            </div>
          ))}
        </div>
      </div>
    </Sheet>
  );
}

// ─── Book Edit Sheet ──────────────────────────────────────
function BookEditSheet({ standalone = false }) {
  const content = (
    <div style={{ padding: '4px 16px 24px' }}>
      <div style={{ display: 'flex', justifyContent: 'center', padding: '4px 0 18px' }}>
        <Cover which="habits" size={120} radius={12} />
      </div>

      <div style={{ background: T.card, borderRadius: 14, overflow: 'hidden' }}>
        {[
          { l: 'Title',     v: 'Atomic Habits' },
          { l: 'Author',    v: 'James Clear' },
          { l: 'Series',    v: '', placeholder: 'None' },
          { l: '# in series', v: '', placeholder: '—' },
        ].map((f, i, arr) => (
          <div key={f.l} style={{
            display: 'flex', alignItems: 'center', padding: '12px 14px',
            borderBottom: i < arr.length - 1 ? '0.5px solid ' + T.hair : 'none',
            gap: 8,
          }}>
            <div style={{ fontSize: 14, color: T.inkSoft, width: 90, flexShrink: 0 }}>{f.l}</div>
            <div style={{
              flex: 1, fontSize: 15, color: f.v ? T.ink : T.inkMute,
              textAlign: 'right', letterSpacing: -0.1,
            }}>{f.v || f.placeholder}</div>
          </div>
        ))}
      </div>

      <SectionHeader>Danger Zone</SectionHeader>
      <button style={{
        margin: '0', padding: '14px',
        background: T.card, border: 'none', cursor: 'pointer',
        borderRadius: 14, width: 'calc(100% - 0px)',
        display: 'flex', alignItems: 'center', gap: 12,
        color: T.red, fontSize: 15, fontWeight: 600, letterSpacing: -0.2,
      }}>
        <Icon name="trash" size={18} color={T.red} strokeWidth={1.9} />
        Delete Book & Audio File
      </button>
      <div style={{ fontSize: 12, color: T.inkMute, padding: '8px 14px 0', lineHeight: 1.4 }}>
        Bookmarks and notes for this book will remain.
      </div>
    </div>
  );

  if (standalone) return content;
  return (
    <Sheet title="Edit Book" height="85%" leading="Cancel" trailing="Save">
      {content}
    </Sheet>
  );
}

// ─── Settings ──────────────────────────────────────────────
function SettingsScreen() {
  return (
    <div style={{
      position: 'absolute', inset: 0, background: T.bg,
      paddingTop: 54, display: 'flex', flexDirection: 'column',
    }}>
      <div style={{ padding: '10px 16px 4px', display: 'flex', alignItems: 'center', gap: 4 }}>
        <button style={{
          width: 36, height: 36, borderRadius: 18, border: 'none', cursor: 'pointer',
          background: 'rgba(255,255,255,0.6)',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}>
          <Icon name="chevron-left" size={18} color={T.ink} strokeWidth={2.2} />
        </button>
        <div style={{ fontSize: 17, fontWeight: 600, color: T.ink, marginLeft: 4 }}>Settings</div>
      </div>
      <div style={{ padding: '4px 16px 8px' }}>
        <div style={{
          fontFamily: 'Georgia, serif', fontSize: 28, fontWeight: 700, color: T.ink,
          letterSpacing: -0.5, marginTop: 4,
        }}>Settings</div>
      </div>

      <div style={{ overflowY: 'auto', flex: 1, paddingBottom: 24 }}>
        {/* Playback */}
        <SectionHeader>Playback</SectionHeader>
        <div style={{ margin: '0 16px', background: T.card, borderRadius: 16, padding: '14px 16px' }}>
          <div style={{ fontSize: 14, color: T.ink, fontWeight: 600, letterSpacing: -0.2, marginBottom: 10 }}>Skip interval</div>
          <div style={{ display: 'flex', gap: 8 }}>
            {['10s', '15s', '30s', '60s'].map((v, i) => (
              <button key={v} style={{
                flex: 1, padding: '10px 0',
                background: i === 1 ? T.ink : T.cardSoft,
                color: i === 1 ? '#F4ECDB' : T.ink,
                border: 'none', borderRadius: 10, cursor: 'pointer',
                fontSize: 14, fontWeight: 600, letterSpacing: -0.1,
              }}>{v}</button>
            ))}
          </div>
        </div>

        {/* Audio Source */}
        <SectionHeader>Audio Source</SectionHeader>
        <div style={{ margin: '0 16px', background: T.card, borderRadius: 16, padding: 16 }}>
          <div style={{
            display: 'flex', background: T.cardSoft, borderRadius: 10, padding: 3, marginBottom: 14,
          }}>
            {['On-Device', 'Companion'].map((v, i) => (
              <button key={v} style={{
                flex: 1, padding: '8px 0',
                background: i === 1 ? '#fff' : 'transparent',
                color: T.ink,
                border: 'none', borderRadius: 8, cursor: 'pointer',
                fontSize: 13, fontWeight: 600,
                boxShadow: i === 1 ? '0 1px 3px rgba(0,0,0,0.08)' : 'none',
              }}>{v}</button>
            ))}
          </div>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
            <FormField label="Host" value="192.168.1.42" mono />
            <FormField label="Port" value="8080" mono />
          </div>
          <button style={{
            marginTop: 12, padding: '10px 14px', borderRadius: 10,
            background: T.tealSoft, color: T.tealInk, border: 'none',
            cursor: 'pointer', fontSize: 13.5, fontWeight: 600,
            display: 'inline-flex', alignItems: 'center', gap: 6,
          }}>
            <span style={{ width: 8, height: 8, borderRadius: 4, background: T.teal }} />
            Connected to mac-mini.local
          </button>
          <div style={{ fontSize: 12, color: T.inkSoft, marginTop: 12, lineHeight: 1.45 }}>
            Run AudioLib Companion on your Mac to download faster and bypass YouTube throttling. <span style={{ color: T.tealInk, fontWeight: 600 }}>Setup instructions →</span>
          </div>
        </div>

        {/* Storage */}
        <SectionHeader>Storage</SectionHeader>
        <div style={{ margin: '0 16px', background: T.card, borderRadius: 16, overflow: 'hidden' }}>
          <SettingsRow l="Library size" v="2.84 GB" />
          <SettingsRow l="Books" v="7" last />
        </div>

        {/* Danger */}
        <SectionHeader>Danger Zone</SectionHeader>
        <div style={{ margin: '0 16px', background: T.card, borderRadius: 16, overflow: 'hidden' }}>
          <button style={{
            width: '100%', padding: '14px 16px',
            background: 'transparent', border: 'none', cursor: 'pointer',
            display: 'flex', alignItems: 'center', gap: 10,
            color: T.red, fontSize: 15, fontWeight: 600, letterSpacing: -0.2,
          }}>
            <Icon name="trash" size={18} color={T.red} strokeWidth={1.9} />
            Delete All Books
          </button>
        </div>

        <SectionHeader>About</SectionHeader>
        <div style={{ margin: '0 16px 36px', background: T.card, borderRadius: 16, overflow: 'hidden' }}>
          <SettingsRow l="Version" v="1.4.2 (231)" last />
        </div>
      </div>
    </div>
  );
}

function FormField({ label, value, mono }) {
  return (
    <div style={{
      display: 'flex', alignItems: 'center', justifyContent: 'space-between',
      padding: '10px 12px', background: T.cardSoft, borderRadius: 10,
    }}>
      <div style={{ fontSize: 13, color: T.inkSoft }}>{label}</div>
      <div style={{
        fontSize: 14, color: T.ink, fontWeight: 500,
        fontFamily: mono ? 'ui-monospace, SF Mono, monospace' : 'inherit',
        fontVariantNumeric: 'tabular-nums',
      }}>{value}</div>
    </div>
  );
}

function SettingsRow({ l, v, last }) {
  return (
    <div style={{
      padding: '14px 16px',
      display: 'flex', alignItems: 'center', justifyContent: 'space-between',
      borderBottom: last ? 'none' : '0.5px solid ' + T.hair,
    }}>
      <div style={{ fontSize: 15, color: T.ink, letterSpacing: -0.2 }}>{l}</div>
      <div style={{ fontSize: 14, color: T.inkSoft, fontVariantNumeric: 'tabular-nums' }}>{v}</div>
    </div>
  );
}

Object.assign(window, {
  NotesScreen, NoteEditor, PlayerScreen, BookEditSheet, SettingsScreen,
  SpeedSheet, SleepSheet, BookmarksSheet, ChaptersSheet, PlayerSheet,
});
