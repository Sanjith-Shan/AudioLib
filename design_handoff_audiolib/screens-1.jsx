// Onboarding + Download + Library screens

// ─── Onboarding ────────────────────────────────────────────
function OnboardingScreen() {
  return (
    <div style={{
      position: 'absolute', inset: 0,
      background: 'linear-gradient(180deg, #F5F2EB 0%, #E8DFC9 100%)',
      display: 'flex', flexDirection: 'column',
      padding: '120px 32px 56px',
    }}>
      {/* App icon */}
      <div style={{
        width: 112, height: 112, borderRadius: 26, alignSelf: 'center',
        background: 'linear-gradient(160deg, #0F5751 0%, #1E9085 100%)',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        boxShadow: '0 16px 40px rgba(15,87,81,0.32), inset 0 1px 0 rgba(255,255,255,0.2)',
        marginBottom: 32,
      }}>
        {/* Headphones glyph */}
        <svg width="64" height="64" viewBox="0 0 64 64" fill="none">
          <path d="M12 36 V32 a20 20 0 0 1 40 0 V36" stroke="#F4ECDB" strokeWidth="3.5" strokeLinecap="round"/>
          <rect x="8" y="36" width="12" height="18" rx="4" fill="#F4ECDB"/>
          <rect x="44" y="36" width="12" height="18" rx="4" fill="#F4ECDB"/>
        </svg>
      </div>

      <div style={{
        fontFamily: 'Georgia, "Iowan Old Style", serif',
        fontSize: 40, fontWeight: 700, color: T.ink,
        letterSpacing: -0.8, textAlign: 'center', marginBottom: 10,
        lineHeight: 1.05,
      }}>AudioLib</div>

      <div style={{
        fontSize: 17, color: T.inkSoft, textAlign: 'center',
        lineHeight: 1.4, maxWidth: 280, alignSelf: 'center',
        marginBottom: 'auto',
      }}>Turn any YouTube link into an audiobook you actually own.</div>

      {/* Feature highlights */}
      <div style={{ display: 'flex', flexDirection: 'column', gap: 18, marginBottom: 36 }}>
        {[
          { icon: 'arrow-down-circle', t: 'Download from YouTube', s: 'Paste a link, get an audiobook.' },
          { icon: 'books', t: 'A real library', s: 'Continue listening, sorted your way.' },
          { icon: 'note', t: 'Take notes with timestamps', s: 'Bookmark thoughts as you listen.' },
        ].map((f) => (
          <div key={f.t} style={{ display: 'flex', alignItems: 'center', gap: 14 }}>
            <div style={{
              width: 36, height: 36, borderRadius: 10,
              background: T.tealSoft, color: T.tealInk,
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              flexShrink: 0,
            }}>
              <Icon name={f.icon} size={20} color={T.tealInk} strokeWidth={1.9} />
            </div>
            <div style={{ flex: 1 }}>
              <div style={{ fontSize: 15, fontWeight: 600, color: T.ink, letterSpacing: -0.2 }}>{f.t}</div>
              <div style={{ fontSize: 13, color: T.inkSoft, marginTop: 1 }}>{f.s}</div>
            </div>
          </div>
        ))}
      </div>

      <button style={{
        background: T.ink, color: '#F4ECDB',
        height: 52, borderRadius: 16, border: 'none',
        fontSize: 17, fontWeight: 600, letterSpacing: -0.2,
        cursor: 'pointer',
        boxShadow: '0 4px 16px rgba(27,24,20,0.22)',
      }}>Get Started</button>

      <div style={{
        fontSize: 12, color: T.inkMute, textAlign: 'center', marginTop: 12,
      }}>We'll ask for notifications next so we can tell you when downloads finish.</div>
    </div>
  );
}

