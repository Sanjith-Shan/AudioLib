// Shared components & design tokens for AudioLib

const T = {
  // Warm paper palette
  bg: '#F1ECE2',
  bgAlt: '#E8E2D4',
  card: '#FFFFFF',
  cardSoft: '#F8F5EE',
  ink: '#1B1814',
  inkSoft: 'rgba(27, 24, 20, 0.62)',
  inkMute: 'rgba(27, 24, 20, 0.38)',
  inkFaint: 'rgba(27, 24, 20, 0.12)',
  hair: 'rgba(27, 24, 20, 0.08)',
  // Accent: teal
  teal: '#1E9085',
  tealSoft: '#D4ECE9',
  tealInk: '#0E5751',
  // Destructive
  red: '#C8443A',
  // Player dark
  dBg: '#0D0D10',
  dCard: '#1B1B20',
  dInk: '#FFFFFF',
  dInkSoft: 'rgba(255,255,255,0.62)',
  dInkMute: 'rgba(255,255,255,0.38)',
  dInkFaint: 'rgba(255,255,255,0.12)',
};

// ─── Cover art generator ───────────────────────────────────
// Tasteful book-cover placeholders. Each cover has a fixed
// palette + a typographic treatment.
const COVERS = {
  gatsby: {
    bg: 'linear-gradient(160deg, #0F3D38 0%, #1A5D54 60%, #2A8077 100%)',
    fg: '#F4E4B8', accent: '#E8B547',
    title: 'The Great\nGatsby', author: 'F. Scott Fitzgerald',
    motif: 'art-deco',
  },
  sapiens: {
    bg: 'linear-gradient(180deg, #D14B3A 0%, #B83025 100%)',
    fg: '#FFF8E7', accent: '#FFD37A',
    title: 'Sapiens', author: 'Yuval Noah Harari',
    motif: 'hand',
  },
  habits: {
    bg: 'linear-gradient(180deg, #1B4B7A 0%, #0F2D4D 100%)',
    fg: '#F2E9D5', accent: '#E8B547',
    title: 'Atomic\nHabits', author: 'James Clear',
    motif: 'circles',
  },
  hailmary: {
    bg: 'radial-gradient(circle at 30% 30%, #2D1B5A 0%, #0A0820 70%)',
    fg: '#FFFFFF', accent: '#7AD0E0',
    title: 'Project\nHail Mary', author: 'Andy Weir',
    motif: 'stars',
  },
  dune: {
    bg: 'linear-gradient(180deg, #C9853C 0%, #8C4A1F 100%)',
    fg: '#1A0F08', accent: '#3D1F10',
    title: 'Dune', author: 'Frank Herbert',
    motif: 'dune',
  },
  threebody: {
    bg: 'linear-gradient(160deg, #1A1A1A 0%, #0A0A0A 100%)',
    fg: '#E8C547', accent: '#C83A3A',
    title: 'The Three-\nBody Problem', author: 'Cixin Liu',
    motif: 'orbits',
  },
  educated: {
    bg: 'linear-gradient(180deg, #E8DCC4 0%, #C9B889 100%)',
    fg: '#3D2818', accent: '#8C5A2A',
    title: 'Educated', author: 'Tara Westover',
    motif: 'pencil',
  },
  becoming: {
    bg: 'linear-gradient(180deg, #2A2A2A 0%, #0E0E0E 100%)',
    fg: '#F4E4B8', accent: '#D4A547',
    title: 'Becoming', author: 'Michelle Obama',
    motif: 'minimal',
  },
};

