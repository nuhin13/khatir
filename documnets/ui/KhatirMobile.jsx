import React, { useState } from "react";

// ═══════════════════════════════════════════════════════════════
//   Khatir · খাতির
//   বাড়িওয়ালার ডিজিটাল খাতা · The landlord's digital ledger
//   Aesthetic: Notun Din (নতুন দিন · New Day)
//   Final v1.0 — production-ready reference UI
// ═══════════════════════════════════════════════════════════════

// ─── DESIGN TOKENS ─────────────────────────────────────────────
const C = {
  // primary palette
  ink:      "#2C3530",
  sage:     "#7BA084",
  sageDk:   "#5C8067",
  sageBg:   "#E8F0EA",
  rose:     "#E89B8B",
  roseDk:   "#C9755F",
  roseBg:   "#FBE9E3",
  butter:   "#F4D58D",
  butterDk: "#D9B45F",
  butterBg: "#FBF1D8",
  // neutrals
  cream:    "#FBF6EE",
  card:     "#FFFFFF",
  line:     "#EFE6D8",
  lineDk:   "#E0D5C2",
  muted:    "#8C8578",
  mutedDk:  "#6B6558",
};

const F_BODY    = `'Hind Siliguri','Noto Sans Bengali',-apple-system,sans-serif`;
const F_HAND    = `'Caveat','Hind Siliguri',cursive`;
const F_TITLE   = `'Plus Jakarta Sans','Hind Siliguri',sans-serif`;

// ─── ICONS ──────────────────────────────────────────────────────
const I = {
  back:   <path d="M15 18l-6-6 6-6"/>,
  doc:    <><path d="M14 3H6a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V9Z"/><path d="M14 3v6h6"/></>,
  shield: <><path d="M12 3l8 3v6c0 5-3.5 7.5-8 9-4.5-1.5-8-4-8-9V6Z"/><path d="M9 12l2 2 4-4"/></>,
  cam:    <><path d="M3 8a2 2 0 0 1 2-2h2l1.5-2h7L19 6h0a2 2 0 0 1 2 2v9a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2Z"/><circle cx="12" cy="13" r="3.5"/></>,
  mic:    <><rect x="9" y="3" width="6" height="11" rx="3"/><path d="M5 11a7 7 0 0 0 14 0M12 18v3"/></>,
  send:   <><path d="M22 2 11 13M22 2l-7 20-4-9-9-4Z"/></>,
  wa:     <path d="M12 3a9 9 0 0 0-7.7 13.6L3 21l4.6-1.2A9 9 0 1 0 12 3Z"/>,
  arrow:  <path d="M5 12h14M13 5l7 7-7 7"/>,
  heart:  <path d="M20.8 4.6a5.5 5.5 0 0 0-7.8 0L12 5.7l-1-1.1a5.5 5.5 0 0 0-7.8 7.8L12 21l8.8-8.6a5.5 5.5 0 0 0 0-7.8Z"/>,
  home:   <path d="M3 10.5 12 3l9 7.5V21h-6v-6h-6v6H3Z"/>,
  user:   <><circle cx="12" cy="8" r="4"/><path d="M4 21a8 8 0 0 1 16 0"/></>,
  chart:  <><path d="M4 19V5M4 19h16"/><rect x="7" y="11" width="3" height="6"/><rect x="12" y="8" width="3" height="9"/><rect x="17" y="13" width="3" height="4"/></>,
  bell:   <><path d="M6 8a6 6 0 0 1 12 0c0 7 3 9 3 9H3s3-2 3-9"/><path d="M10 21a2 2 0 0 0 4 0"/></>,
  more:   <><circle cx="12" cy="5" r="1.5"/><circle cx="12" cy="12" r="1.5"/><circle cx="12" cy="19" r="1.5"/></>,
  check:  <path d="M20 6 9 17l-5-5"/>,
  plus:   <path d="M12 5v14M5 12h14"/>,
  cash:   <><rect x="2" y="6" width="20" height="12" rx="2"/><circle cx="12" cy="12" r="3"/></>,
  pin:    <><path d="M12 22s8-7.6 8-13a8 8 0 0 0-16 0c0 5.4 8 13 8 13Z"/><circle cx="12" cy="9" r="2.5"/></>,
};
const Icon = ({ d, s = 22, c = "currentColor", sw = 1.8 }) => (
  <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth={sw} strokeLinecap="round" strokeLinejoin="round">{d}</svg>
);

// ─── PRIMITIVES ─────────────────────────────────────────────────
const Phone = ({ children }) => (
  <div style={{
    minHeight: "100vh",
    background: "linear-gradient(135deg, #d4c4a8 0%, #a89682 50%, #8a7563 100%)",
    display: "flex", alignItems: "center", justifyContent: "center",
    padding: "24px 12px", fontFamily: F_BODY,
  }}>
    <div style={{
      width: 390, height: 820, maxWidth: "100%", maxHeight: "94vh",
      background: C.cream, borderRadius: 44, overflow: "hidden", position: "relative",
      boxShadow: "0 50px 100px -20px rgba(60,40,30,.55), 0 0 0 10px #2a201a, 0 0 0 11px #5a4838",
      display: "flex", flexDirection: "column",
    }}>{children}</div>
  </div>
);

const TopBar = ({ title, onBack, action, transparent }) => (
  <div style={{
    padding: "16px 20px 10px", display: "flex", alignItems: "center", gap: 12,
    background: transparent ? "transparent" : C.cream, flexShrink: 0,
  }}>
    {onBack && (
      <button onClick={onBack} style={{
        background: C.card, border: `1px solid ${C.line}`, color: C.ink,
        width: 40, height: 40, borderRadius: 20, display: "grid", placeItems: "center",
        cursor: "pointer", boxShadow: "0 2px 6px -2px rgba(0,0,0,.06)", padding: 0,
      }}><Icon d={I.back} s={20}/></button>
    )}
    {!onBack ? (
      <div style={{ display: "flex", alignItems: "center", gap: 9 }}>
        <div style={{
          width: 34, height: 34, borderRadius: 11,
          background: `linear-gradient(135deg, ${C.sage}, ${C.sageDk})`,
          display: "grid", placeItems: "center", boxShadow: `0 4px 10px -3px ${C.sageDk}`,
        }}>
          <span style={{ color: "#fff", fontFamily: F_BODY, fontSize: 24, fontWeight: 700, lineHeight: 1, marginTop: -3 }}>খ</span>
        </div>
        <div>
          <div style={{ fontFamily: F_TITLE, fontSize: 18, fontWeight: 800, color: C.ink, letterSpacing: -.5, lineHeight: 1 }}>
            Khatir <span style={{ color: C.sageDk, fontWeight: 700 }}>খাতির</span>
          </div>
          <div style={{ fontSize: 9.5, color: C.muted, marginTop: 2, letterSpacing: .3 }}>বাড়িওয়ালার ডিজিটাল খাতা</div>
        </div>
      </div>
    ) : (
      <div style={{ fontFamily: F_TITLE, fontWeight: 800, fontSize: 18, color: C.ink, flex: 1, letterSpacing: -.3 }}>{title}</div>
    )}
    {action}
  </div>
);

const Scroll = ({ children, style }) => (
  <div style={{ flex: 1, overflowY: "auto", overflowX: "hidden", ...style }}>{children}</div>
);

const Card = ({ children, style, onClick, soft }) => (
  <div onClick={onClick} style={{
    background: soft || C.card,
    borderRadius: 22, padding: 16,
    border: `1px solid ${soft ? "transparent" : C.line}`,
    boxShadow: soft ? "none" : "0 3px 12px -6px rgba(80,60,40,.1)",
    cursor: onClick ? "pointer" : "default",
    transition: "transform .15s",
    ...style,
  }}>{children}</div>
);

const Btn = ({ children, kind = "primary", onClick, full, style, size = "md" }) => {
  const variants = {
    primary: { background: C.sage, color: "#fff", boxShadow: `0 8px 20px -8px rgba(123,160,132,.55)` },
    rose:    { background: C.rose, color: "#fff", boxShadow: `0 8px 20px -8px rgba(232,155,139,.55)` },
    butter:  { background: C.butter, color: C.ink, boxShadow: `0 8px 20px -8px rgba(244,213,141,.6)` },
    ghost:   { background: "transparent", color: C.sageDk, border: `2px solid ${C.sage}`, boxShadow: "none" },
    soft:    { background: C.sageBg, color: C.sageDk, boxShadow: "none" },
    dark:    { background: C.ink, color: "#fff", boxShadow: `0 8px 20px -8px rgba(44,53,48,.5)` },
  };
  const sizes = {
    sm: { padding: "10px 16px", fontSize: 13 },
    md: { padding: "15px 22px", fontSize: 15 },
    lg: { padding: "17px 24px", fontSize: 16 },
  };
  return (
    <button onClick={onClick} style={{
      ...variants[kind], ...sizes[size],
      border: variants[kind].border || 0,
      borderRadius: 999, fontFamily: F_TITLE, fontWeight: 700,
      cursor: "pointer", width: full ? "100%" : "auto",
      letterSpacing: .1, transition: "transform .1s", ...style,
    }}>{children}</button>
  );
};

const Chip = ({ children, bg = C.sageBg, fg = C.sageDk, style }) => (
  <span style={{
    background: bg, color: fg, fontSize: 11.5, fontWeight: 700,
    padding: "5px 12px", borderRadius: 999, display: "inline-block",
    ...style,
  }}>{children}</span>
);

// ─── INTRO ─────────────────────────────────────────────────────
const SLIDES = [
  { illo: "🏠", color: C.sageBg, accent: C.sage, accentDk: C.sageDk,
    kicker: "স্বাগতম", title: "বাড়িওয়ালার ডিজিটাল খাতা",
    body: "কাগজের ঝামেলা শেষ। ভাড়াটিয়ার তথ্য, ভাড়ার হিসাব, খরচ — সব এক জায়গায়।" },
  { illo: "⚡", color: C.butterBg, accent: C.butter, accentDk: C.butterDk,
    kicker: "প্রধান সুবিধা", title: "পুলিশ ফর্ম, ২ মিনিটে!",
    body: "থানায় দৌড়ানো বন্ধ। NID-এর ছবি তুলুন, ফর্ম নিজে থেকেই পূরণ হবে।" },
  { illo: "🎁", color: C.roseBg, accent: C.rose, accentDk: C.roseDk,
    kicker: "একদম ফ্রি!", title: "প্রথম ২ ভাড়াটিয়া ফ্রি",
    body: "কোনো খরচ ছাড়াই পুরো ব্যবস্থা ব্যবহার করুন। NID যাচাই ছাড়া সব ফিচার।" },
];

const Intro = ({ go }) => {
  const [i, setI] = useState(0);
  const s = SLIDES[i];
  return (
    <>
      <div style={{ padding: "20px 22px 6px", display: "flex", justifyContent: "space-between", alignItems: "center" }}>
        <div style={{ display: "flex", gap: 6 }}>
          {SLIDES.map((_, k) => (
            <div key={k} style={{
              width: k === i ? 28 : 8, height: 8,
              background: k === i ? s.accentDk : C.line,
              borderRadius: 4, transition: "all .3s",
            }}/>
          ))}
        </div>
        <button onClick={() => go("login")} style={{
          background: "transparent", border: 0, color: C.muted,
          fontSize: 13, fontWeight: 600, cursor: "pointer",
        }}>এড়িয়ে যান</button>
      </div>
      <Scroll>
        <div style={{ padding: "26px 28px 20px", textAlign: "center" }}>
          {/* hero illo */}
          <div style={{ position: "relative", width: 220, height: 220, margin: "10px auto 30px" }}>
            <div style={{
              width: 220, height: 220, background: s.color, borderRadius: 110,
              display: "grid", placeItems: "center", fontSize: 110, position: "relative",
              boxShadow: `0 30px 60px -25px ${s.accent}`, transition: "all .4s",
            }}>
              <span style={{ filter: "drop-shadow(0 4px 12px rgba(0,0,0,.12))" }}>{s.illo}</span>
              {/* decorative floating dots */}
              <div style={{ position: "absolute", top: 22, right: 18, width: 22, height: 22, borderRadius: 11, background: s.accent, opacity: .8 }}/>
              <div style={{ position: "absolute", bottom: 30, left: 12, width: 14, height: 14, borderRadius: 7, background: s.accent, opacity: .55 }}/>
              <div style={{ position: "absolute", top: 50, left: -8, width: 10, height: 10, borderRadius: 5, background: s.accent, opacity: .7 }}/>
              <div style={{ position: "absolute", bottom: 14, right: 4, width: 8, height: 8, borderRadius: 4, background: s.accent, opacity: .5 }}/>
            </div>
          </div>
          <Chip bg={s.color} fg={s.accentDk}>{s.kicker}</Chip>
          <div style={{ fontFamily: F_BODY, fontSize: 22, fontWeight: 800, color: s.accentDk, marginTop: 10, lineHeight: 1 }}>খাতির</div>
          <div style={{ fontFamily: F_TITLE, fontSize: 28, fontWeight: 800, color: C.ink, lineHeight: 1.2, letterSpacing: -.6, marginTop: 6 }}>{s.title}</div>
          <div style={{ fontSize: 15.5, color: C.mutedDk, lineHeight: 1.65, marginTop: 14, maxWidth: 290, margin: "14px auto 0" }}>{s.body}</div>
        </div>
      </Scroll>
      <div style={{ padding: "14px 22px 24px", flexShrink: 0 }}>
        {i < SLIDES.length - 1 ? (
          <Btn full size="lg" onClick={() => setI(i + 1)} style={{ background: s.accent, color: s.accent === C.butter ? C.ink : "#fff" }}>
            পরবর্তী →
          </Btn>
        ) : (
          <Btn full size="lg" onClick={() => go("login")}>শুরু করি! 🎉</Btn>
        )}
      </div>
    </>
  );
};