// ─── Download Tab ──────────────────────────────────────────
function DownloadCard({ url, setUrl, downloading }) {
  return (
    <div style={{
      margin: '0 16px', padding: '18px 18px 16px',
      background: T.ink, color: '#F4ECDB',
      borderRadius: 20,
      boxShadow: '0 6px 24px rgba(27,24,20,0.18)',
    }}>
      <div style={{
        fontSize: 11, fontWeight: 700, letterSpacing: 0.8,
        textTransform: 'uppercase', color: 'rgba(244,236,219,0.55)',
        marginBottom: 6,
      }}>Add Audiobook</div>
      <div style={{ fontSize: 22, fontWeight: 700, letterSpacing: -0.4, marginBottom: 14 }}>
        Paste a YouTube link
      </div>

      <div style={{
        background: 'rgba(255,255,255,0.08)', borderRadius: 12,
        padding: '12px 14px', display: 'flex', alignItems: 'center', gap: 8,
        border: '0.5px solid rgba(255,255,255,0.1)',
      }}>
        <Icon name="link" size={16} color="rgba(244,236,219,0.5)" />
        <div style={{
          flex: 1, fontSize: 14.5, color: url ? '#F4ECDB' : 'rgba(244,236,219,0.35)',
          fontFamily: 'ui-monospace, SF Mono, monospace',
          whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis',
        }}>{url || 'youtube.com/watch?v=…'}</div>
      </div>

      <button disabled={!url} style={{
        marginTop: 12, width: '100%', height: 46, border: 'none',
        borderRadius: 12, fontSize: 16, fontWeight: 600, letterSpacing: -0.2,
        background: url ? '#F4ECDB' : 'rgba(244,236,219,0.18)',
        color: url ? T.ink : 'rgba(244,236,219,0.5)',
        cursor: url ? 'pointer' : 'default',
        display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8,
      }}>
        {downloading ? (
          <>
            <div style={{ width: 14, height: 14, borderRadius: 7, border: '2px solid rgba(27,24,20,0.2)', borderTopColor: T.ink, animation: 'spin 0.8s linear infinite' }} />
            Downloading…
          </>
        ) : 'Download'}
      </button>
    </div>
  );
}

function DownloadRow({ title, state, pct, speed, eta, sizeText, error, canStream, source }) {
  const stateColor = error ? T.red : state === 'Done' ? T.teal : T.ink;
  return (
    <div style={{
      background: T.card, borderRadius: 16, padding: 14,
      marginBottom: 10, position: 'relative',
      boxShadow: '0 1px 0 rgba(27,24,20,0.04)',
    }}>
      <div style={{ display: 'flex', alignItems: 'flex-start', gap: 12 }}>
        {/* Spinner / icon */}
        <div style={{
          width: 36, height: 36, borderRadius: 10, flexShrink: 0,
          background: error ? 'rgba(200,68,58,0.1)' : state === 'Done' ? T.tealSoft : T.cardSoft,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          color: stateColor,
        }}>
          {error ? <Icon name="wifi-x" size={18} color={T.red} /> :
            state === 'Done' ? <Icon name="check-fill" size={20} color={T.teal} /> :
              <Icon name="arrow-down-circle" size={18} color={T.ink} />}
        </div>
        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{
            fontSize: 15, fontWeight: 600, color: T.ink, letterSpacing: -0.2,
            whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis',
            paddingRight: 24,
          }}>{title}</div>
          <div style={{ fontSize: 12, color: stateColor, marginTop: 2, fontWeight: 500 }}>
            {state}{source && <span style={{ color: T.inkMute, fontWeight: 400 }}> · {source}</span>}
          </div>
        </div>
        {/* Cancel */}
        <button style={{
          position: 'absolute', top: 12, right: 12,
          width: 24, height: 24, borderRadius: 12,
          background: T.inkFaint, border: 'none', cursor: 'pointer',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          color: T.inkSoft,
        }}>
          <Icon name="x" size={12} color={T.inkSoft} strokeWidth={2.4} />
        </button>
      </div>

      {pct !== undefined && !error && (
        <>
          <div style={{ marginTop: 12, marginBottom: 8 }}>
            <ProgressBar value={pct / 100} height={4} color={state === 'Done' ? T.teal : T.ink} />
          </div>
          <div style={{
            display: 'flex', justifyContent: 'space-between', alignItems: 'center',
            fontSize: 11.5, color: T.inkSoft,
            fontVariantNumeric: 'tabular-nums',
          }}>
            <span>{sizeText}</span>
            <span>{speed ? `${speed} · ${eta}` : eta}</span>
          </div>
        </>
      )}

      {error && (
        <div style={{
          marginTop: 10, padding: '8px 10px',
          background: 'rgba(200,68,58,0.08)', borderRadius: 8,
          fontSize: 12.5, color: T.red, lineHeight: 1.35,
        }}>{error}</div>
      )}

      {canStream && state !== 'Done' && !error && (
        <button style={{
          marginTop: 10, padding: '7px 12px', borderRadius: 10,
          background: T.tealSoft, color: T.tealInk,
          border: 'none', cursor: 'pointer',
          fontSize: 12.5, fontWeight: 600, letterSpacing: -0.1,
          display: 'inline-flex', alignItems: 'center', gap: 6,
        }}>
          <Icon name="play" size={11} color={T.tealInk} />
          Tap to listen
        </button>
      )}
    </div>
  );
}

