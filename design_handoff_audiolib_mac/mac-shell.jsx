// Mac AudioLib — shared shell + bottom player bar + sidebar

const MAC = '-apple-system, BlinkMacSystemFont, "SF Pro", "Helvetica Neue", sans-serif';

// ─── Window shell w/ floating sidebar + player bar ─────────
function AudioLibWindow({ width = 1280, height = 820, children, sidebar, playerBar, sidebarCollapsed }) {
  return (
    <div style={{
      width, height, borderRadius: 14, overflow: 'hidden',
      background: T.bg,
      boxShadow: '0 0 0 0.5px rgba(0,0,0,0.22), 0 24px 60px rgba(0,0,0,0.30)',
      display: 'flex', flexDirection: 'column', position: 'relative',
      fontFamily: MAC,
    }}>
      <div style={{ flex: 1, display: 'flex', minHeight: 0 }}>
        {!sidebarCollapsed && sidebar}
        <div style={{ flex: 1, display: 'flex', flexDirection: 'column', minWidth: 0 }}>
          {children}
        </div>
      </div>
      {playerBar}
    </div>
  );
}

// ─── Sidebar ───────────────────────────────────────────────
function MSidebarItem({ icon, label, count, selected, onClick, indent = 0 }) {
  return (
    <button onClick={onClick} style={{
      display: 'flex', alignItems: 'center', gap: 8,
      width: 'calc(100% - 16px)', margin: '0 8px',
      padding: `5px 10px 5px ${10 + indent}px`,
      borderRadius: 6, border: 'none',
      background: selected ? 'rgba(30, 144, 133, 0.13)' : 'transparent',
      color: selected ? T.tealInk : T.ink,
      fontFamily: MAC, fontSize: 12.5, fontWeight: 500,
      textAlign: 'left', cursor: 'pointer',
      letterSpacing: -0.1,
    }}>
      <span style={{ width: 16, height: 16, display: 'inline-flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0, color: selected ? T.teal : T.inkSoft }}>
        <Icon name={icon} size={14} color={selected ? T.teal : T.inkSoft} strokeWidth={1.8} />
      </span>
      <span style={{ flex: 1, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{label}</span>
      {count !== undefined && (
        <span style={{
          fontSize: 11, color: selected ? T.tealInk : T.inkMute,
          fontVariantNumeric: 'tabular-nums', fontWeight: 500,
        }}>{count}</span>
      )}
    </button>
  );
}

function MSidebarHeader({ children }) {
  return (
    <div style={{
      fontSize: 10.5, fontWeight: 700, letterSpacing: 0.8,
      textTransform: 'uppercase', color: T.inkMute,
      padding: '14px 18px 4px',
    }}>{children}</div>
  );
}

function MSidebar({ active = 'all-books', onSelect = () => {}, trafficLights = true }) {
  return (
    <div style={{
      width: 232, flexShrink: 0, height: '100%',
      background: 'rgba(232, 226, 212, 0.62)',
      backdropFilter: 'blur(40px) saturate(180%)',
      WebkitBackdropFilter: 'blur(40px) saturate(180%)',
      borderRight: '0.5px solid rgba(27, 24, 20, 0.08)',
      display: 'flex', flexDirection: 'column',
    }}>
      {/* Traffic lights */}
      {trafficLights && (
        <div style={{
          height: 38, display: 'flex', alignItems: 'center',
          padding: '0 14px', flexShrink: 0,
          gap: 8,
        }}>
          <div style={{ display: 'flex', gap: 8 }}>
            <span style={{ width: 12, height: 12, borderRadius: 6, background: '#FF5F57', border: '0.5px solid rgba(0,0,0,0.08)' }} />
            <span style={{ width: 12, height: 12, borderRadius: 6, background: '#FEBC2E', border: '0.5px solid rgba(0,0,0,0.08)' }} />
            <span style={{ width: 12, height: 12, borderRadius: 6, background: '#28C840', border: '0.5px solid rgba(0,0,0,0.08)' }} />
          </div>
        </div>
      )}

      {/* App branding */}
      <div style={{
        padding: '6px 16px 8px', display: 'flex', alignItems: 'center', gap: 9,
      }}>
        <div style={{
          width: 26, height: 26, borderRadius: 7,
          background: 'linear-gradient(160deg, #0F5751 0%, #1E9085 100%)',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          boxShadow: '0 1px 3px rgba(15,87,81,0.4), inset 0 1px 0 rgba(255,255,255,0.2)',
        }}>
          <svg width="16" height="16" viewBox="0 0 64 64" fill="none">
            <path d="M12 36 V32 a20 20 0 0 1 40 0 V36" stroke="#F4ECDB" strokeWidth="5" strokeLinecap="round"/>
            <rect x="8" y="36" width="12" height="18" rx="4" fill="#F4ECDB"/>
            <rect x="44" y="36" width="12" height="18" rx="4" fill="#F4ECDB"/>
          </svg>
        </div>
        <div style={{
          fontFamily: 'Georgia, serif', fontSize: 17, fontWeight: 700,
          color: T.ink, letterSpacing: -0.3,
        }}>AudioLib</div>
      </div>

      <div style={{ flex: 1, overflowY: 'auto', paddingBottom: 8 }}>
        <MSidebarHeader>Library</MSidebarHeader>
        <MSidebarItem icon="books"            label="All Books"          count={7}  selected={active === 'all-books'}      onClick={() => onSelect('all-books')} />
        <MSidebarItem icon="play-line"        label="Continue Listening" count={3}  selected={active === 'continue'}       onClick={() => onSelect('continue')} />
        <MSidebarItem icon="clock"            label="Recently Added"     count={5}  selected={active === 'recent'}         onClick={() => onSelect('recent')} />
        <MSidebarItem icon="check"            label="Finished"           count={2}  selected={active === 'finished'}       onClick={() => onSelect('finished')} />

        <MSidebarHeader>Downloads</MSidebarHeader>
        <MSidebarItem icon="arrow-down-circle" label="Active"            count={3}  selected={active === 'downloads'}      onClick={() => onSelect('downloads')} />
        <MSidebarItem icon="check-fill"        label="Completed"         count={12} selected={active === 'completed'}      onClick={() => onSelect('completed')} />

        <MSidebarHeader>Notes</MSidebarHeader>
        <MSidebarItem icon="note"             label="All Notes"          count={14} selected={active === 'all-notes'}      onClick={() => onSelect('all-notes')} />
        <MSidebarItem icon="link"             label="Linked to Books"    count={9}  selected={active === 'linked-notes'}   onClick={() => onSelect('linked-notes')} />

        <MSidebarHeader>Series</MSidebarHeader>
        <MSidebarItem icon="books" label="Dune" selected={active === 'series-dune'} onClick={() => onSelect('series-dune')} />
        <MSidebarItem icon="books" label="Remembrance of Earth's Past" selected={active === 'series-rep'} onClick={() => onSelect('series-rep')} />
      </div>

      {/* Footer — Companion mode + settings */}
      <div style={{
        borderTop: '0.5px solid rgba(27,24,20,0.08)',
        padding: 10, display: 'flex', flexDirection: 'column', gap: 8,
      }}>
        <div style={{
          background: 'rgba(255,255,255,0.5)', borderRadius: 8,
          padding: '8px 10px',
        }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
            <span style={{ width: 7, height: 7, borderRadius: 4, background: T.teal, boxShadow: `0 0 0 3px rgba(30,144,133,0.18)` }} />
            <span style={{ fontSize: 11, fontWeight: 600, color: T.ink, letterSpacing: -0.1 }}>Companion mode</span>
          </div>
          <div style={{ fontSize: 10.5, color: T.inkSoft, marginTop: 2, fontFamily: 'ui-monospace, SF Mono, monospace' }}>
            mac-mini.local:8080 · 2 connected
          </div>
        </div>
        <button onClick={() => onSelect('settings')} style={{
          background: 'transparent', border: 'none', cursor: 'pointer',
          padding: '6px 8px', borderRadius: 6,
          display: 'flex', alignItems: 'center', gap: 8,
          color: T.inkSoft, fontSize: 12, fontWeight: 500, fontFamily: MAC,
          textAlign: 'left',
        }}>
          <Icon name="gear" size={14} color={T.inkSoft} strokeWidth={1.8} />
          <span>Preferences…</span>
        </button>
      </div>
    </div>
  );
}

// ─── Top toolbar (per-view) ────────────────────────────────
function MToolbar({ title, subtitle, leading, trailing, dark = false }) {
  return (
    <div style={{
      height: 50, flexShrink: 0,
      padding: '0 20px',
      display: 'flex', alignItems: 'center', gap: 10,
      borderBottom: '0.5px solid ' + (dark ? 'rgba(255,255,255,0.06)' : 'rgba(27,24,20,0.08)'),
      background: dark ? 'transparent' : 'rgba(241,236,226,0.7)',
      backdropFilter: 'blur(20px)',
      color: dark ? '#fff' : T.ink,
    }}>
      {leading}
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{
          fontFamily: 'Georgia, serif', fontSize: 18, fontWeight: 700,
          letterSpacing: -0.3, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis',
        }}>{title}</div>
        {subtitle && (
          <div style={{ fontSize: 11.5, color: dark ? 'rgba(255,255,255,0.55)' : T.inkSoft, marginTop: -1 }}>{subtitle}</div>
        )}
      </div>
      {trailing}
    </div>
  );
}

function MIconButton({ icon, onClick, label, active, primary, size = 28 }) {
  return (
    <button onClick={onClick} title={label} style={{
      height: size, padding: label ? '0 10px' : 0, minWidth: size,
      display: 'inline-flex', alignItems: 'center', gap: 5,
      borderRadius: 7,
      background: primary ? T.ink : active ? 'rgba(30,144,133,0.13)' : 'rgba(255,255,255,0.6)',
      border: '0.5px solid ' + (primary ? T.ink : 'rgba(27,24,20,0.08)'),
      color: primary ? '#F4ECDB' : active ? T.tealInk : T.ink,
      cursor: 'pointer', fontFamily: MAC, fontSize: 12, fontWeight: 600, letterSpacing: -0.1,
    }}>
      {icon && <Icon name={icon} size={14} color={primary ? '#F4ECDB' : active ? T.tealInk : T.ink} strokeWidth={1.9} />}
      {label && <span>{label}</span>}
    </button>
  );
}

function MSegmented({ value, onChange, options }) {
  return (
    <div style={{
      display: 'inline-flex', background: 'rgba(27,24,20,0.06)', borderRadius: 7,
      padding: 2, gap: 0,
    }}>
      {options.map((o) => {
        const active = o.value === value;
        return (
          <button key={o.value} onClick={() => onChange?.(o.value)} style={{
            padding: '5px 9px', borderRadius: 5, border: 'none', cursor: 'pointer',
            background: active ? '#fff' : 'transparent',
            boxShadow: active ? '0 1px 2px rgba(0,0,0,0.08), 0 0 0 0.5px rgba(0,0,0,0.04)' : 'none',
            color: T.ink, fontSize: 11.5, fontWeight: 600,
            display: 'inline-flex', alignItems: 'center', gap: 4, fontFamily: MAC,
          }}>
            {o.icon && <Icon name={o.icon} size={12} color={T.ink} strokeWidth={1.9} />}
            {o.label}
          </button>
        );
      })}
    </div>
  );
}

// ─── Bottom player bar ─────────────────────────────────────
function MPlayerBar({ playing = true, onTogglePlay, onExpand, book = BOOKS.habits, sleepActive = true }) {
  return (
    <div style={{
      height: 78, flexShrink: 0,
      background: 'rgba(27, 24, 20, 0.97)',
      backdropFilter: 'blur(40px)',
      borderTop: '0.5px solid rgba(27,24,20,0.4)',
      color: '#F4ECDB',
      display: 'flex', alignItems: 'center',
      padding: '0 16px', gap: 16,
      position: 'relative',
    }}>
      {/* Left: cover + title */}
      <div onClick={onExpand} style={{
        display: 'flex', alignItems: 'center', gap: 12,
        width: 280, flexShrink: 0, cursor: 'pointer',
      }}>
        <Cover which={book.id} size={54} radius={6} />
        <div style={{ minWidth: 0, flex: 1 }}>
          <div style={{
            fontSize: 13, fontWeight: 600, color: '#fff', letterSpacing: -0.2,
            whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis',
          }}>{book.title}</div>
          <div style={{
            fontSize: 11.5, color: 'rgba(244,236,219,0.55)', marginTop: 1,
            whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis',
          }}>{book.author}</div>
        </div>
        <button onClick={(e) => e.stopPropagation()} style={{
          width: 26, height: 26, borderRadius: 13,
          background: 'transparent', border: 'none', cursor: 'pointer',
          color: 'rgba(244,236,219,0.5)', display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0,
        }}>
          <Icon name="bookmark" size={14} color="rgba(244,236,219,0.5)" />
        </button>
      </div>

      {/* Center: transport */}
      <div style={{
        flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center',
        gap: 6, maxWidth: 760, padding: '0 12px',
      }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 18 }}>
          <button style={{ background: 'none', border: 'none', cursor: 'pointer', padding: 0, color: 'rgba(244,236,219,0.7)', display: 'flex', alignItems: 'center' }}>
            <MacSkip dir="back" seconds={15} size={22} />
          </button>
          <button style={{ background: 'none', border: 'none', cursor: 'pointer', padding: 0, color: 'rgba(244,236,219,0.5)' }}>
            <Icon name="chevron-left" size={14} color="rgba(244,236,219,0.5)" strokeWidth={2.2} />
          </button>
          <button onClick={onTogglePlay} style={{
            width: 32, height: 32, borderRadius: 16, border: 'none', cursor: 'pointer',
            background: '#F4ECDB', color: T.ink,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            boxShadow: '0 2px 6px rgba(0,0,0,0.3)',
          }}>
            <Icon name={playing ? 'pause' : 'play'} size={14} color={T.ink} />
          </button>
          <button style={{ background: 'none', border: 'none', cursor: 'pointer', padding: 0, color: 'rgba(244,236,219,0.5)' }}>
            <Icon name="chevron-right" size={14} color="rgba(244,236,219,0.5)" strokeWidth={2.2} />
          </button>
          <button style={{ background: 'none', border: 'none', cursor: 'pointer', padding: 0, color: 'rgba(244,236,219,0.7)', display: 'flex', alignItems: 'center' }}>
            <MacSkip dir="fwd" seconds={15} size={22} />
          </button>
        </div>
        <div style={{ display: 'flex', alignItems: 'center', gap: 10, width: '100%' }}>
          <span style={{ fontSize: 10.5, color: 'rgba(244,236,219,0.55)', fontVariantNumeric: 'tabular-nums', fontFamily: 'ui-monospace, monospace', width: 50, textAlign: 'right' }}>2:14:08</span>
          <div style={{ flex: 1, height: 4, borderRadius: 2, background: 'rgba(255,255,255,0.12)', position: 'relative', cursor: 'pointer' }}>
            <div style={{ width: '38%', height: '100%', borderRadius: 2, background: '#F4ECDB' }} />
            <div style={{ position: 'absolute', left: '38%', top: '50%', width: 10, height: 10, borderRadius: 5, background: '#F4ECDB', transform: 'translate(-50%, -50%)', boxShadow: '0 1px 3px rgba(0,0,0,0.4)' }} />
          </div>
          <span style={{ fontSize: 10.5, color: 'rgba(244,236,219,0.55)', fontVariantNumeric: 'tabular-nums', fontFamily: 'ui-monospace, monospace', width: 50 }}>-3:47:22</span>
        </div>
      </div>

      {/* Right: secondary controls */}
      <div style={{
        width: 280, flexShrink: 0, display: 'flex', alignItems: 'center', justifyContent: 'flex-end', gap: 4,
      }}>
        <MacBarPill label="1.5×" />
        <MacBarIcon icon="moon" active={sleepActive} hint={sleepActive ? '22:13' : null} />
        <MacBarIcon icon="list" />
        <MacBarIcon icon="bookmark" />
        <div style={{ width: 12 }} />
        {/* Volume */}
        <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
          <Icon name="speaker" size={14} color="rgba(244,236,219,0.55)" strokeWidth={1.9} />
          <div style={{ width: 78, height: 3, borderRadius: 2, background: 'rgba(255,255,255,0.12)', position: 'relative' }}>
            <div style={{ width: '72%', height: '100%', background: 'rgba(244,236,219,0.8)', borderRadius: 2 }} />
            <div style={{ position: 'absolute', left: '72%', top: '50%', width: 8, height: 8, borderRadius: 4, background: '#F4ECDB', transform: 'translate(-50%, -50%)' }} />
          </div>
        </div>
        <button onClick={onExpand} style={{
          marginLeft: 8, width: 26, height: 26, borderRadius: 13,
          background: 'rgba(255,255,255,0.08)', border: 'none', cursor: 'pointer',
          color: 'rgba(244,236,219,0.75)', display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}>
          <Icon name="chevron-up" size={12} color="rgba(244,236,219,0.85)" strokeWidth={2.2} />
        </button>
      </div>
    </div>
  );
}

function MacBarPill({ label }) {
  return (
    <button style={{
      height: 24, padding: '0 8px', borderRadius: 6,
      background: 'transparent', border: 'none', cursor: 'pointer',
      color: 'rgba(244,236,219,0.85)', fontSize: 11.5, fontWeight: 700, letterSpacing: -0.2,
      fontFamily: MAC, fontVariantNumeric: 'tabular-nums',
    }}>{label}</button>
  );
}
function MacBarIcon({ icon, active, hint }) {
  return (
    <button style={{
      height: 24, padding: '0 6px', borderRadius: 6,
      background: active ? 'rgba(30,144,133,0.22)' : 'transparent', border: 'none', cursor: 'pointer',
      color: active ? T.teal : 'rgba(244,236,219,0.7)',
      display: 'inline-flex', alignItems: 'center', gap: 4,
      fontFamily: MAC, fontSize: 10.5, fontWeight: 600, fontVariantNumeric: 'tabular-nums',
    }}>
      <Icon name={icon} size={14} color={active ? T.teal : 'rgba(244,236,219,0.7)'} fill={icon === 'moon' && active ? T.teal : 'none'} strokeWidth={active ? 0 : 1.8} />
      {hint && <span>{hint}</span>}
    </button>
  );
}

// Mac-friendly skip icon (a slim circular arrow with the number)
function MacSkip({ dir = 'back', seconds = 15, size = 22 }) {
  return (
    <div style={{ position: 'relative', width: size, height: size }}>
      <svg width={size} height={size} viewBox="0 0 24 24" fill="none">
        {dir === 'back' ? (
          <>
            <path d="M12 5 a7 7 0 1 0 6 3.5" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" fill="none"/>
            <path d="M12 2.5 l2 2 -2 2" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" fill="none"/>
          </>
        ) : (
          <>
            <path d="M12 5 a7 7 0 1 1 -6 3.5" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" fill="none"/>
            <path d="M12 2.5 l-2 2 2 2" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" fill="none"/>
          </>
        )}
      </svg>
      <span style={{
        position: 'absolute', inset: 0, display: 'flex', alignItems: 'center', justifyContent: 'center',
        fontSize: size * 0.4, fontWeight: 700, color: 'currentColor', paddingTop: size * 0.08,
        fontFamily: MAC,
      }}>{seconds}</span>
    </div>
  );
}

Object.assign(window, {
  MAC, AudioLibWindow, MSidebar, MSidebarItem, MSidebarHeader, MToolbar, MIconButton, MSegmented, MPlayerBar, MacSkip,
});