// ─── LOGIN ─────────────────────────────────────────────────────
const Login = ({ go }) => (
  <>
    <TopBar transparent/>
    <Scroll>
      <div style={{ padding: "20px 24px 4px", textAlign: "center" }}>
        <div style={{ fontSize: 80, marginTop: 8 }}>👋</div>
        <div style={{ fontFamily: F_HAND, fontSize: 42, color: C.sageDk, lineHeight: 1, marginTop: 4 }}>Hello!</div>
        <div style={{ fontFamily: F_TITLE, fontSize: 24, fontWeight: 800, color: C.ink, lineHeight: 1.1, letterSpacing: -.5, marginTop: 6 }}>স্বাগতম, বাড়িওয়ালা</div>
        <div style={{ color: C.muted, marginTop: 8, fontSize: 14 }}>মোবাইল নম্বর দিয়ে শুরু করুন</div>
      </div>
      <div style={{ padding: "18px 22px" }}>
        <Card style={{ padding: "14px 16px" }}>
          <div style={{ fontSize: 11.5, fontWeight: 700, color: C.muted, marginBottom: 8, letterSpacing: .3, textTransform: "uppercase" }}>মোবাইল নম্বর</div>
          <div style={{ display: "flex", alignItems: "center", gap: 0 }}>
            <span style={{ fontWeight: 700, color: C.sageDk, fontSize: 17 }}>🇧🇩 +88</span>
            <div style={{ width: 1, height: 26, background: C.line, margin: "0 12px" }}/>
            <input
              defaultValue="01711-000111"
              style={{
                border: 0, outline: "none", flex: 1, fontSize: 18,
                fontFamily: F_TITLE, background: "transparent", color: C.ink,
                fontWeight: 700, padding: "4px 0", letterSpacing: .3,
              }}
            />
          </div>
        </Card>
        <div style={{ marginTop: 16 }}>
          <Btn full size="lg" onClick={() => go("home")}>
            <span style={{ display: "inline-flex", alignItems: "center", gap: 8 }}>OTP পাঠান <Icon d={I.arrow} s={18}/></span>
          </Btn>
        </div>
        <div style={{ marginTop: 12, padding: "12px 14px", background: C.sageBg, borderRadius: 16, display: "flex", gap: 10, alignItems: "center" }}>
          <Icon d={I.wa} s={20} c={C.sageDk}/>
          <div style={{ fontSize: 13, color: C.sageDk, fontWeight: 600 }}>WhatsApp-এ কোড পাবেন · দ্রুত</div>
        </div>
      </div>

      {/* testimonial */}
      <div style={{ padding: "16px 22px 24px" }}>
        <Card soft={C.butterBg} style={{ padding: "16px 18px" }}>
          <div style={{ display: "flex", gap: 4, marginBottom: 6 }}>
            {[1,2,3,4,5].map(i => <span key={i} style={{ color: C.roseDk, fontSize: 14 }}>★</span>)}
          </div>
          <div style={{ fontFamily: F_TITLE, fontSize: 14.5, color: C.ink, lineHeight: 1.55, fontWeight: 600 }}>
            "পুলিশ ফর্ম এখন ২ মিনিটে শেষ। অনেক উপকার হয়েছে!"
          </div>
          <div style={{ marginTop: 10, display: "flex", alignItems: "center", gap: 8 }}>
            <div style={{
              width: 30, height: 30, borderRadius: 15, background: C.rose,
              color: "#fff", display: "grid", placeItems: "center", fontSize: 14, fontWeight: 800,
            }}>I</div>
            <div style={{ fontSize: 12, color: C.mutedDk }}>
              <b style={{ color: C.ink }}>Md. Ibrahim</b> · উত্তরা
            </div>
          </div>
        </Card>
      </div>
    </Scroll>
  </>
);

// ─── HOME ──────────────────────────────────────────────────────
const Home = ({ go }) => (
  <>
    <TopBar action={
      <div style={{ display: "flex", gap: 8 }}>
        <button style={{ background: C.card, border: `1px solid ${C.line}`, width: 40, height: 40, borderRadius: 20, display: "grid", placeItems: "center", cursor: "pointer", position: "relative" }}>
          <Icon d={I.bell} s={18} c={C.ink}/>
          <div style={{ position: "absolute", top: 8, right: 9, width: 8, height: 8, borderRadius: 4, background: C.rose, border: "1.5px solid #fff" }}/>
        </button>
      </div>
    }/>
    <Scroll>
      {/* greeting */}
      <div style={{ padding: "4px 22px 12px" }}>
        <div style={{ fontFamily: F_HAND, fontSize: 26, color: C.sageDk, lineHeight: 1 }}>আসসালামু আলাইকুম,</div>
        <div style={{ display: "flex", alignItems: "center", gap: 8, marginTop: 4 }}>
          <div style={{ fontFamily: F_TITLE, fontSize: 24, fontWeight: 800, color: C.ink, letterSpacing: -.5, lineHeight: 1.1 }}>করিম সাহেব</div>
          <span style={{ fontSize: 20 }}>👋</span>
        </div>
        <div style={{ color: C.muted, fontSize: 12.5, marginTop: 4 }}>আজ ১৫ মে · বৃহস্পতিবার · ২ বিল্ডিং · ১৪ ইউনিট</div>
      </div>

      {/* DMP form hero */}
      <div style={{ padding: "4px 20px 0" }}>
        <Card
          onClick={() => go("addTenant")}
          soft={`linear-gradient(135deg, ${C.sage} 0%, ${C.sageDk} 100%)`}
          style={{
            color: "#fff", padding: "22px 22px 24px",
            position: "relative", overflow: "hidden", borderRadius: 26,
            boxShadow: `0 20px 40px -16px ${C.sageDk}`,
          }}
        >
          <Chip bg="rgba(255,255,255,.22)" fg="#fff">⭐ সুপারিশ · FLAGSHIP</Chip>
          <div style={{ fontFamily: F_TITLE, fontSize: 24, fontWeight: 800, marginTop: 12, lineHeight: 1.15, letterSpacing: -.5 }}>
            পুলিশ ফর্ম,<br/>মাত্র ২ মিনিটে!
          </div>
          <div style={{ fontSize: 13.5, opacity: .92, marginTop: 8, lineHeight: 1.5, maxWidth: 250 }}>
            NID-এর ছবি তুলুন, বাকিটা আমরা করব ✨
          </div>
          <div style={{
            marginTop: 16, display: "inline-flex", alignItems: "center", gap: 8,
            background: "rgba(255,255,255,.22)", padding: "9px 16px", borderRadius: 999,
            fontSize: 13.5, fontWeight: 700,
          }}>শুরু করি <Icon d={I.arrow} s={16}/></div>
          <div style={{
            position: "absolute", right: -12, top: -16, fontSize: 130,
            opacity: .13, lineHeight: 1, transform: "rotate(-8deg)",
          }}>📄</div>
        </Card>
      </div>

      {/* portfolio mini stats */}
      <div style={{ padding: "14px 20px 4px" }}>
        <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr 1fr", gap: 10 }}>
          <Card style={{ textAlign: "center", padding: "12px 6px", borderRadius: 18 }}>
            <div style={{ fontSize: 20 }}>🏢</div>
            <div style={{ fontFamily: F_TITLE, fontSize: 22, fontWeight: 800, color: C.ink, marginTop: 2, lineHeight: 1 }}>২</div>
            <div style={{ fontSize: 11, color: C.muted, fontWeight: 600, marginTop: 3 }}>বিল্ডিং</div>
          </Card>
          <Card style={{ textAlign: "center", padding: "12px 6px", borderRadius: 18 }}>
            <div style={{ fontSize: 20 }}>🚪</div>
            <div style={{ fontFamily: F_TITLE, fontSize: 22, fontWeight: 800, color: C.ink, marginTop: 2, lineHeight: 1 }}>১৪</div>
            <div style={{ fontSize: 11, color: C.muted, fontWeight: 600, marginTop: 3 }}>ইউনিট</div>
          </Card>
          <Card soft={C.butterBg} style={{ textAlign: "center", padding: "12px 6px", borderRadius: 18 }}>
            <div style={{ fontSize: 20 }}>💰</div>
            <div style={{ fontFamily: F_TITLE, fontSize: 17, fontWeight: 800, color: C.roseDk, marginTop: 2, lineHeight: 1 }}>৳৯৭K</div>
            <div style={{ fontSize: 11, color: C.mutedDk, fontWeight: 600, marginTop: 3 }}>মাসিক</div>
          </Card>
        </div>
      </div>

      {/* collection progress */}
      <div style={{ padding: "12px 20px 4px" }}>
        <Card style={{ borderRadius: 22 }}>
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start", marginBottom: 6 }}>
            <div>
              <div style={{ fontSize: 12, color: C.muted, fontWeight: 600 }}>এ মাসে আদায়</div>
              <div style={{ fontFamily: F_TITLE, fontSize: 24, fontWeight: 800, color: C.ink, letterSpacing: -.5, lineHeight: 1.1, marginTop: 2 }}>
                ৳৭১,০০০ <span style={{ fontSize: 13, color: C.muted, fontWeight: 600 }}>/৯৩K</span>
              </div>
            </div>
            <Chip bg={C.sageBg} fg={C.sageDk}>৭৬% 🎯</Chip>
          </div>
          <div style={{ height: 12, background: C.sageBg, borderRadius: 8, marginTop: 8, overflow: "hidden" }}>
            <div style={{ width: "76%", height: "100%", background: `linear-gradient(90deg, ${C.sage}, ${C.sageDk})`, borderRadius: 8 }}/>
          </div>
          <div style={{
            marginTop: 10, padding: "10px 12px", background: C.roseBg, borderRadius: 14,
            display: "flex", alignItems: "center", gap: 10,
          }}>
            <div style={{ fontSize: 22 }}>⏰</div>
            <div style={{ flex: 1 }}>
              <div style={{ fontSize: 12.5, color: C.roseDk, fontWeight: 700 }}>১ টি ভাড়া বাকি</div>
              <div style={{ fontSize: 11, color: C.mutedDk, marginTop: 1 }}>৳২২,০০০ · Karim H. · 2C</div>
            </div>
            <button onClick={() => go("rentReq")} style={{
              background: C.rose, color: "#fff", border: 0, borderRadius: 999,
              padding: "6px 12px", fontSize: 11, fontWeight: 700, cursor: "pointer", fontFamily: F_TITLE,
            }}>চান</button>
          </div>
        </Card>
      </div>

      {/* quick actions */}
      <div style={{ padding: "14px 20px 4px" }}>
        <div style={{ fontFamily: F_TITLE, fontSize: 14, fontWeight: 800, color: C.ink, marginBottom: 10, paddingLeft: 4 }}>দ্রুত কাজ ✨</div>
        <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 10 }}>
          {[
            ["addBuilding","🏢","বিল্ডিং যোগ", "Add building",  C.sageBg,   C.sageDk],
            ["rentReq",   "📤", "ভাড়া চান",    "Rent request",  C.roseBg,   C.roseDk],
            ["addTenant", "👤", "ভাড়াটিয়া যোগ", "Add tenant",    C.butterBg, C.roseDk],
            ["dashboard", "📊", "ড্যাশবোর্ড",   "Dashboard",     C.sageBg,   C.sageDk],
          ].map(([k, e, t, en, bg, fg]) => (
            <Card key={k} onClick={() => go(k)} soft={bg} style={{ padding: "14px 14px", borderRadius: 20 }}>
              <div style={{ fontSize: 26, marginBottom: 6 }}>{e}</div>
              <div style={{ fontFamily: F_TITLE, fontWeight: 700, fontSize: 14.5, color: fg, lineHeight: 1.2 }}>{t}</div>
              <div style={{ fontSize: 10.5, color: C.mutedDk, marginTop: 2, fontWeight: 600 }}>{en}</div>
            </Card>
          ))}
        </div>
      </div>

      {/* maintenance/expenses quick view */}
      <div style={{ padding: "12px 20px 4px" }}>
        <Card onClick={() => go("expenses")} style={{ borderRadius: 20, padding: "14px 14px", display: "flex", alignItems: "center", gap: 12 }}>
          <div style={{ width: 44, height: 44, borderRadius: 22, background: C.butterBg, display: "grid", placeItems: "center", fontSize: 20 }}>🔧</div>
          <div style={{ flex: 1 }}>
            <div style={{ fontFamily: F_TITLE, fontWeight: 700, fontSize: 14, color: C.ink }}>মেরামত ও খরচ</div>
            <div style={{ fontSize: 11.5, color: C.muted, marginTop: 1 }}>২ টি নতুন অনুরোধ অপেক্ষায়</div>
          </div>
          <Chip bg={C.roseBg} fg={C.roseDk}>২ new</Chip>
        </Card>
      </div>

      {/* free hook */}
      <div style={{ padding: "12px 20px 24px" }}>
        <Card soft={C.butterBg} style={{ padding: "12px 16px", display: "flex", gap: 14, alignItems: "center", borderRadius: 18 }}>
          <div style={{ fontSize: 32 }}>🎁</div>
          <div style={{ flex: 1 }}>
            <div style={{ fontFamily: F_HAND, fontSize: 22, color: C.roseDk, lineHeight: .9 }}>Yay!</div>
            <div style={{ fontFamily: F_TITLE, fontSize: 13, fontWeight: 700, color: C.ink, marginTop: 2 }}>২ ভাড়াটিয়া পর্যন্ত ফ্রি</div>
            <div style={{ fontSize: 11, color: C.muted, marginTop: 1 }}>আপনি এখন ১/২ ব্যবহার করেছেন</div>
          </div>
          <button style={{
            background: C.rose, color: "#fff", border: 0, borderRadius: 999,
            padding: "8px 14px", fontSize: 11.5, fontWeight: 700, cursor: "pointer", fontFamily: F_TITLE,
          }}>প্ল্যান</button>
        </Card>
      </div>
    </Scroll>

    {/* bottom nav */}
    <BottomNav active="home" go={go}/>
  </>
);