function DownloadScreen({ populated = true }) {
  return (
    <div style={{
      position: 'absolute', inset: 0, background: T.bg,
      paddingTop: 54,
      display: 'flex', flexDirection: 'column',
    }}>
      {/* Nav */}
      <div style={{
        padding: '8px 16px 4px', display: 'flex', alignItems: 'center', justifyContent: 'space-between',
      }}>
        <div style={{
          fontFamily: 'Georgia, serif', fontSize: 28, fontWeight: 700,
          color: T.ink, letterSpacing: -0.5,
        }}>Download</div>
        <button style={{
          width: 36, height: 36, borderRadius: 18, border: 'none', cursor: 'pointer',
          background: 'rgba(255,255,255,0.6)', backdropFilter: 'blur(20px)',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          color: T.ink,
        }}>
          <Icon name="gear" size={18} color={T.ink} />
        </button>
      </div>

      <div style={{ overflowY: 'auto', flex: 1, paddingBottom: 140 }}>
        <div style={{ paddingTop: 8 }}>
          <DownloadCard url={populated ? 'youtube.com/watch?v=dQw4w9WgXcQ' : ''} />
        </div>

        {populated ? (
          <>
            <SectionHeader>Active</SectionHeader>
            <div style={{ padding: '0 16px' }}>
              <DownloadRow
                title="Brandon Sanderson — Words of Radiance (Full)"
                state="Downloading 64%"
                pct={64}
                speed="2.4 MB/s"
                eta="~3 min left"
                sizeText="Downloaded 184 MB of 287 MB"
                canStream
                source="m4a"
              />
              <DownloadRow
                title="The Midnight Library — Matt Haig — Audiobook"
                state="Mac downloading…"
                pct={28}
                speed="—"
                eta="~7 min left"
                sizeText="Downloaded 41 MB of 146 MB"
                source="Companion"
              />
              <DownloadRow
                title="dQw4w9WgXcQ"
                state="Fetching info…"
                pct={0}
                sizeText="Resolving title…"
                eta=""
              />
              <DownloadRow
                title="The Power Broker — Pt. 1"
                state="Failed"
                error="Could not reach YouTube after 30s. Check your connection and try again."
              />
              <DownloadRow
                title="Atomic Habits — James Clear — Audiobook"
                state="Done"
                pct={100}
                sizeText="142 MB"
                eta="Just added"
              />
            </div>
          </>
        ) : (
          // Empty state
          <div style={{
            display: 'flex', flexDirection: 'column', alignItems: 'center',
            padding: '64px 32px 24px', textAlign: 'center',
          }}>
            <div style={{
              width: 72, height: 72, borderRadius: 22,
              background: T.cardSoft, display: 'flex', alignItems: 'center', justifyContent: 'center',
              marginBottom: 18,
            }}>
              <Icon name="arrow-down-circle" size={36} color={T.inkMute} strokeWidth={1.5} />
            </div>
            <div style={{ fontSize: 17, fontWeight: 600, color: T.ink, letterSpacing: -0.3 }}>No Active Downloads</div>
            <div style={{ fontSize: 14, color: T.inkSoft, marginTop: 6, maxWidth: 240, lineHeight: 1.4 }}>
              Paste a YouTube link above to get started.
            </div>
          </div>
        )}
      </div>

      <TabBar active="download" />
    </div>
  );
}