function Cover({ which = 'gatsby', size = 64, radius }) {
  const c = COVERS[which] || COVERS.gatsby;
  const r = radius ?? Math.max(4, size * 0.06);
  const titleSize = size * 0.14;
  const authorSize = Math.max(6, size * 0.06);

  // Motif decoration
  const motif = () => {
    const s = size;
    if (c.motif === 'art-deco') {
      return (
        <svg width={s} height={s} style={{ position: 'absolute', inset: 0, opacity: 0.5 }}>
          <circle cx={s / 2} cy={s * 0.32} r={s * 0.06} fill="none" stroke={c.accent} strokeWidth={s * 0.008} />
          <circle cx={s / 2} cy={s * 0.32} r={s * 0.11} fill="none" stroke={c.accent} strokeWidth={s * 0.005} />
        </svg>
      );
    }
    if (c.motif === 'circles') {
      return (
        <svg width={s} height={s} style={{ position: 'absolute', inset: 0 }}>
          <circle cx={s * 0.78} cy={s * 0.18} r={s * 0.08} fill={c.accent} opacity="0.9" />
          <circle cx={s * 0.78} cy={s * 0.18} r={s * 0.04} fill={c.bg.match(/#\w+/)?.[0] || '#000'} />
        </svg>
      );
    }
    if (c.motif === 'stars') {
      return (
        <svg width={s} height={s} style={{ position: 'absolute', inset: 0 }}>
          {[[0.2, 0.18], [0.78, 0.12], [0.85, 0.45], [0.15, 0.6], [0.6, 0.78], [0.4, 0.3]].map(([x, y], i) => (
            <circle key={i} cx={s * x} cy={s * y} r={s * (0.005 + (i % 3) * 0.003)} fill={c.accent} opacity={0.7} />
          ))}
        </svg>
      );
    }
    if (c.motif === 'orbits') {
      return (
        <svg width={s} height={s} style={{ position: 'absolute', inset: 0, opacity: 0.6 }}>
          <ellipse cx={s / 2} cy={s * 0.55} rx={s * 0.3} ry={s * 0.08} fill="none" stroke={c.accent} strokeWidth={s * 0.004} />
          <ellipse cx={s / 2} cy={s * 0.55} rx={s * 0.42} ry={s * 0.13} fill="none" stroke={c.accent} strokeWidth={s * 0.004} transform={`rotate(20 ${s / 2} ${s * 0.55})`} />
        </svg>
      );
    }
    if (c.motif === 'dune') {
      return (
        <svg width={s} height={s} style={{ position: 'absolute', inset: 0 }} viewBox={`0 0 ${s} ${s}`}>
          <path d={`M0 ${s * 0.75} Q ${s * 0.3} ${s * 0.6} ${s * 0.6} ${s * 0.75} T ${s} ${s * 0.78} L ${s} ${s} L 0 ${s} Z`} fill={c.accent} opacity="0.5" />
        </svg>
      );
    }
    return null;
  };

  return (
    <div style={{
      width: size, height: size, borderRadius: r,
      background: c.bg, position: 'relative', overflow: 'hidden',
      boxShadow: `inset 0 0 0 0.5px rgba(0,0,0,0.25), 0 ${size * 0.02}px ${size * 0.06}px rgba(0,0,0,0.18)`,
      flexShrink: 0,
    }}>
      {motif()}
      {/* Spine highlight */}
      <div style={{
        position: 'absolute', left: 0, top: 0, bottom: 0, width: size * 0.04,
        background: 'linear-gradient(90deg, rgba(255,255,255,0.18) 0%, rgba(255,255,255,0) 100%)',
      }} />
      {/* Title block */}
      <div style={{
        position: 'absolute', inset: `${size * 0.1}px ${size * 0.08}px`,
        display: 'flex', flexDirection: 'column', justifyContent: 'space-between',
      }}>
        <div style={{
          color: c.fg, fontFamily: 'Georgia, "Iowan Old Style", serif',
          fontSize: titleSize, lineHeight: 1.05, fontWeight: 700,
          letterSpacing: -0.3, whiteSpace: 'pre-line',
          textShadow: size > 80 ? '0 1px 2px rgba(0,0,0,0.2)' : 'none',
        }}>{c.title}</div>
        <div style={{
          color: c.fg, opacity: 0.85, fontFamily: 'Georgia, serif',
          fontSize: authorSize, fontStyle: 'italic',
          letterSpacing: 0.2,
        }}>{c.author}</div>
      </div>
    </div>
  );
}

const BOOKS = {
  gatsby:    { id: 'gatsby',    title: 'The Great Gatsby',     author: 'F. Scott Fitzgerald', series: null,                       remain: '4h 12m', progress: 0.18 },
  sapiens:   { id: 'sapiens',   title: 'Sapiens',              author: 'Yuval Noah Harari',   series: null,                       remain: '12h 04m', progress: 0.42 },
  habits:    { id: 'habits',    title: 'Atomic Habits',        author: 'James Clear',         series: null,                       remain: '3h 47m', progress: 0.62 },
  hailmary:  { id: 'hailmary',  title: 'Project Hail Mary',    author: 'Andy Weir',           series: null,                       remain: '8h 29m', progress: 0.31 },
  dune:      { id: 'dune',      title: 'Dune',                 author: 'Frank Herbert',       series: { name: 'Dune', n: 1 },     remain: '17h 11m', progress: 0.05 },
  threebody: { id: 'threebody', title: 'The Three-Body Problem', author: 'Cixin Liu',         series: { name: 'Remembrance', n: 1 }, remain: '9h 03m', progress: 0.78 },
  educated:  { id: 'educated',  title: 'Educated',             author: 'Tara Westover',       series: null,                       remain: '6h 22m', progress: 1.0 },
  becoming:  { id: 'becoming',  title: 'Becoming',             author: 'Michelle Obama',      series: null,                       remain: '0h 0m',  progress: 0 },
};

// ─── Icons ─────────────────────────────────────────────────
const Icon = ({ name, size = 22, color = 'currentColor', strokeWidth = 1.8, fill = 'none' }) => {
  const s = size;
  const paths = {
    'arrow-down-circle': <><circle cx="12" cy="12" r="10"/><path d="M12 7v9m-4-4l4 4 4-4"/></>,
    'books': <><path d="M4 4h4v16H4zM10 6h4v14h-4z"/><path d="M16 8l4 1-3 14-4-1z"/></>,
    'note': <><path d="M5 4h11l4 4v12H5z"/><path d="M16 4v4h4"/><path d="M8 12h8M8 16h6"/></>,
    'gear': <><circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1-2.83 2.83l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-4 0v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83-2.83l.06-.06a1.65 1.65 0 0 0 .33-1.82 1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1 0-4h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 2.83-2.83l.06.06a1.65 1.65 0 0 0 1.82.33H9a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 4 0v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82V9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 0 4h-.09a1.65 1.65 0 0 0-1.51 1z"/></>,
    'search': <><circle cx="11" cy="11" r="7"/><path d="m20 20-3.5-3.5"/></>,
    'play': <path d="M7 4v16l13-8z" fill={color} stroke="none"/>,
    'play-line': <path d="M7 4v16l13-8z"/>,
    'pause': <><rect x="6" y="4" width="4" height="16" rx="1" fill={color} stroke="none"/><rect x="14" y="4" width="4" height="16" rx="1" fill={color} stroke="none"/></>,
    'x': <path d="M6 6l12 12M18 6L6 18"/>,
    'chevron-down': <path d="M6 9l6 6 6-6"/>,
    'chevron-up': <path d="M6 15l6-6 6 6"/>,
    'chevron-right': <path d="M9 6l6 6-6 6"/>,
    'chevron-left': <path d="M15 6l-6 6 6 6"/>,
    'plus': <path d="M12 5v14M5 12h14"/>,
    'check': <path d="M5 12l5 5 9-11"/>,
    'moon': <path d="M21 12.8A9 9 0 1 1 11.2 3a7 7 0 0 0 9.8 9.8z"/>,
    'list': <><path d="M8 6h13M8 12h13M8 18h13"/><circle cx="4" cy="6" r="1" fill={color}/><circle cx="4" cy="12" r="1" fill={color}/><circle cx="4" cy="18" r="1" fill={color}/></>,
    'bookmark': <path d="M6 3h12v18l-6-4-6 4z"/>,
    'bookmark-fill': <path d="M6 3h12v18l-6-4-6 4z" fill={color}/>,
    'speaker': <><path d="M3 9v6h4l5 5V4L7 9z"/><path d="M16 8a5 5 0 0 1 0 8"/></>,
    'skip-back-15': null, // custom
    'skip-fwd-15': null, // custom
    'more': <><circle cx="5" cy="12" r="1.5" fill={color}/><circle cx="12" cy="12" r="1.5" fill={color}/><circle cx="19" cy="12" r="1.5" fill={color}/></>,
    'sort': <><path d="M4 6h16M6 12h12M10 18h4"/></>,
    'trash': <><path d="M4 7h16M9 7V4h6v3M6 7l1 13h10l1-13"/></>,
    'edit': <><path d="M4 20h4l11-11-4-4L4 16z"/><path d="M14 5l4 4"/></>,
    'link': <><path d="M10 14a3 3 0 0 0 4.2 0l3-3a3 3 0 0 0-4.2-4.2L12 8"/><path d="M14 10a3 3 0 0 0-4.2 0l-3 3a3 3 0 0 0 4.2 4.2L12 16"/></>,
    'bold': <path d="M7 5h6a3.5 3.5 0 1 1 0 7H7zm0 7h7a3.5 3.5 0 1 1 0 7H7z"/>,
    'italic': <path d="M10 5h8M6 19h8M14 5l-4 14"/>,
    'underline': <><path d="M7 5v8a5 5 0 0 0 10 0V5"/><path d="M5 21h14"/></>,
    'h1': <><path d="M4 5v14M12 5v14M4 12h8"/><path d="M16 8l2-1v12"/></>,
    'h2': <><path d="M4 5v14M12 5v14M4 12h8"/><path d="M16 9a2 2 0 1 1 4 0c0 2-4 4-4 8h4"/></>,
    'bullet-list': <><circle cx="5" cy="7" r="1.5" fill={color}/><circle cx="5" cy="12" r="1.5" fill={color}/><circle cx="5" cy="17" r="1.5" fill={color}/><path d="M10 7h10M10 12h10M10 17h10"/></>,
    'num-list': <><path d="M10 7h10M10 12h10M10 17h10"/><path d="M4 5l1-1v5M3 14h2.5L3 17h2.5"/></>,
    'clock': <><circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/></>,
    'wifi-x': <><path d="M5 12a10 10 0 0 1 14 0M8 15a6 6 0 0 1 8 0"/><circle cx="12" cy="19" r="1" fill={color}/></>,
    'check-fill': <><circle cx="12" cy="12" r="10" fill={color} stroke="none"/><path d="M8 12l3 3 5-6" stroke="#fff" strokeWidth="2.2"/></>,
  };
  const p = paths[name];
  if (!p) return null;
  return (
    <svg width={s} height={s} viewBox="0 0 24 24" fill={fill} stroke={color} strokeWidth={strokeWidth} strokeLinecap="round" strokeLinejoin="round" style={{ display: 'block' }}>{p}</svg>
  );
};

// ─── Progress bar ──────────────────────────────────────────
function ProgressBar({ value = 0.4, height = 3, color, track, dark = false }) {
  return (
    <div style={{
      width: '100%', height, borderRadius: height,
      background: track || (dark ? T.dInkFaint : T.inkFaint),
      overflow: 'hidden',
    }}>
      <div style={{
        width: `${value * 100}%`, height: '100%', borderRadius: height,
        background: color || T.teal,
      }} />
    </div>
  );
}

// ─── Tab Bar (iOS 26 style — glass) ────────────────────────
function TabBar({ active = 'library', onChange = () => {}, dark = false }) {
  const tabs = [
    { id: 'download', label: 'Download', icon: 'arrow-down-circle' },
    { id: 'library',  label: 'Library',  icon: 'books' },
    { id: 'notes',    label: 'Notes',    icon: 'note' },
  ];
  const muted = dark ? T.dInkSoft : T.inkSoft;
  return (
    <div style={{
      position: 'absolute', bottom: 0, left: 0, right: 0,
      paddingBottom: 14, paddingTop: 6,
      display: 'flex', justifyContent: 'space-around',
      background: dark
        ? 'linear-gradient(180deg, rgba(13,13,16,0) 0%, rgba(13,13,16,0.92) 60%)'
        : 'linear-gradient(180deg, rgba(241,236,226,0) 0%, rgba(241,236,226,0.96) 60%)',
      backdropFilter: 'blur(20px)',
    }}>
      {tabs.map((t) => {
        const isActive = active === t.id;
        return (
          <button key={t.id} onClick={() => onChange(t.id)} style={{
            background: 'none', border: 'none', padding: '6px 16px 4px',
            display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 2,
            color: isActive ? T.teal : muted, cursor: 'pointer',
            fontFamily: '-apple-system, system-ui', fontSize: 10, fontWeight: 500,
            letterSpacing: 0.1,
          }}>
            <Icon name={t.icon} size={26} strokeWidth={isActive ? 2 : 1.7} />
            <span>{t.label}</span>
          </button>
        );
      })}
    </div>
  );
}

// ─── Mini Player ───────────────────────────────────────────
function MiniPlayer({ book = BOOKS.habits, playing = false, onTap = () => {}, onPlay = () => {} }) {
  return (
    <div onClick={onTap} style={{
      position: 'absolute', bottom: 64, left: 8, right: 8,
      background: T.ink, borderRadius: 16,
      display: 'flex', alignItems: 'center', gap: 10,
      padding: '8px 10px',
      boxShadow: '0 6px 22px rgba(27, 24, 20, 0.22), 0 1px 0 rgba(255,255,255,0.04) inset',
      cursor: 'pointer', overflow: 'hidden',
    }}>
      <Cover which={book.id} size={42} radius={8} />
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{
          color: '#fff', fontSize: 13, fontWeight: 600, letterSpacing: -0.2,
          whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis',
        }}>{book.title}</div>
        <div style={{
          color: 'rgba(255,255,255,0.55)', fontSize: 11.5,
          whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis',
        }}>{book.author}</div>
      </div>
      <button onClick={(e) => { e.stopPropagation(); onPlay(); }} style={{
        width: 34, height: 34, borderRadius: 17, background: 'rgba(255,255,255,0.12)',
        border: 'none', display: 'flex', alignItems: 'center', justifyContent: 'center',
        color: '#fff', cursor: 'pointer',
      }}>
        <Icon name={playing ? 'pause' : 'play'} size={16} color="#fff" />
      </button>
      {/* hairline progress */}
      <div style={{
        position: 'absolute', bottom: 0, left: 12, right: 12, height: 2, borderRadius: 1,
        background: 'rgba(255,255,255,0.08)',
      }}>
        <div style={{ width: `${book.progress * 100}%`, height: '100%', background: T.teal, borderRadius: 1 }} />
      </div>
    </div>
  );
}

// ─── Sheet shell (modal bottom sheet) ──────────────────────
function Sheet({ title, dark = false, children, height = '70%', leading, trailing, onClose }) {
  const bg = dark ? '#1C1C1F' : '#F5F2EB';
  return (
    <div style={{ position: 'absolute', inset: 0, zIndex: 30 }}>
      {/* scrim */}
      <div style={{ position: 'absolute', inset: 0, background: 'rgba(0,0,0,0.45)' }} />
      {/* sheet */}
      <div style={{
        position: 'absolute', left: 0, right: 0, bottom: 0,
        height, background: bg,
        borderTopLeftRadius: 18, borderTopRightRadius: 18,
        boxShadow: '0 -8px 30px rgba(0,0,0,0.18)',
        overflow: 'hidden',
        display: 'flex', flexDirection: 'column',
      }}>
        {/* grabber */}
        <div style={{ display: 'flex', justifyContent: 'center', paddingTop: 6 }}>
          <div style={{ width: 36, height: 5, borderRadius: 3, background: dark ? 'rgba(255,255,255,0.25)' : 'rgba(0,0,0,0.18)' }} />
        </div>
        {/* title row */}
        {title !== undefined && (
          <div style={{ display: 'flex', alignItems: 'center', padding: '12px 16px 8px' }}>
            <div style={{ width: 60, fontSize: 16, color: dark ? '#fff' : T.ink, opacity: 0.7 }}>{leading}</div>
            <div style={{ flex: 1, textAlign: 'center', fontSize: 16, fontWeight: 600, color: dark ? '#fff' : T.ink, letterSpacing: -0.3 }}>{title}</div>
            <div style={{ width: 60, textAlign: 'right', fontSize: 16, fontWeight: 600, color: T.teal }}>{trailing}</div>
          </div>
        )}
        <div style={{ flex: 1, overflow: 'auto' }}>{children}</div>
      </div>
    </div>
  );
}

// ─── Section header ───────────────────────────────────────
function SectionHeader({ children, dark = false, action }) {
  return (
    <div style={{
      display: 'flex', alignItems: 'center', justifyContent: 'space-between',
      padding: '20px 20px 8px',
    }}>
      <div style={{
        fontSize: 13, fontWeight: 600, letterSpacing: 0.5,
        textTransform: 'uppercase',
        color: dark ? T.dInkSoft : T.inkSoft,
      }}>{children}</div>
      {action}
    </div>
  );
}

Object.assign(window, {
  T, COVERS, BOOKS, Cover, Icon, ProgressBar, TabBar, MiniPlayer, Sheet, SectionHeader,
});