const BottomNav = ({ active, go }) => {
  const items = [
    ["home",     I.home,  "হোম"],
    ["dashboard",I.chart, "চার্ট"],
    ["addTenant",I.plus,  "যোগ"],
    ["rentReq",  I.cash,  "ভাড়া"],
    ["more",     I.more,  "আরও"],
  ];
  return (
    <div style={{
      borderTop: `1px solid ${C.line}`, background: C.card, padding: "8px 0 14px",
      display: "flex", justifyContent: "space-around", flexShrink: 0,
    }}>
      {items.map(([k, d, l]) => {
        const isActive = k === active;
        const isPlus = k === "addTenant";
        return (
          <button key={k} onClick={() => go(k)} style={{
            background: "transparent", border: 0, padding: "4px 4px",
            display: "flex", flexDirection: "column", alignItems: "center", gap: 2,
            cursor: "pointer", color: isActive ? C.sageDk : C.muted, minWidth: 56,
          }}>
            <div style={{
              width: isPlus ? 44 : 32, height: isPlus ? 44 : 32, borderRadius: isPlus ? 22 : 16,
              background: isPlus ? C.sage : (isActive ? C.sageBg : "transparent"),
              display: "grid", placeItems: "center",
              boxShadow: isPlus ? `0 8px 16px -6px ${C.sageDk}` : "none",
              marginTop: isPlus ? -8 : 0,
            }}>
              <Icon d={d} s={isPlus ? 22 : 20} c={isPlus ? "#fff" : (isActive ? C.sageDk : C.muted)}/>
            </div>
            <span style={{ fontSize: 10.5, fontWeight: 700, fontFamily: F_TITLE }}>{l}</span>
          </button>
        );
      })}
    </div>
  );
};

// ─── ADD TENANT ────────────────────────────────────────────────
const AddTenant = ({ go }) => (
  <>
    <TopBar title="ভাড়াটিয়া যোগ" onBack={() => go("home")}/>
    <Scroll>
      <div style={{ padding: "4px 22px 8px", textAlign: "center" }}>
        <div style={{ fontSize: 60 }}>👋</div>
        <div style={{ fontFamily: F_HAND, fontSize: 30, color: C.sageDk, marginTop: 4, lineHeight: 1 }}>Let's add a tenant</div>
        <div style={{ fontFamily: F_TITLE, fontSize: 19, fontWeight: 800, color: C.ink, letterSpacing: -.3, marginTop: 4 }}>কীভাবে শুরু করতে চান?</div>
      </div>
      <div style={{ padding: "16px 20px", display: "grid", gap: 12 }}>
        <Card
          onClick={() => go("ocr")}
          soft={`linear-gradient(135deg, ${C.sageBg}, #D8E5DC)`}
          style={{ border: `2px solid ${C.sage}`, padding: "16px 16px", display: "flex", gap: 14, alignItems: "center", borderRadius: 22 }}
        >
          <div style={{
            width: 64, height: 64, borderRadius: 32,
            background: `linear-gradient(135deg, ${C.sage}, ${C.sageDk})`, color: "#fff",
            display: "grid", placeItems: "center", fontSize: 28, flexShrink: 0,
            boxShadow: `0 6px 14px -4px ${C.sageDk}`,
          }}>📸</div>
          <div style={{ flex: 1 }}>
            <div style={{ fontFamily: F_TITLE, fontWeight: 800, fontSize: 17, color: C.ink }}>NID-এর ছবি তুলুন</div>
            <div style={{ fontSize: 12.5, color: C.muted, marginTop: 2 }}>AI নিজেই সব পূরণ করবে ✨</div>
          </div>
          <Chip bg={C.sage} fg="#fff">⭐</Chip>
        </Card>
        <Card onClick={() => go("voice")} style={{ padding: "16px 16px", display: "flex", gap: 14, alignItems: "center", borderRadius: 22 }}>
          <div style={{ width: 64, height: 64, borderRadius: 32, background: C.butterBg, display: "grid", placeItems: "center", fontSize: 28, flexShrink: 0 }}>🎤</div>
          <div style={{ flex: 1 }}>
            <div style={{ fontFamily: F_TITLE, fontWeight: 800, fontSize: 17, color: C.ink }}>ভয়েস দিয়ে বলুন</div>
            <div style={{ fontSize: 12.5, color: C.muted, marginTop: 2 }}>বাংলায় বললেই হবে</div>
          </div>
          <Icon d={I.arrow} s={18} c={C.muted}/>
        </Card>
        <Card onClick={() => go("dmp")} style={{ padding: "16px 16px", display: "flex", gap: 14, alignItems: "center", borderRadius: 22 }}>
          <div style={{ width: 64, height: 64, borderRadius: 32, background: C.roseBg, display: "grid", placeItems: "center", fontSize: 28, flexShrink: 0 }}>✍️</div>
          <div style={{ flex: 1 }}>
            <div style={{ fontFamily: F_TITLE, fontWeight: 800, fontSize: 17, color: C.ink }}>হাতে লিখুন</div>
            <div style={{ fontSize: 12.5, color: C.muted, marginTop: 2 }}>সময় নিয়ে নিজে পূরণ করুন</div>
          </div>
          <Icon d={I.arrow} s={18} c={C.muted}/>
        </Card>
      </div>

      <div style={{ padding: "16px 20px 24px" }}>
        <Card soft={C.sageBg} style={{ padding: "12px 14px", display: "flex", gap: 10, alignItems: "center", borderRadius: 16 }}>
          <div style={{ fontSize: 20 }}>💡</div>
          <div style={{ fontSize: 12, color: C.sageDk, fontWeight: 600, lineHeight: 1.5 }}>
            <b>টিপ:</b> NID ছবি পদ্ধতি সবচেয়ে দ্রুত — ২ মিনিটে শেষ
          </div>
        </Card>
      </div>
    </Scroll>
  </>
);

// ─── OCR ───────────────────────────────────────────────────────
const OCR = ({ go }) => {
  const [scanned, setScanned] = useState(false);
  return (
    <>
      <TopBar title="NID স্ক্যান" onBack={() => go("addTenant")}/>
      <Scroll>
        {!scanned ? (
          <div style={{ padding: "4px 22px 20px" }}>
            <div style={{ fontFamily: F_HAND, fontSize: 26, color: C.sageDk, textAlign: "center", marginBottom: 14 }}>Snap your NID</div>
            <Card soft="#1a2820" style={{ padding: 0, overflow: "hidden", borderRadius: 24 }}>
              <div style={{ aspectRatio: "1.58", position: "relative", display: "grid", placeItems: "center" }}>
                <div style={{ position: "absolute", inset: 18, border: `3px dashed rgba(255,255,255,.4)`, borderRadius: 16 }}/>
                <div style={{
                  position: "absolute", left: 18, right: 18, height: 2, background: C.butter,
                  top: "50%", boxShadow: `0 0 18px ${C.butter}`, borderRadius: 1,
                }}/>
                <div style={{ color: "rgba(255,255,255,.75)", textAlign: "center", zIndex: 2 }}>
                  <div style={{ fontSize: 44 }}>📇</div>
                  <div style={{ marginTop: 8, fontSize: 13, fontWeight: 600 }}>NID কার্ড ফ্রেমে রাখুন</div>
                </div>
              </div>
            </Card>
            <Card soft={C.sageBg} style={{ marginTop: 14, padding: "12px 14px", display: "flex", gap: 10, alignItems: "center", borderRadius: 16 }}>
              <div style={{ fontSize: 20 }}>💡</div>
              <div style={{ fontSize: 12.5, color: C.sageDk, fontWeight: 600, lineHeight: 1.5 }}>ভালো আলোতে, সমান্তরাল করে ধরুন। ছবি কোথাও পাঠানো হবে না।</div>
            </Card>
            <div style={{ marginTop: 18 }}>
              <Btn full size="lg" onClick={() => setScanned(true)}>📸 ছবি তুলুন</Btn>
            </div>
          </div>
        ) : (
          <div style={{ padding: "4px 22px 20px" }}>
            <Card soft={C.sageBg} style={{ display: "flex", gap: 10, alignItems: "center", padding: "12px 14px", marginBottom: 14, borderRadius: 18 }}>
              <div style={{ fontSize: 22 }}>✨</div>
              <div style={{ fontSize: 13.5, color: C.sageDk, fontWeight: 700, flex: 1 }}>AI বুঝে নিয়েছে — যাচাই করুন</div>
            </Card>
            <div style={{ display: "grid", gap: 10 }}>
              {[
                ["নাম",         "Karim Hossain",       "👤"],
                ["NID নম্বর",   "1992 5566 7788",      "🆔"],
                ["জন্ম তারিখ",  "12 Mar 1992",         "🎂"],
                ["ঠিকানা",      "Mirpur 10, Dhaka",    "🏠"],
              ].map(([l, v, e]) => (
                <Card key={l} style={{ padding: "12px 14px", display: "flex", gap: 12, alignItems: "center", borderRadius: 18 }}>
                  <div style={{ fontSize: 22 }}>{e}</div>
                  <div style={{ flex: 1 }}>
                    <div style={{ fontSize: 11, color: C.muted, fontWeight: 600 }}>{l}</div>
                    <div style={{ fontFamily: F_TITLE, fontWeight: 700, color: C.ink, fontSize: 15, marginTop: 1 }}>{v}</div>
                  </div>
                  <button style={{ background: C.sageBg, color: C.sageDk, border: 0, fontSize: 11, fontWeight: 700, padding: "6px 10px", borderRadius: 999, cursor: "pointer" }}>edit</button>
                </Card>
              ))}
            </div>
            <div style={{ marginTop: 18 }}>
              <Btn full size="lg" onClick={() => go("dmp")}>পরবর্তী — ফর্ম তৈরি 🚀</Btn>
            </div>
          </div>
        )}
      </Scroll>
    </>
  );
};