// ─── Library Tab ───────────────────────────────────────────
function ContinueListening({ book }) {
  return (
    <div style={{
      margin: '4px 16px 18px', padding: 16, borderRadius: 20,
      background: 'linear-gradient(135deg, #11332E 0%, #1B5751 100%)',
      color: '#F4ECDB', position: 'relative', overflow: 'hidden',
      boxShadow: '0 8px 24px rgba(17,51,46,0.22)',
    }}>
      <div style={{ display: 'flex', gap: 14, alignItems: 'center' }}>
        <Cover which={book.id} size={84} radius={10} />
        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{
            fontSize: 10, fontWeight: 700, letterSpacing: 1.2,
            textTransform: 'uppercase', color: 'rgba(244,236,219,0.55)', marginBottom: 4,
          }}>Continue listening</div>
          <div style={{
            fontSize: 17, fontWeight: 700, letterSpacing: -0.3, lineHeight: 1.15,
            whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis',
          }}>{book.title}</div>
          <div style={{
            fontSize: 13, color: 'rgba(244,236,219,0.7)', marginTop: 2,
            whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis',
          }}>{book.author}</div>
          <div style={{
            display: 'flex', alignItems: 'center', gap: 8,
            marginTop: 12,
          }}>
            <div style={{ flex: 1 }}>
              <ProgressBar value={book.progress} height={3} color="#F4ECDB" track="rgba(244,236,219,0.18)" />
              <div style={{ fontSize: 11, color: 'rgba(244,236,219,0.6)', marginTop: 4, fontVariantNumeric: 'tabular-nums' }}>
                {book.remain} left
              </div>
            </div>
            <button style={{
              width: 44, height: 44, borderRadius: 22, border: 'none', cursor: 'pointer',
              background: '#F4ECDB', display: 'flex', alignItems: 'center', justifyContent: 'center',
              flexShrink: 0,
              boxShadow: '0 2px 6px rgba(0,0,0,0.18)',
            }}>
              <Icon name="play" size={18} color={T.ink} />
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}

function LibraryRow({ book }) {
  return (
    <div style={{
      display: 'flex', alignItems: 'center', gap: 12,
      padding: '10px 16px',
    }}>
      <Cover which={book.id} size={64} radius={8} />
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{
          fontSize: 15, fontWeight: 600, color: T.ink, letterSpacing: -0.2,
          whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis',
        }}>{book.title}</div>
        <div style={{
          fontSize: 13, color: T.inkSoft, marginTop: 1,
          whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis',
        }}>{book.author}</div>
        {book.series && (
          <div style={{ fontSize: 11.5, color: T.tealInk, fontWeight: 600, marginTop: 2 }}>
            {book.series.name} #{book.series.n}
          </div>
        )}
        <div style={{ marginTop: 6, display: 'flex', alignItems: 'center', gap: 8 }}>
          <div style={{ flex: 1 }}>
            <ProgressBar value={book.progress} height={2.5} color={book.progress === 1 ? T.teal : T.ink} />
          </div>
          <div style={{ fontSize: 11, color: T.inkMute, fontVariantNumeric: 'tabular-nums', minWidth: 56, textAlign: 'right' }}>
            {book.progress === 1 ? 'Finished' : book.progress === 0 ? 'New' : book.remain + ' left'}
          </div>
        </div>
      </div>
      <button style={{
        width: 38, height: 38, borderRadius: 19, border: 'none', cursor: 'pointer',
        background: T.cardSoft, display: 'flex', alignItems: 'center', justifyContent: 'center',
        flexShrink: 0,
      }}>
        <Icon name="play" size={14} color={T.ink} />
      </button>
    </div>
  );
}