// ─── DMP FORM ──────────────────────────────────────────────────
const DMP = ({ go }) => (
  <>
    <TopBar
      title="DMP ফর্ম"
      onBack={() => go("home")}
      action={<Chip bg={C.sageBg} fg={C.sageDk}>✓ প্রস্তুত</Chip>}
    />
    <Scroll>
      <div style={{ padding: "4px 22px 6px", textAlign: "center" }}>
        <div style={{ fontSize: 56 }}>🎉</div>
        <div style={{ fontFamily: F_HAND, fontSize: 30, color: C.sageDk, marginTop: 0, lineHeight: 1 }}>All done!</div>
        <div style={{ fontFamily: F_TITLE, fontSize: 17, fontWeight: 800, color: C.ink, marginTop: 4 }}>ফর্ম তৈরি হয়েছে</div>
      </div>
      <div style={{ padding: "14px 20px" }}>
        <Card style={{ padding: "20px 18px", borderRadius: 22 }}>
          <div style={{ textAlign: "center", paddingBottom: 12, marginBottom: 14, borderBottom: `1px dashed ${C.line}` }}>
            <div style={{ fontSize: 22, marginBottom: 6 }}>🏛️</div>
            <div style={{ fontFamily: F_TITLE, fontWeight: 800, fontSize: 14, color: C.ink, letterSpacing: .2 }}>ঢাকা মেট্রোপলিটন পুলিশ</div>
            <div style={{ fontSize: 10, color: C.muted, marginTop: 3, letterSpacing: 1 }}>DMP · CIMS</div>
            <Chip bg={C.roseBg} fg={C.roseDk} style={{ marginTop: 8 }}>ভাড়াটিয়া তথ্য ফরম</Chip>
          </div>
          {[
            ["ভাড়াটিয়া",  "Karim Hossain"],
            ["NID",         "1992 5566 7788"],
            ["বাড়িওয়ালা", "Abdul Karim"],
            ["ঠিকানা",      "Mirpur 10, Flat 2C"],
            ["শুরু",        "জানু ২০২৫"],
            ["পরিবার",      "৩ জন"],
            ["পেশা",        "বেসরকারি চাকরি"],
          ].map(([l, v], i) => (
            <div key={i} style={{ display: "flex", padding: "8px 0", fontSize: 13, borderBottom: i < 6 ? `1px dotted ${C.line}` : 0 }}>
              <div style={{ width: 110, color: C.muted, fontWeight: 600 }}>{l}</div>
              <div style={{ color: C.ink, fontWeight: 700, fontFamily: F_TITLE, flex: 1 }}>{v}</div>
            </div>
          ))}
          <div style={{ marginTop: 10, paddingTop: 10, borderTop: `1px solid ${C.line}`, fontSize: 9.5, color: C.muted, textAlign: "center", letterSpacing: .3 }}>
            Generated by Khatir · KHT/2026/0512 · {new Date().toLocaleDateString("bn-BD")}
          </div>
        </Card>
        <div style={{ marginTop: 16, display: "grid", gap: 10 }}>
          <Btn kind="primary" full size="lg" onClick={() => go("verify")}>📥 PDF নামান</Btn>
          <Btn kind="soft" full onClick={() => go("home")}>সেভ করে হোমে যান</Btn>
        </div>
      </div>
    </Scroll>
  </>
);

// ─── VOICE ─────────────────────────────────────────────────────
const Voice = ({ go }) => {
  const [done, setDone] = useState(false);
  return (
    <>
      <TopBar title="ভয়েস ফর্ম" onBack={() => go("addTenant")}/>
      <Scroll>
        <div style={{ padding: "6px 24px 24px", textAlign: "center" }}>
          {!done ? (
            <>
              <div style={{ fontFamily: F_HAND, fontSize: 30, color: C.sageDk, marginTop: 8, lineHeight: 1 }}>Talk to me!</div>
              <div style={{ fontFamily: F_TITLE, fontSize: 18, fontWeight: 800, color: C.ink, marginTop: 4 }}>মাইক চাপুন</div>
              <div
                onClick={() => setDone(true)}
                style={{
                  width: 160, height: 160, borderRadius: 80,
                  background: `radial-gradient(circle at 30% 30%, ${C.rose}, ${C.roseDk})`,
                  margin: "26px auto", display: "grid", placeItems: "center", cursor: "pointer",
                  boxShadow: `0 0 0 14px ${C.roseBg}, 0 0 0 28px rgba(232,155,139,.18), 0 20px 40px -10px ${C.roseDk}`,
                }}
              >
                <div style={{ fontSize: 70 }}>🎤</div>
              </div>
              <div style={{ color: C.muted, marginTop: 6, fontSize: 13 }}>চেপে ধরে বাংলায় বলুন</div>
              <Card soft={C.butterBg} style={{ marginTop: 18, padding: "12px 14px", textAlign: "left", borderRadius: 16 }}>
                <div style={{ fontSize: 11, color: C.mutedDk, fontWeight: 700, marginBottom: 4 }}>উদাহরণ</div>
                <div style={{ fontFamily: F_HAND, fontSize: 16, color: C.ink, lineHeight: 1.4 }}>
                  "নতুন ভাড়াটিয়া, নাম রহিম উদ্দিন, ফ্ল্যাট ৪বি, ভাড়া ছাব্বিশ হাজার, মার্চ থেকে…"
                </div>
              </Card>
            </>
          ) : (
            <>
              <Card soft="#2a3530" style={{ color: "#fff", textAlign: "left", padding: 18, borderRadius: 20 }}>
                <div style={{ fontSize: 10.5, color: C.butter, fontWeight: 700, marginBottom: 8, letterSpacing: 1.5, textTransform: "uppercase" }}>🎙 আপনি বললেন</div>
                <div style={{ fontFamily: F_TITLE, fontSize: 14.5, fontWeight: 600, lineHeight: 1.55 }}>
                  "নতুন ভাড়াটিয়া, নাম রহিম উদ্দিন, ফ্ল্যাট ৪বি, ভাড়া ছাব্বিশ হাজার, মার্চ থেকে"
                </div>
              </Card>
              <Chip bg={C.sageBg} fg={C.sageDk} style={{ marginTop: 14 }}>✨ AI বুঝে নিয়েছে</Chip>
              <div style={{ marginTop: 14, display: "grid", gap: 8, textAlign: "left" }}>
                {[["নাম","রহিম উদ্দিন","👤"],["ইউনিট","৪বি","🚪"],["ভাড়া","৳২৬,০০০","💰"],["শুরু","Mar 2026","📅"]].map(([l,v,e]) => (
                  <Card key={l} style={{ padding: "10px 14px", display: "flex", alignItems: "center", gap: 12, borderRadius: 14 }}>
                    <div style={{ fontSize: 18 }}>{e}</div>
                    <div style={{ flex: 1, fontSize: 12, color: C.muted, fontWeight: 600 }}>{l}</div>
                    <b style={{ color: C.ink, fontFamily: F_TITLE, fontSize: 14 }}>{v}</b>
                  </Card>
                ))}
              </div>
              <div style={{ marginTop: 18 }}>
                <Btn full size="lg" onClick={() => go("dmp")}>ফর্ম তৈরি 🎉</Btn>
              </div>
            </>
          )}
        </div>
      </Scroll>
    </>
  );
};

// ─── VERIFY ────────────────────────────────────────────────────
const Verify = ({ go }) => {
  const [s, setS] = useState("idle");
  return (
    <>
      <TopBar title="NID যাচাই" onBack={() => go("home")}/>
      <Scroll>
        <div style={{ padding: "6px 24px 24px", textAlign: "center" }}>
          <div style={{ fontSize: 80, marginTop: 14 }}>{s === "ok" ? "🎉" : "🛡️"}</div>
          {s === "idle" && <>
            <div style={{ fontFamily: F_HAND, fontSize: 28, color: C.sageDk, marginTop: 4, lineHeight: 1 }}>Let's verify</div>
            <div style={{ fontFamily: F_TITLE, fontSize: 19, fontWeight: 800, color: C.ink, marginTop: 4 }}>Karim Hossain</div>
            <div style={{ color: C.muted, fontSize: 12.5, marginTop: 2 }}>NID 1992 5566 7788</div>
            <Card style={{ margin: "20px 0", textAlign: "left", padding: "14px 16px", borderRadius: 18 }}>
              <div style={{ fontSize: 13, color: C.ink, lineHeight: 1.6 }}>
                নির্বাচন কমিশনের <b style={{ color: C.sageDk }}>Matched/Not Matched</b> সার্ভিস দিয়ে পরিচয় যাচাই হবে।
              </div>
              <div style={{
                marginTop: 12, padding: "10px 12px", background: C.butterBg, borderRadius: 12,
                display: "flex", alignItems: "center", gap: 8,
              }}>
                <div style={{ fontSize: 16 }}>✓</div>
                <span style={{ fontSize: 12, color: C.mutedDk, flex: 1 }}>ভাড়াটিয়ার সম্মতি নেওয়া হয়েছে</span>
              </div>
              <div style={{
                marginTop: 10, padding: "10px 12px", background: C.sageBg, borderRadius: 12,
                display: "flex", justifyContent: "space-between", alignItems: "center",
              }}>
                <span style={{ fontSize: 12, color: C.mutedDk, fontWeight: 600 }}>ফি</span>
                <b style={{ fontFamily: F_TITLE, color: C.sageDk, fontSize: 16 }}>৳৭৫</b>
              </div>
            </Card>
            <Btn full size="lg" kind="primary" onClick={() => { setS("loading"); setTimeout(() => setS("ok"), 1200); }}>
              যাচাই করুন 🛡️
            </Btn>
          </>}
          {s === "loading" && (
            <div style={{ fontFamily: F_HAND, fontSize: 26, color: C.muted, marginTop: 18 }}>verifying…</div>
          )}
          {s === "ok" && <>
            <div style={{ fontFamily: F_HAND, fontSize: 36, color: C.sageDk, marginTop: 4, lineHeight: 1 }}>Matched!</div>
            <div style={{ fontFamily: F_TITLE, fontSize: 18, fontWeight: 800, color: C.ink, marginTop: 2 }}>পরিচয় নিশ্চিত</div>
            <Card style={{ marginTop: 18, textAlign: "left", padding: 14, borderRadius: 18 }}>
              {[["নাম","✓"],["জন্ম তারিখ","✓"],["ফেস ম্যাচ","✓"]].map(([l, v], i) => (
                <div key={i} style={{
                  display: "flex", justifyContent: "space-between", alignItems: "center",
                  padding: "10px 0", borderBottom: i < 2 ? `1px solid ${C.line}` : 0,
                }}>
                  <span style={{ color: C.mutedDk, fontWeight: 600 }}>{l}</span>
                  <Chip bg={C.sageBg} fg={C.sageDk}>{v} মিল</Chip>
                </div>
              ))}
            </Card>
            <div style={{ marginTop: 20 }}>
              <Btn full size="lg" onClick={() => go("home")}>সম্পন্ন 🎉</Btn>
            </div>
          </>}
        </div>
      </Scroll>
    </>
  );
};

// ─── RENT REQUEST ──────────────────────────────────────────────
const RentReq = ({ go }) => {
  const [sent, setSent] = useState(false);
  return (
    <>
      <TopBar title="ভাড়ার অনুরোধ" onBack={() => go("home")}/>
      <Scroll>
        {!sent ? (
          <>
            <div style={{ padding: "4px 22px 8px", textAlign: "center" }}>
              <div style={{ fontSize: 52 }}>📤</div>
              <div style={{ fontFamily: F_HAND, fontSize: 28, color: C.sageDk, lineHeight: 1 }}>Ask for rent</div>
              <div style={{ fontFamily: F_TITLE, fontSize: 18, fontWeight: 800, color: C.ink, marginTop: 4 }}>কাকে পাঠাবেন?</div>
              <div style={{ color: C.mutedDk, fontSize: 12.5, marginTop: 8, lineHeight: 1.5, maxWidth: 290, margin: "8px auto 0" }}>
                ভাড়াটিয়ার অ্যাপ না থাকলেও সমস্যা নেই — WhatsApp-এ লিংক পাবেন 💚
              </div>
            </div>
            <div style={{ padding: "14px 22px" }}>
              <div style={{ display: "grid", gap: 10 }}>
                {[
                  ["Karim Hossain", "2C", "৳২২,০০০", "late",  C.rose,    "মে ৩"],
                  ["Rahim Uddin",   "4B", "৳২৬,০০০", "ok",    C.sage,    "মে ৫"],
                  ["Salim Mia",     "1A", "৳১৮,৫০০", "ok",    C.sageDk,  "মে ৫"],
                ].map(([n, u, a, st, bg, d], i) => (
                  <Card key={i} style={{ padding: "12px 14px", display: "flex", alignItems: "center", gap: 12, borderRadius: 18 }}>
                    <div style={{
                      width: 44, height: 44, borderRadius: 22, background: bg, color: "#fff",
                      display: "grid", placeItems: "center", fontFamily: F_TITLE, fontWeight: 800, fontSize: 17,
                    }}>{n[0]}</div>
                    <div style={{ flex: 1 }}>
                      <div style={{ fontFamily: F_TITLE, fontWeight: 700, fontSize: 14.5, color: C.ink }}>{n}</div>
                      <div style={{ fontSize: 11.5, color: C.muted, marginTop: 1 }}>ইউনিট {u} · {a} · বকেয়া {d}</div>
                    </div>
                    {st === "late"
                      ? <Chip bg={C.roseBg} fg={C.roseDk}>বাকি 😟</Chip>
                      : <div style={{ width: 22, height: 22, borderRadius: 11, background: C.sage, display: "grid", placeItems: "center" }}>
                          <Icon d={I.check} s={14} c="#fff" sw={3}/>
                        </div>
                    }
                  </Card>
                ))}
              </div>
              <Card soft={C.sageBg} style={{ marginTop: 14, padding: "12px 14px", display: "flex", gap: 12, alignItems: "center", borderRadius: 18 }}>
                <div style={{ fontSize: 26 }}>⏰</div>
                <div style={{ flex: 1 }}>
                  <div style={{ fontFamily: F_TITLE, fontWeight: 700, fontSize: 13.5, color: C.ink }}>স্বয়ংক্রিয় তফসিল</div>
                  <div style={{ fontSize: 11.5, color: C.mutedDk, marginTop: 1 }}>প্রতি মাসের ৫ তারিখে · সক্রিয়</div>
                </div>
                <div style={{ width: 42, height: 24, borderRadius: 12, background: C.sage, position: "relative" }}>
                  <div style={{ width: 20, height: 20, borderRadius: 10, background: "#fff", position: "absolute", top: 2, right: 2 }}/>
                </div>
              </Card>
              <div style={{ marginTop: 16 }}>
                <Btn full size="lg" onClick={() => setSent(true)}>সকলকে পাঠান 📤</Btn>
              </div>
            </div>
          </>
        ) : (
          <div style={{ padding: "8px 22px 22px" }}>
            <div style={{ textAlign: "center", marginBottom: 14 }}>
              <div style={{ fontSize: 76 }}>🎉</div>
              <div style={{ fontFamily: F_HAND, fontSize: 32, color: C.sageDk, lineHeight: 1 }}>Sent!</div>
              <div style={{ fontFamily: F_TITLE, fontSize: 15, fontWeight: 700, color: C.ink, marginTop: 4 }}>
                WhatsApp-এ লিংক পেয়েছেন ৩ জন
              </div>
            </div>
            <Card style={{ padding: "4px 0", borderRadius: 22 }}>
              {[
                ["1", "📥", "পেমেন্ট প্রমাণ আপলোড",   "শীঘ্রই",   C.roseBg,    true],
                ["2", "🔔", "আপনি বিজ্ঞপ্তি পাবেন",   "অপেক্ষায়", C.sageBg,    false],
                ["3", "✅", "'টাকা পেয়েছি' চাপুন",     "অপেক্ষায়", C.butterBg,  false],
              ].map(([n, e, t, s, bg, active], i) => (
                <div key={i} style={{
                  padding: "14px 16px", display: "flex", alignItems: "center", gap: 14,
                  borderBottom: i < 2 ? `1px solid ${C.line}` : 0,
                }}>
                  <div style={{ width: 44, height: 44, borderRadius: 22, background: bg, display: "grid", placeItems: "center", fontSize: 20 }}>{e}</div>
                  <div style={{ flex: 1 }}>
                    <div style={{ fontFamily: F_TITLE, fontSize: 14, fontWeight: 700, color: C.ink, lineHeight: 1.3 }}>{t}</div>
                    <div style={{ fontSize: 11.5, color: active ? C.roseDk : C.muted, marginTop: 2, fontWeight: 600 }}>
                      {active ? "⏳ " + s : s}
                    </div>
                  </div>
                  <div style={{ fontFamily: F_TITLE, fontWeight: 800, color: active ? C.roseDk : C.line, fontSize: 18 }}>0{n}</div>
                </div>
              ))}
            </Card>
            <div style={{ marginTop: 14 }}>
              <Btn full kind="soft" onClick={() => go("home")}>হোমে ফিরি 🏠</Btn>
            </div>
          </div>
        )}
      </Scroll>
    </>
  );
};

// ─── EXPENSES / MAINTENANCE ────────────────────────────────────
const Expenses = ({ go }) => (
  <>
    <TopBar title="মেরামত ও খরচ" onBack={() => go("home")}/>
    <Scroll>
      <div style={{ padding: "4px 22px 4px" }}>
        <Card soft={`linear-gradient(135deg, ${C.butter}, ${C.butterDk})`} style={{ color: C.ink, padding: "18px 18px", borderRadius: 22 }}>
          <Chip bg="rgba(255,255,255,.45)" fg={C.ink}>এ মাসে</Chip>
          <div style={{ fontFamily: F_HAND, fontSize: 20, color: C.ink, marginTop: 8, lineHeight: 1, opacity: .8 }}>Total expenses</div>
          <div style={{ fontFamily: F_TITLE, fontSize: 32, fontWeight: 800, letterSpacing: -1, lineHeight: 1, marginTop: 4 }}>৳৪২,০০০</div>
          <div style={{ marginTop: 8, fontSize: 12, color: C.mutedDk, fontWeight: 600 }}>৩ টি মেরামত · ২ অপেক্ষায়</div>
        </Card>
      </div>

      <div style={{ padding: "14px 22px 4px" }}>
        <div style={{ fontFamily: F_TITLE, fontSize: 14, fontWeight: 800, color: C.ink, marginBottom: 10 }}>নতুন অনুরোধ 🔔</div>
        <div style={{ display: "grid", gap: 10 }}>
          {[
            ["Karim Hossain", "2C", "পানির পাইপ লিক হচ্ছে", "🚿", "পানি"],
            ["Rahim Uddin",   "4B", "বাথরুমের লাইট কাজ করছে না", "💡", "বিদ্যুৎ"],
          ].map(([n, u, t, e, cat], i) => (
            <Card key={i} style={{ padding: "14px 14px", borderRadius: 18 }}>
              <div style={{ display: "flex", alignItems: "flex-start", gap: 12 }}>
                <div style={{ fontSize: 26 }}>{e}</div>
                <div style={{ flex: 1 }}>
                  <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between" }}>
                    <div style={{ fontFamily: F_TITLE, fontWeight: 700, fontSize: 14, color: C.ink }}>{n}</div>
                    <Chip bg={C.roseBg} fg={C.roseDk}>{cat}</Chip>
                  </div>
                  <div style={{ fontSize: 11.5, color: C.muted, marginTop: 1 }}>ইউনিট {u}</div>
                  <div style={{ fontSize: 13, color: C.ink, marginTop: 6, lineHeight: 1.4 }}>{t}</div>
                  <div style={{ marginTop: 10, display: "flex", gap: 8 }}>
                    <Btn size="sm" kind="primary">সমাধান করেছি</Btn>
                    <Btn size="sm" kind="soft">দেখুন</Btn>
                  </div>
                </div>
              </div>
            </Card>
          ))}
        </div>
      </div>

      <div style={{ padding: "14px 22px 8px" }}>
        <div style={{ fontFamily: F_TITLE, fontSize: 14, fontWeight: 800, color: C.ink, marginBottom: 10 }}>সাম্প্রতিক খরচ</div>
        <Card style={{ padding: 0, borderRadius: 20, overflow: "hidden" }}>
          {[
            ["প্লাম্বিং মেরামত", "১০ মে", "৳৩,৫০০", "🔧"],
            ["দেয়াল রং",        "৮ মে",  "৳১২,০০০", "🎨"],
            ["বৈদ্যুতিক তার",    "৫ মে",  "৳৪,২০০", "💡"],
            ["AC সার্ভিস",       "২ মে",  "৳২,৮০০", "❄️"],
          ].map(([t, d, a, e], i) => (
            <div key={i} style={{
              padding: "12px 14px", display: "flex", alignItems: "center", gap: 12,
              borderBottom: i < 3 ? `1px solid ${C.line}` : 0,
            }}>
              <div style={{ fontSize: 20 }}>{e}</div>
              <div style={{ flex: 1 }}>
                <div style={{ fontFamily: F_TITLE, fontWeight: 700, fontSize: 13.5, color: C.ink }}>{t}</div>
                <div style={{ fontSize: 11, color: C.muted, marginTop: 1 }}>{d}</div>
              </div>
              <div style={{ fontFamily: F_TITLE, fontWeight: 800, color: C.roseDk, fontSize: 14 }}>{a}</div>
            </div>
          ))}
        </Card>
      </div>

      <div style={{ padding: "10px 22px 28px" }}>
        <Btn full kind="ghost" onClick={() => go("home")}>+ ম্যানুয়াল খরচ যোগ করুন</Btn>
      </div>
    </Scroll>
  </>
);