function LibraryScreen({ withMiniPlayer = true, empty = false }) {
  const books = [BOOKS.sapiens, BOOKS.hailmary, BOOKS.dune, BOOKS.threebody, BOOKS.gatsby, BOOKS.educated];
  return (
    <div style={{
      position: 'absolute', inset: 0, background: T.bg,
      paddingTop: 54,
      display: 'flex', flexDirection: 'column',
    }}>
      {/* Nav */}
      <div style={{
        padding: '8px 16px 4px', display: 'flex', alignItems: 'center', justifyContent: 'space-between',
      }}>
        <div style={{
          fontFamily: 'Georgia, serif', fontSize: 28, fontWeight: 700,
          color: T.ink, letterSpacing: -0.5,
        }}>Library</div>
        <div style={{ display: 'flex', gap: 8 }}>
          <button style={{
            width: 36, height: 36, borderRadius: 18, border: 'none', cursor: 'pointer',
            background: 'rgba(255,255,255,0.6)', backdropFilter: 'blur(20px)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
          }}>
            <Icon name="sort" size={18} color={T.ink} />
          </button>
          <button style={{
            width: 36, height: 36, borderRadius: 18, border: 'none', cursor: 'pointer',
            background: 'rgba(255,255,255,0.6)', backdropFilter: 'blur(20px)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
          }}>
            <Icon name="gear" size={18} color={T.ink} />
          </button>
        </div>
      </div>

      {/* Search */}
      {!empty && (
        <div style={{ padding: '10px 16px 8px' }}>
          <div style={{
            display: 'flex', alignItems: 'center', gap: 8,
            background: 'rgba(255,255,255,0.7)', borderRadius: 12,
            padding: '10px 12px',
          }}>
            <Icon name="search" size={16} color={T.inkSoft} />
            <span style={{ flex: 1, fontSize: 14.5, color: T.inkMute }}>Search title or author</span>
          </div>
        </div>
      )}

      <div style={{ overflowY: 'auto', flex: 1, paddingBottom: withMiniPlayer ? 168 : 110 }}>
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
              <Icon name="books" size={40} color={T.inkMute} strokeWidth={1.5} />
            </div>
            <div style={{ fontSize: 19, fontWeight: 700, color: T.ink, letterSpacing: -0.3, fontFamily: 'Georgia, serif' }}>Your Library</div>
            <div style={{ fontSize: 14, color: T.inkSoft, marginTop: 6, maxWidth: 260, lineHeight: 1.4 }}>
              Downloaded audiobooks will appear here.
            </div>
            <button style={{
              marginTop: 22, padding: '12px 22px', borderRadius: 14, border: 'none',
              background: T.ink, color: '#F4ECDB', fontSize: 15, fontWeight: 600,
              cursor: 'pointer', letterSpacing: -0.2,
            }}>Download one</button>
          </div>
        ) : (
          <>
            <ContinueListening book={BOOKS.habits} />
            <SectionHeader>All books · 7</SectionHeader>
            <div style={{ margin: '0 16px', background: T.card, borderRadius: 18, overflow: 'hidden' }}>
              {books.map((b, i) => (
                <React.Fragment key={b.id}>
                  <LibraryRow book={b} />
                  {i < books.length - 1 && <div style={{ height: 0.5, background: T.hair, marginLeft: 92 }} />}
                </React.Fragment>
              ))}
            </div>
          </>
        )}
      </div>

      {withMiniPlayer && !empty && <MiniPlayer book={BOOKS.habits} playing />}
      <TabBar active="library" />
    </div>
  );
}

Object.assign(window, { OnboardingScreen, DownloadScreen, LibraryScreen, DownloadRow, LibraryRow, ContinueListening });