// ─── DASHBOARD ─────────────────────────────────────────────────
const Dashboard = ({ go }) => {
  const months = ["ডিস","জান","ফেব","মার","এপ্র","মে"];
  const data = [82, 88, 76, 91, 95, 76];
  return (
    <>
      <TopBar title="ড্যাশবোর্ড" onBack={() => go("home")}/>
      <Scroll>
        <div style={{ padding: "4px 20px 8px" }}>
          <Card
            soft={`linear-gradient(135deg, ${C.sage} 0%, ${C.sageDk} 100%)`}
            style={{ color: "#fff", borderRadius: 26, padding: "20px 22px", position: "relative", overflow: "hidden" }}
          >
            <Chip bg="rgba(255,255,255,.22)" fg="#fff">FY ২৫-২৬</Chip>
            <div style={{ fontFamily: F_HAND, fontSize: 22, color: "rgba(255,255,255,.88)", marginTop: 8, lineHeight: 1 }}>Total income</div>
            <div style={{ fontFamily: F_TITLE, fontSize: 42, fontWeight: 800, letterSpacing: -1.5, lineHeight: 1, marginTop: 4 }}>৳৫.১৪L</div>
            <div style={{ marginTop: 10, display: "flex", gap: 8, alignItems: "center", fontSize: 12, fontWeight: 700 }}>
              <span style={{ background: "rgba(255,255,255,.22)", padding: "4px 10px", borderRadius: 999 }}>↑ ১২%</span>
              <span style={{ opacity: .85 }}>গত বছরের চেয়ে</span>
            </div>
            <div style={{ position: "absolute", right: -8, bottom: -8, fontSize: 120, opacity: .13 }}>📈</div>
          </Card>
        </div>

        {/* collection chart */}
        <div style={{ padding: "12px 20px 4px" }}>
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "baseline", marginBottom: 10 }}>
            <div style={{ fontFamily: F_TITLE, fontSize: 14.5, fontWeight: 800, color: C.ink }}>আদায়ের হার 📊</div>
            <Chip>↑ ভালো চলছে</Chip>
          </div>
          <Card style={{ padding: "16px 14px", borderRadius: 22 }}>
            <div style={{ display: "flex", alignItems: "flex-end", gap: 10, height: 130 }}>
              {data.map((v, i) => (
                <div key={i} style={{ flex: 1, display: "flex", flexDirection: "column", alignItems: "center", gap: 6 }}>
                  <div style={{ fontFamily: F_TITLE, fontSize: 10.5, fontWeight: 800, color: i === data.length - 1 ? C.roseDk : C.sageDk }}>{v}</div>
                  <div style={{
                    width: "100%", height: v * 0.95,
                    background: i === data.length - 1
                      ? `linear-gradient(180deg, ${C.rose}, ${C.roseDk})`
                      : `linear-gradient(180deg, ${C.sage}, ${C.sageDk})`,
                    borderRadius: "14px 14px 4px 4px",
                  }}/>
                </div>
              ))}
            </div>
            <div style={{ display: "flex", gap: 10, marginTop: 8 }}>
              {months.map((m, i) => (
                <div key={i} style={{ flex: 1, textAlign: "center", fontSize: 10.5, color: C.muted, fontWeight: 600 }}>{m}</div>
              ))}
            </div>
          </Card>
        </div>

        {/* occupancy */}
        <div style={{ padding: "10px 20px 4px" }}>
          <Card style={{ padding: 14, borderRadius: 22, display: "flex", alignItems: "center", gap: 14 }}>
            <div style={{ position: "relative", width: 100, height: 100, flexShrink: 0 }}>
              <svg viewBox="0 0 36 36" style={{ transform: "rotate(-90deg)" }}>
                <circle cx="18" cy="18" r="15.9" fill="none" stroke={C.sageBg} strokeWidth="4" strokeLinecap="round"/>
                <circle cx="18" cy="18" r="15.9" fill="none" stroke={C.sage} strokeWidth="4" strokeDasharray="78 22" strokeLinecap="round"/>
              </svg>
              <div style={{ position: "absolute", inset: 0, display: "grid", placeItems: "center" }}>
                <div style={{ textAlign: "center" }}>
                  <div style={{ fontFamily: F_TITLE, fontSize: 22, fontWeight: 800, color: C.ink, lineHeight: 1 }}>৭৮%</div>
                  <div style={{ fontSize: 9.5, color: C.muted, fontWeight: 700 }}>১১/১৪</div>
                </div>
              </div>
            </div>
            <div style={{ flex: 1 }}>
              <div style={{ fontFamily: F_TITLE, fontSize: 14.5, fontWeight: 800, color: C.ink }}>অকুপেন্সি 🏠</div>
              <div style={{ marginTop: 8 }}>
                {[
                  ["ভাড়া হয়েছে",  "১১", C.sage,   "😊"],
                  ["খালি",          "২",  C.rose,   "😕"],
                  ["প্রক্রিয়াধীন", "১",  C.butter, "⏳"],
                ].map(([l, n, c, e], i) => (
                  <div key={i} style={{ display: "flex", alignItems: "center", gap: 8, fontSize: 12.5, padding: "2px 0" }}>
                    <span style={{ fontSize: 14 }}>{e}</span>
                    <span style={{ color: C.ink, flex: 1, fontWeight: 600 }}>{l}</span>
                    <b style={{ fontFamily: F_TITLE, color: C.ink }}>{n}</b>
                  </div>
                ))}
              </div>
            </div>
          </Card>
        </div>

        {/* expenses breakdown */}
        <div style={{ padding: "10px 20px 24px" }}>
          <div style={{ fontFamily: F_TITLE, fontSize: 14.5, fontWeight: 800, color: C.ink, marginBottom: 10 }}>প্রধান খরচ 💸</div>
          <div style={{ display: "grid", gap: 8 }}>
            {[
              ["প্লাম্বিং",       "৳১৮,৫০০", "🔧", 60, C.roseBg,    C.roseDk],
              ["পেইন্ট",          "৳১২,০০০", "🎨", 40, C.butterBg,  C.roseDk],
              ["বিদ্যুৎ মেরামত",  "৳৭,০০০",  "💡", 24, C.sageBg,    C.sageDk],
              ["অন্যান্য",        "৳৪,৫০০",  "✨", 15, "#F0E8DA",   C.mutedDk],
            ].map(([l, v, e, p, bg, fg], i) => (
              <Card key={i} soft={bg} style={{ padding: "12px 14px", display: "flex", alignItems: "center", gap: 12, borderRadius: 16 }}>
                <div style={{ fontSize: 22 }}>{e}</div>
                <div style={{ flex: 1 }}>
                  <div style={{ fontFamily: F_TITLE, fontWeight: 700, fontSize: 13.5, color: C.ink }}>{l}</div>
                  <div style={{ height: 5, background: "rgba(255,255,255,.65)", borderRadius: 999, marginTop: 5, overflow: "hidden" }}>
                    <div style={{ width: `${p}%`, height: "100%", background: fg, borderRadius: 999 }}/>
                  </div>
                </div>
                <div style={{ fontFamily: F_TITLE, fontWeight: 800, color: fg, fontSize: 14 }}>{v}</div>
              </Card>
            ))}
          </div>
        </div>
      </Scroll>
    </>
  );
};

// ─── ROLE CHOOSER ──────────────────────────────────────────────
const RoleChooser = ({ go, setRole }) => {
  const roles = [
    {
      k: "landlord", emoji: "🏠",
      tBn: "বাড়িওয়ালা", tEn: "Landlord",
      d: "নিজের বিল্ডিং ও ভাড়াটিয়া পরিচালনা করি",
      accent: C.sage, accentDk: C.sageDk, bg: C.sageBg,
      perks: ["DMP ফর্ম তৈরি", "ভাড়া আদায়", "খরচের হিসাব"],
      recommended: true,
    },
    {
      k: "manager", emoji: "🏢",
      tBn: "ভবন ম্যানেজার", tEn: "Building Manager",
      d: "একাধিক মালিকের সম্পত্তি পরিচালনা করি",
      accent: C.butter, accentDk: C.roseDk, bg: C.butterBg,
      perks: ["মাল্টি-ওনার পোর্টফোলিও", "টিম এক্সেস", "একীভূত রিপোর্ট"],
    },
    {
      k: "tenant", emoji: "👤",
      tBn: "ভাড়াটিয়া", tEn: "Tenant",
      d: "একটি ফ্ল্যাটে ভাড়া থাকি",
      accent: C.rose, accentDk: C.roseDk, bg: C.roseBg,
      perks: ["ভাড়া পরিশোধ", "রসিদ", "মেরামতের অনুরোধ"],
    },
  ];
  return (
    <>
      <TopBar transparent/>
      <Scroll>
        <div style={{ padding: "8px 22px 8px", textAlign: "center" }}>
          <div style={{ fontFamily: F_HAND, fontSize: 30, color: C.sageDk, lineHeight: 1 }}>Tell us who you are</div>
          <div style={{ fontFamily: F_TITLE, fontSize: 21, fontWeight: 800, color: C.ink, marginTop: 4, letterSpacing: -.4 }}>আপনি কে?</div>
          <div style={{ fontSize: 13, color: C.muted, marginTop: 6, lineHeight: 1.5, maxWidth: 300, margin: "6px auto 0" }}>
            যথাযথ ফিচার পেতে আপনার ভূমিকা নির্বাচন করুন
          </div>
        </div>
        <div style={{ padding: "16px 20px 24px", display: "grid", gap: 12 }}>
          {roles.map(r => (
            <Card
              key={r.k}
              onClick={() => { setRole(r.k); go(r.k === "tenant" ? "tenantHome" : r.k === "manager" ? "managerHome" : "home"); }}
              soft={r.k === "landlord" ? `linear-gradient(135deg, ${r.bg} 0%, #DCE9DF 100%)` : r.bg}
              style={{
                padding: "18px 18px", borderRadius: 22, position: "relative",
                border: r.recommended ? `2px solid ${r.accent}` : "2px solid transparent",
              }}
            >
              {r.recommended && (
                <div style={{
                  position: "absolute", top: -10, right: 16,
                  background: r.accentDk, color: "#fff",
                  fontSize: 10, fontWeight: 800, padding: "4px 10px", borderRadius: 999,
                  fontFamily: F_TITLE, letterSpacing: .5,
                }}>⭐ সাধারণত এটিই</div>
              )}
              <div style={{ display: "flex", alignItems: "center", gap: 14 }}>
                <div style={{
                  width: 64, height: 64, borderRadius: 32, background: "#fff",
                  display: "grid", placeItems: "center", fontSize: 30, flexShrink: 0,
                  boxShadow: `0 6px 14px -6px ${r.accentDk}`,
                }}>{r.emoji}</div>
                <div style={{ flex: 1 }}>
                  <div style={{ fontFamily: F_TITLE, fontWeight: 800, fontSize: 18, color: C.ink, lineHeight: 1.1 }}>{r.tBn}</div>
                  <div style={{ fontFamily: F_HAND, fontSize: 18, color: r.accentDk, lineHeight: 1, marginTop: 4 }}>{r.tEn}</div>
                  <div style={{ fontSize: 12, color: C.mutedDk, marginTop: 6, lineHeight: 1.4 }}>{r.d}</div>
                </div>
                <Icon d={I.arrow} s={20} c={r.accentDk}/>
              </div>
              <div style={{ display: "flex", flexWrap: "wrap", gap: 6, marginTop: 14, paddingTop: 12, borderTop: `1px dashed rgba(0,0,0,.08)` }}>
                {r.perks.map(p => (
                  <span key={p} style={{
                    background: "rgba(255,255,255,.8)", color: r.accentDk,
                    fontSize: 10.5, fontWeight: 700, padding: "4px 10px", borderRadius: 999,
                  }}>✓ {p}</span>
                ))}
              </div>
            </Card>
          ))}
        </div>
        <div style={{ padding: "0 22px 24px", textAlign: "center" }}>
          <div style={{ fontSize: 11.5, color: C.muted, lineHeight: 1.5 }}>
            পরে More মেনু থেকে পরিবর্তন করা যাবে
          </div>
        </div>
      </Scroll>
    </>
  );
};

// ─── ADD BUILDING ──────────────────────────────────────────────
const AddBuilding = ({ go }) => {
  const [step, setStep] = useState(1);
  const [name, setName] = useState("");
  const [area, setArea] = useState("");
  const [address, setAddress] = useState("");
  const [pinSet, setPinSet] = useState(false);
  const AREAS = ["Uttara","Mirpur","Mohammadpur","Dhanmondi","Banasree","Gulshan","Banani","Bashundhara","Old Dhaka","অন্য"];

  return (
    <>
      <TopBar title={step === 1 ? "নতুন বিল্ডিং" : step === 2 ? "ঠিকানা" : "মানচিত্রে পিন"} onBack={() => step > 1 ? setStep(step - 1) : go("home")}/>
      <Scroll>
        {/* progress */}
        <div style={{ padding: "4px 22px 14px" }}>
          <div style={{ display: "flex", gap: 6, alignItems: "center" }}>
            {[1, 2, 3].map(s => (
              <React.Fragment key={s}>
                <div style={{
                  flex: s === step ? 2 : 1, height: 6, borderRadius: 3,
                  background: s <= step ? C.sage : C.line, transition: "all .3s",
                }}/>
                {s < 3 && <div style={{ width: 2 }}/>}
              </React.Fragment>
            ))}
          </div>
          <div style={{ fontSize: 11, color: C.muted, marginTop: 6, fontWeight: 600 }}>ধাপ {step}/৩</div>
        </div>

        {step === 1 && (
          <div style={{ padding: "0 22px 24px" }}>
            <div style={{ textAlign: "center", marginBottom: 18 }}>
              <div style={{ fontSize: 56 }}>🏢</div>
              <div style={{ fontFamily: F_HAND, fontSize: 26, color: C.sageDk, marginTop: 2, lineHeight: 1 }}>Name your building</div>
              <div style={{ fontFamily: F_TITLE, fontSize: 17, fontWeight: 800, color: C.ink, marginTop: 4 }}>বিল্ডিংয়ের নাম দিন</div>
            </div>

            <Card style={{ padding: "14px 16px", marginBottom: 12 }}>
              <div style={{ fontSize: 11, fontWeight: 700, color: C.muted, marginBottom: 8, letterSpacing: .3, textTransform: "uppercase" }}>বিল্ডিংয়ের নাম ★</div>
              <input
                value={name}
                onChange={e => setName(e.target.value)}
                placeholder="যেমন: করিম মঞ্জিল, House 12"
                style={{
                  border: 0, outline: "none", width: "100%", fontSize: 17,
                  fontFamily: F_TITLE, background: "transparent", color: C.ink,
                  fontWeight: 700, padding: "4px 0", letterSpacing: -.2,
                }}
              />
            </Card>

            <Card style={{ padding: "14px 16px" }}>
              <div style={{ fontSize: 11, fontWeight: 700, color: C.muted, marginBottom: 10, letterSpacing: .3, textTransform: "uppercase" }}>এলাকা ★</div>
              <div style={{ display: "flex", flexWrap: "wrap", gap: 7 }}>
                {AREAS.map(a => (
                  <button key={a} onClick={() => setArea(a)} style={{
                    padding: "8px 14px", borderRadius: 999, border: 0, cursor: "pointer",
                    background: a === area ? C.sage : C.sageBg,
                    color: a === area ? "#fff" : C.sageDk,
                    fontSize: 12.5, fontWeight: 700, fontFamily: F_TITLE,
                  }}>{a}</button>
                ))}
              </div>
            </Card>

            <div style={{ marginTop: 18 }}>
              <Btn full size="lg" onClick={() => setStep(2)} kind={name && area ? "primary" : "soft"}>
                <span style={{ display: "inline-flex", alignItems: "center", gap: 8 }}>পরবর্তী <Icon d={I.arrow} s={16}/></span>
              </Btn>
            </div>
          </div>
        )}

        {step === 2 && (
          <div style={{ padding: "0 22px 24px" }}>
            <div style={{ textAlign: "center", marginBottom: 18 }}>
              <div style={{ fontSize: 50 }}>📍</div>
              <div style={{ fontFamily: F_HAND, fontSize: 26, color: C.sageDk, marginTop: 2, lineHeight: 1 }}>Where is it?</div>
              <div style={{ fontFamily: F_TITLE, fontSize: 17, fontWeight: 800, color: C.ink, marginTop: 4 }}>সম্পূর্ণ ঠিকানা লিখুন</div>
            </div>

            <Card style={{ padding: "14px 16px", marginBottom: 12 }}>
              <div style={{ fontSize: 11, fontWeight: 700, color: C.muted, marginBottom: 8, letterSpacing: .3, textTransform: "uppercase" }}>ঠিকানা ★</div>
              <textarea
                value={address}
                onChange={e => setAddress(e.target.value)}
                placeholder="যেমন: House 12, Road 4, Block C&#10;Mirpur 10, Dhaka 1216"
                rows={3}
                style={{
                  border: 0, outline: "none", width: "100%", fontSize: 14,
                  fontFamily: F_BODY, background: "transparent", color: C.ink,
                  resize: "vertical", lineHeight: 1.5,
                }}
              />
            </Card>
            <Card soft={C.sageBg} style={{ padding: "12px 14px", display: "flex", gap: 10, alignItems: "center", borderRadius: 16, marginBottom: 12 }}>
              <div style={{ fontSize: 20 }}>📬</div>
              <div style={{ fontSize: 12, color: C.sageDk, fontWeight: 600, lineHeight: 1.5 }}>
                <b>এলাকা:</b> {area || "—"} · DMP ফর্মে এই ঠিকানা ব্যবহার হবে
              </div>
            </Card>

            <div style={{ marginTop: 18 }}>
              <Btn full size="lg" onClick={() => setStep(3)} kind={address ? "primary" : "soft"}>
                <span style={{ display: "inline-flex", alignItems: "center", gap: 8 }}>পরবর্তী — ম্যাপ <Icon d={I.arrow} s={16}/></span>
              </Btn>
            </div>
          </div>
        )}

        {step === 3 && (
          <div style={{ padding: "0 22px 24px" }}>
            <div style={{ textAlign: "center", marginBottom: 14 }}>
              <div style={{ fontSize: 50 }}>🗺️</div>
              <div style={{ fontFamily: F_HAND, fontSize: 26, color: C.sageDk, marginTop: 2, lineHeight: 1 }}>Drop a pin (optional)</div>
              <div style={{ fontFamily: F_TITLE, fontSize: 17, fontWeight: 800, color: C.ink, marginTop: 4 }}>মানচিত্রে স্থান চিহ্নিত করুন</div>
              <div style={{ fontSize: 11.5, color: C.muted, marginTop: 6 }}>ঐচ্ছিক · এড়িয়ে গেলেও সমস্যা নেই</div>
            </div>

            {/* mock map */}
            <Card style={{ padding: 0, overflow: "hidden", borderRadius: 20 }}>
              <div
                onClick={() => setPinSet(true)}
                style={{
                  height: 240, position: "relative", cursor: "pointer",
                  background: `
                    linear-gradient(135deg, #e8e4d4 0%, #d8d3c0 100%),
                    repeating-linear-gradient(45deg, transparent, transparent 18px, rgba(255,255,255,.4) 18px, rgba(255,255,255,.4) 19px)
                  `,
                }}
              >
                {/* fake streets */}
                <div style={{ position: "absolute", left: 0, right: 0, top: "30%", height: 14, background: "#f4ede0" }}/>
                <div style={{ position: "absolute", left: 0, right: 0, top: "65%", height: 12, background: "#f4ede0" }}/>
                <div style={{ position: "absolute", top: 0, bottom: 0, left: "25%", width: 13, background: "#f4ede0" }}/>
                <div style={{ position: "absolute", top: 0, bottom: 0, left: "70%", width: 11, background: "#f4ede0" }}/>
                {/* fake blocks */}
                <div style={{ position: "absolute", left: "30%", top: "8%", width: 60, height: 30, background: "#c8c0a8", borderRadius: 2, opacity: .6 }}/>
                <div style={{ position: "absolute", left: "78%", top: "12%", width: 40, height: 25, background: "#c8c0a8", borderRadius: 2, opacity: .6 }}/>
                <div style={{ position: "absolute", left: "8%", top: "42%", width: 50, height: 35, background: "#c8c0a8", borderRadius: 2, opacity: .6 }}/>
                <div style={{ position: "absolute", left: "75%", top: "75%", width: 45, height: 30, background: "#c8c0a8", borderRadius: 2, opacity: .6 }}/>

                {pinSet ? (
                  <div style={{ position: "absolute", left: "48%", top: "42%", transform: "translate(-50%, -100%)" }}>
                    <div style={{ display: "grid", placeItems: "center", filter: "drop-shadow(0 4px 8px rgba(0,0,0,.3))" }}>
                      <svg width="44" height="56" viewBox="0 0 44 56">
                        <path d="M22 0a18 18 0 0 0-18 18c0 13 18 36 18 36s18-23 18-36A18 18 0 0 0 22 0Z" fill={C.rose}/>
                        <circle cx="22" cy="18" r="7" fill="#fff"/>
                      </svg>
                    </div>
                  </div>
                ) : (
                  <div style={{
                    position: "absolute", inset: 0, display: "grid", placeItems: "center",
                    background: "rgba(255,255,255,.4)",
                  }}>
                    <div style={{
                      background: C.card, padding: "12px 18px", borderRadius: 999,
                      fontSize: 13, fontWeight: 700, color: C.sageDk,
                      boxShadow: "0 4px 12px -4px rgba(0,0,0,.2)", fontFamily: F_TITLE,
                    }}>✋ ট্যাপ করে পিন রাখুন</div>
                  </div>
                )}
                <div style={{ position: "absolute", bottom: 8, right: 8, fontSize: 9, color: "rgba(0,0,0,.4)", fontWeight: 600 }}>© OpenStreetMap</div>
              </div>
            </Card>

            {pinSet && (
              <Card soft={C.sageBg} style={{ padding: "12px 14px", marginTop: 12, display: "flex", gap: 10, alignItems: "center", borderRadius: 16 }}>
                <Icon d={I.pin} s={18} c={C.sageDk}/>
                <div style={{ flex: 1 }}>
                  <div style={{ fontSize: 13, color: C.sageDk, fontWeight: 700 }}>পিন রাখা হয়েছে</div>
                  <div style={{ fontSize: 11, color: C.mutedDk, marginTop: 1, fontFamily: "monospace" }}>23.8103°N, 90.4125°E</div>
                </div>
                <button onClick={() => setPinSet(false)} style={{ background: "transparent", border: 0, color: C.muted, fontSize: 12, fontWeight: 600, cursor: "pointer" }}>রিসেট</button>
              </Card>
            )}

            <div style={{ marginTop: 18, display: "grid", gap: 10 }}>
              <Btn full size="lg" kind="primary" onClick={() => go("home")}>
                ✓ বিল্ডিং সেভ করুন
              </Btn>
              {!pinSet && (
                <Btn full kind="soft" onClick={() => go("home")}>পিন ছাড়া এড়িয়ে যান</Btn>
              )}
            </div>
          </div>
        )}
      </Scroll>
    </>
  );
};

// ─── MANAGER HOME ──────────────────────────────────────────────
const ManagerHome = ({ go }) => {
  const [owner, setOwner] = useState(0);
  const owners = [
    { n: "Md. Ibrahim",   units: 14, occ: 11, mrr: "৯৭K", c: C.sage },
    { n: "Tariq Aziz",    units: 38, occ: 35, mrr: "২.৮L", c: C.rose },
    { n: "Sabina Yasmin", units: 31, occ: 28, mrr: "২.১L", c: C.butter },
  ];
  return (
    <>
      <TopBar action={
        <button style={{ background: C.card, border: `1px solid ${C.line}`, width: 40, height: 40, borderRadius: 20, display: "grid", placeItems: "center", cursor: "pointer", position: "relative" }}>
          <Icon d={I.bell} s={18} c={C.ink}/>
          <div style={{ position: "absolute", top: 8, right: 9, width: 8, height: 8, borderRadius: 4, background: C.rose, border: "1.5px solid #fff" }}/>
        </button>
      }/>
      <Scroll>
        <div style={{ padding: "4px 22px 12px" }}>
          <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
            <Chip bg={C.butterBg} fg={C.roseDk}>🏢 Manager</Chip>
          </div>
          <div style={{ fontFamily: F_HAND, fontSize: 24, color: C.sageDk, lineHeight: 1, marginTop: 8 }}>আসসালামু আলাইকুম,</div>
          <div style={{ fontFamily: F_TITLE, fontSize: 22, fontWeight: 800, color: C.ink, letterSpacing: -.5, lineHeight: 1.1, marginTop: 4 }}>আসিফ ভাই 👋</div>
          <div style={{ color: C.muted, fontSize: 12.5, marginTop: 4 }}>৩ মালিক · ৮৩ ইউনিট · ৭৪ ভাড়া হয়েছে</div>
        </div>

        {/* portfolio summary hero */}
        <div style={{ padding: "0 20px 4px" }}>
          <Card soft={`linear-gradient(135deg, ${C.ink} 0%, #3D4A42 100%)`}
                style={{ color: "#fff", borderRadius: 26, padding: "18px 20px", position: "relative", overflow: "hidden" }}>
            <Chip bg="rgba(255,255,255,.18)" fg="#fff">পুরো পোর্টফোলিও</Chip>
            <div style={{ fontFamily: F_HAND, fontSize: 22, marginTop: 8, opacity: .85, lineHeight: 1 }}>Total under management</div>
            <div style={{ fontFamily: F_TITLE, fontSize: 36, fontWeight: 800, letterSpacing: -1, lineHeight: 1, marginTop: 4 }}>৳৫.৯L<span style={{ fontSize: 14, opacity: .7, fontWeight: 600 }}>/mo</span></div>
            <div style={{ marginTop: 10, display: "flex", gap: 14, fontSize: 12 }}>
              <div><b style={{ color: C.butter }}>৭৪</b>/৮৩ অকুপায়েড</div>
              <div style={{ opacity: .35 }}>·</div>
              <div><b style={{ color: C.sage }}>৮৯%</b> আদায়</div>
            </div>
            <div style={{ position: "absolute", right: -20, top: -16, fontSize: 130, opacity: .08 }}>🏢</div>
          </Card>
        </div>

        {/* owner switcher */}
        <div style={{ padding: "16px 20px 4px" }}>
          <div style={{ fontFamily: F_TITLE, fontSize: 14, fontWeight: 800, color: C.ink, marginBottom: 10, paddingLeft: 4 }}>মালিক পোর্টফোলিও 🏢</div>
          <div style={{ display: "flex", gap: 10, overflowX: "auto", paddingBottom: 6, marginLeft: -4, paddingLeft: 4 }}>
            {owners.map((o, i) => (
              <Card key={i} onClick={() => setOwner(i)}
                style={{
                  minWidth: 170, padding: "12px 14px", borderRadius: 18, flexShrink: 0,
                  border: i === owner ? `2px solid ${C.sage}` : `1px solid ${C.line}`,
                }}
              >
                <div style={{ display: "flex", alignItems: "center", gap: 10, marginBottom: 8 }}>
                  <div style={{ width: 34, height: 34, borderRadius: 17, background: o.c, color: "#fff", display: "grid", placeItems: "center", fontWeight: 800, fontSize: 14, fontFamily: F_TITLE }}>{o.n[3]}</div>
                  <div style={{ fontFamily: F_TITLE, fontWeight: 700, fontSize: 13, color: C.ink }}>{o.n}</div>
                </div>
                <div style={{ display: "flex", justifyContent: "space-between", fontSize: 11, color: C.muted }}>
                  <span>{o.occ}/{o.units} ইউনিট</span>
                  <b style={{ color: C.roseDk }}>৳{o.mrr}</b>
                </div>
              </Card>
            ))}
            <Card style={{ minWidth: 100, padding: "12px 14px", borderRadius: 18, flexShrink: 0, display: "grid", placeItems: "center", textAlign: "center", border: `2px dashed ${C.line}` }}>
              <div>
                <div style={{ fontSize: 22, color: C.muted }}>+</div>
                <div style={{ fontSize: 11, color: C.muted, fontWeight: 600, marginTop: 2 }}>মালিক যোগ</div>
              </div>
            </Card>
          </div>
        </div>

        {/* quick actions */}
        <div style={{ padding: "14px 20px 4px" }}>
          <div style={{ fontFamily: F_TITLE, fontSize: 14, fontWeight: 800, color: C.ink, marginBottom: 10, paddingLeft: 4 }}>দ্রুত কাজ — {owners[owner].n}</div>
          <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 10 }}>
            {[
              ["addBuilding","🏢","বিল্ডিং যোগ","Add building",C.sageBg,C.sageDk],
              ["rentReq",   "📤","ভাড়া চান",  "Collect rent",C.roseBg,C.roseDk],
              ["expenses",  "🔧","মেরামত",     "Maintenance", C.butterBg,C.roseDk],
              ["dashboard", "📊","রিপোর্ট",    "Report",      C.sageBg,C.sageDk],
            ].map(([k,e,t,en,bg,fg]) => (
              <Card key={k} onClick={() => go(k)} soft={bg} style={{ padding: "14px 14px", borderRadius: 20 }}>
                <div style={{ fontSize: 26, marginBottom: 6 }}>{e}</div>
                <div style={{ fontFamily: F_TITLE, fontWeight: 700, fontSize: 14, color: fg, lineHeight: 1.2 }}>{t}</div>
                <div style={{ fontSize: 10.5, color: C.mutedDk, marginTop: 2, fontWeight: 600 }}>{en}</div>
              </Card>
            ))}
          </div>
        </div>

        {/* team */}
        <div style={{ padding: "14px 20px 8px" }}>
          <Card style={{ padding: "14px 14px", display: "flex", alignItems: "center", gap: 12, borderRadius: 20 }}>
            <div style={{ width: 44, height: 44, borderRadius: 22, background: C.sageBg, display: "grid", placeItems: "center", fontSize: 20 }}>👥</div>
            <div style={{ flex: 1 }}>
              <div style={{ fontFamily: F_TITLE, fontWeight: 700, fontSize: 14, color: C.ink }}>টিম মেম্বার</div>
              <div style={{ fontSize: 11.5, color: C.muted, marginTop: 1 }}>২ জন সহকারী · ১ accountant</div>
            </div>
            <Btn size="sm" kind="soft">পরিচালনা</Btn>
          </Card>
        </div>

        <div style={{ padding: "10px 20px 24px" }}>
          <Card soft={C.butterBg} style={{ padding: "12px 16px", display: "flex", gap: 14, alignItems: "center", borderRadius: 18 }}>
            <div style={{ fontSize: 32 }}>💼</div>
            <div style={{ flex: 1 }}>
              <div style={{ fontFamily: F_TITLE, fontSize: 13.5, fontWeight: 700, color: C.ink }}>B2B Manager Tier</div>
              <div style={{ fontSize: 11, color: C.muted, marginTop: 1 }}>একীভূত রিপোর্ট · টিম সিট · বার্ষিক বিলিং</div>
            </div>
            <Chip bg={C.sage} fg="#fff">Active</Chip>
          </Card>
        </div>
      </Scroll>
      <BottomNav active="home" go={go}/>
    </>
  );
};

// ─── TENANT HOME ───────────────────────────────────────────────
const TenantHome = ({ go }) => (
  <>
    <TopBar action={
      <button style={{ background: C.card, border: `1px solid ${C.line}`, width: 40, height: 40, borderRadius: 20, display: "grid", placeItems: "center", cursor: "pointer", position: "relative" }}>
        <Icon d={I.bell} s={18} c={C.ink}/>
        <div style={{ position: "absolute", top: 8, right: 9, width: 8, height: 8, borderRadius: 4, background: C.rose, border: "1.5px solid #fff" }}/>
      </button>
    }/>
    <Scroll>
      <div style={{ padding: "4px 22px 12px" }}>
        <Chip bg={C.roseBg} fg={C.roseDk}>👤 Tenant</Chip>
        <div style={{ fontFamily: F_HAND, fontSize: 24, color: C.sageDk, lineHeight: 1, marginTop: 8 }}>আসসালামু আলাইকুম,</div>
        <div style={{ fontFamily: F_TITLE, fontSize: 22, fontWeight: 800, color: C.ink, letterSpacing: -.5, lineHeight: 1.1, marginTop: 4 }}>নাসরিন আক্তার 👋</div>
        <div style={{ color: C.muted, fontSize: 12.5, marginTop: 4 }}>Mirpur 10 · ফ্ল্যাট 4B</div>
      </div>

      {/* pending rent hero */}
      <div style={{ padding: "0 20px 4px" }}>
        <Card
          soft={`linear-gradient(135deg, ${C.rose} 0%, ${C.roseDk} 100%)`}
          style={{ color: "#fff", borderRadius: 26, padding: "20px 22px", position: "relative", overflow: "hidden" }}
        >
          <Chip bg="rgba(255,255,255,.22)" fg="#fff">⏰ এ মাসের ভাড়া</Chip>
          <div style={{ fontFamily: F_TITLE, fontSize: 36, fontWeight: 800, letterSpacing: -1, lineHeight: 1, marginTop: 10 }}>৳২৬,০০০</div>
          <div style={{ fontSize: 12.5, opacity: .9, marginTop: 6 }}>বাকি · মে ২৬২৬ · ৫ মে পর্যন্ত</div>
          <div style={{
            marginTop: 14, background: "rgba(255,255,255,.95)", color: C.roseDk,
            padding: "11px 16px", borderRadius: 999, fontFamily: F_TITLE, fontWeight: 800,
            fontSize: 14, display: "inline-flex", alignItems: "center", gap: 8, cursor: "pointer",
          }}>📥 পেমেন্ট প্রমাণ আপলোড <Icon d={I.arrow} s={16}/></div>
          <div style={{ position: "absolute", right: -8, bottom: -8, fontSize: 110, opacity: .12 }}>💰</div>
        </Card>
      </div>

      {/* lease info */}
      <div style={{ padding: "12px 20px 4px" }}>
        <Card style={{ borderRadius: 20, padding: 14 }}>
          <div style={{ display: "flex", alignItems: "center", gap: 12, marginBottom: 12 }}>
            <div style={{ width: 44, height: 44, borderRadius: 22, background: C.sageBg, display: "grid", placeItems: "center", fontSize: 20 }}>📋</div>
            <div style={{ flex: 1 }}>
              <div style={{ fontFamily: F_TITLE, fontSize: 14, fontWeight: 800, color: C.ink }}>আমার লিজ</div>
              <div style={{ fontSize: 11, color: C.muted, marginTop: 1 }}>মার্চ ২০২৬ — চলমান</div>
            </div>
            <Btn size="sm" kind="soft">দেখুন</Btn>
          </div>
          <div style={{ paddingTop: 10, borderTop: `1px solid ${C.line}`, display: "grid", gridTemplateColumns: "1fr 1fr", gap: 8, fontSize: 12 }}>
            <div><span style={{ color: C.muted }}>মালিক:</span> <b style={{ color: C.ink }}>আব্দুল করিম</b></div>
            <div><span style={{ color: C.muted }}>অগ্রিম:</span> <b style={{ color: C.ink }}>৳৫২,০০০</b></div>
          </div>
        </Card>
      </div>

      {/* quick actions */}
      <div style={{ padding: "14px 20px 4px" }}>
        <div style={{ fontFamily: F_TITLE, fontSize: 14, fontWeight: 800, color: C.ink, marginBottom: 10, paddingLeft: 4 }}>দ্রুত কাজ ✨</div>
        <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 10 }}>
          {[
            ["🔧","মেরামত চাই",  "Request fix",   C.butterBg, C.roseDk],
            ["📃","রসিদ দেখুন",  "Receipts",      C.sageBg,   C.sageDk],
            ["💬","মালিকের সাথে","Chat owner",    C.roseBg,   C.roseDk],
            ["⭐","রিভিউ দিন",  "Review",         C.sageBg,   C.sageDk],
          ].map(([e,t,en,bg,fg]) => (
            <Card key={t} soft={bg} style={{ padding: "14px 14px", borderRadius: 20 }}>
              <div style={{ fontSize: 26, marginBottom: 6 }}>{e}</div>
              <div style={{ fontFamily: F_TITLE, fontWeight: 700, fontSize: 14, color: fg, lineHeight: 1.2 }}>{t}</div>
              <div style={{ fontSize: 10.5, color: C.mutedDk, marginTop: 2, fontWeight: 600 }}>{en}</div>
            </Card>
          ))}
        </div>
      </div>

      {/* recent receipts */}
      <div style={{ padding: "14px 20px 4px" }}>
        <div style={{ fontFamily: F_TITLE, fontSize: 14, fontWeight: 800, color: C.ink, marginBottom: 10, paddingLeft: 4 }}>সাম্প্রতিক রসিদ 📃</div>
        <Card style={{ padding: 0, borderRadius: 20 }}>
          {[
            ["এপ্রিল ২০২৬", "৳২৬,০০০", "✓ পরিশোধিত", C.sage],
            ["মার্চ ২০২৬",   "৳২৬,০০০", "✓ পরিশোধিত", C.sage],
            ["ফেব ২০২৬",    "৳২৬,০০০", "✓ পরিশোধিত", C.sage],
          ].map(([m,a,s,c],i) => (
            <div key={i} style={{
              padding: "12px 14px", display: "flex", alignItems: "center", gap: 12,
              borderBottom: i < 2 ? `1px solid ${C.line}` : 0,
            }}>
              <div style={{ width: 36, height: 36, borderRadius: 18, background: C.sageBg, display: "grid", placeItems: "center", fontSize: 16 }}>📃</div>
              <div style={{ flex: 1 }}>
                <div style={{ fontFamily: F_TITLE, fontWeight: 700, fontSize: 13.5, color: C.ink }}>{m}</div>
                <div style={{ fontSize: 11, color: c, marginTop: 1, fontWeight: 700 }}>{s}</div>
              </div>
              <div style={{ fontFamily: F_TITLE, fontWeight: 800, color: C.ink, fontSize: 14 }}>{a}</div>
            </div>
          ))}
        </Card>
      </div>

      {/* good tenant record */}
      <div style={{ padding: "12px 20px 24px" }}>
        <Card soft={C.sageBg} style={{ padding: "14px 16px", display: "flex", gap: 14, alignItems: "center", borderRadius: 18 }}>
          <div style={{ fontSize: 36 }}>🌟</div>
          <div style={{ flex: 1 }}>
            <div style={{ fontFamily: F_HAND, fontSize: 22, color: C.sageDk, lineHeight: .9 }}>You're a star!</div>
            <div style={{ fontFamily: F_TITLE, fontSize: 13, fontWeight: 700, color: C.ink, marginTop: 2 }}>৩ মাস সময়মতো ভাড়া</div>
            <div style={{ fontSize: 11, color: C.muted, marginTop: 1 }}>পরের বাসায় ভালো রেকর্ড পাবেন</div>
          </div>
        </Card>
      </div>
    </Scroll>
    <BottomNav active="home" go={go}/>
  </>
);

// ─── ROUTER ─────────────────────────────────────────────────────
export default function KhatirApp() {
  const [screen, setScreen] = useState("intro");
  const [role, setRole] = useState("landlord");

  const goHome = () => {
    setScreen(role === "manager" ? "managerHome" : role === "tenant" ? "tenantHome" : "home");
  };
  const go = (s) => {
    if (s === "home") goHome();
    else setScreen(s);
  };

  const screens = {
    intro:        <Intro       go={setScreen}/>,
    login:        <Login       go={(s) => s === "home" ? setScreen("roleChooser") : setScreen(s)}/>,
    roleChooser:  <RoleChooser go={setScreen} setRole={setRole}/>,
    home:         <Home        go={go}/>,
    managerHome:  <ManagerHome go={go}/>,
    tenantHome:   <TenantHome  go={go}/>,
    addBuilding:  <AddBuilding go={go}/>,
    addTenant:    <AddTenant   go={go}/>,
    ocr:          <OCR         go={go}/>,
    voice:        <Voice       go={go}/>,
    dmp:          <DMP         go={go}/>,
    verify:       <Verify      go={go}/>,
    rentReq:      <RentReq     go={go}/>,
    expenses:     <Expenses    go={go}/>,
    dashboard:    <Dashboard   go={go}/>,
    more:         <Home        go={go}/>,
  };
  return (
    <Phone>
      <style>{`
        @import url('https://fonts.googleapis.com/css2?family=Caveat:wght@500;600;700&family=Plus+Jakarta+Sans:wght@500;600;700;800&family=Hind+Siliguri:wght@400;600;700&display=swap');
        * { box-sizing: border-box; -webkit-tap-highlight-color: transparent; }
        button:active { transform: scale(.97); }
      `}</style>
      <div style={{ display: "flex", flexDirection: "column", height: "100%" }}>
        {screens[screen] || screens.home}
      </div>
    </Phone>
  );
}
