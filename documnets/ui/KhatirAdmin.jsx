import React, { useState } from "react";

// ═══════════════════════════════════════════════════════════════
//   Khatir Admin Portal · ops.khatir.com.bd
//   Desktop-first · English · Internal staff only
//   Final v1.0 — production-ready reference UI
// ═══════════════════════════════════════════════════════════════

const C = {
  // admin uses a calmer, more "operations" palette — derived from brand
  bg:       "#F7F5F0",
  panel:    "#FFFFFF",
  ink:      "#1F2A24",
  ink2:     "#3D4A42",
  muted:    "#7A8278",
  line:     "#E8E2D4",
  lineDk:   "#D5CCB8",
  sage:     "#7BA084",
  sageDk:   "#5C8067",
  sageBg:   "#E8F0EA",
  rose:     "#E89B8B",
  roseDk:   "#C9755F",
  roseBg:   "#FBE9E3",
  butter:   "#F4D58D",
  butterBg: "#FBF1D8",
  danger:   "#D14D3B",
  dangerBg: "#FBE5E1",
  cream:    "#FBF6EE",
};

const F_TITLE = `'Plus Jakarta Sans', -apple-system, sans-serif`;
const F_BODY  = `'Inter', -apple-system, sans-serif`;
const F_MONO  = `'JetBrains Mono', 'Menlo', monospace`;

// ─── ICONS ──────────────────────────────────────────────────────
const I = {
  dash:    <><rect x="3" y="3" width="7" height="9"/><rect x="14" y="3" width="7" height="5"/><rect x="14" y="12" width="7" height="9"/><rect x="3" y="16" width="7" height="5"/></>,
  users:   <><circle cx="9" cy="8" r="4"/><path d="M2 21a7 7 0 0 1 14 0"/><circle cx="17" cy="9" r="3"/><path d="M22 20a5 5 0 0 0-6-4.9"/></>,
  money:   <><circle cx="12" cy="12" r="9"/><path d="M14 9.5c-.6-.9-1.8-1.5-3-1.5-2 0-3 1-3 2.2 0 3.4 6 1.7 6 5 0 1.3-1.2 2.3-3 2.3-1.5 0-2.8-.7-3.4-1.7M12 6v2m0 8v2"/></>,
  flag:    <><path d="M4 21V4M4 4h12l-2 4 2 4H4"/></>,
  shield:  <><path d="M12 3l8 3v6c0 5-3.5 7.5-8 9-4.5-1.5-8-4-8-9V6Z"/></>,
  cog:     <><circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.7 1.7 0 0 0 .3 1.8l.1.1a2 2 0 1 1-2.8 2.8l-.1-.1a1.7 1.7 0 0 0-1.8-.3 1.7 1.7 0 0 0-1 1.5V21a2 2 0 1 1-4 0v-.1A1.7 1.7 0 0 0 9 19.4a1.7 1.7 0 0 0-1.8.3l-.1.1a2 2 0 1 1-2.8-2.8l.1-.1a1.7 1.7 0 0 0 .3-1.8 1.7 1.7 0 0 0-1.5-1H3a2 2 0 1 1 0-4h.1A1.7 1.7 0 0 0 4.6 9a1.7 1.7 0 0 0-.3-1.8l-.1-.1a2 2 0 1 1 2.8-2.8l.1.1A1.7 1.7 0 0 0 9 4.6 1.7 1.7 0 0 0 10 3.1V3a2 2 0 1 1 4 0v.1a1.7 1.7 0 0 0 1 1.5 1.7 1.7 0 0 0 1.8-.3l.1-.1a2 2 0 1 1 2.8 2.8l-.1.1a1.7 1.7 0 0 0-.3 1.8c.2.5.7.9 1.3 1H21a2 2 0 1 1 0 4h-.1c-.6 0-1.1.3-1.5 1Z"/></>,
  ticket:  <><path d="M3 8v8a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2V8a2 2 0 0 0-2-2H5a2 2 0 0 0-2 2Z"/><path d="M8 6v12"/></>,
  chart:   <><path d="M4 19V5M4 19h16"/><rect x="7" y="11" width="3" height="6"/><rect x="12" y="8" width="3" height="9"/><rect x="17" y="13" width="3" height="4"/></>,
  lock:    <><rect x="4" y="11" width="16" height="10" rx="2"/><path d="M8 11V7a4 4 0 0 1 8 0v4"/></>,
  search:  <><circle cx="11" cy="11" r="7"/><path d="m21 21-4.3-4.3"/></>,
  bell:    <><path d="M6 8a6 6 0 0 1 12 0c0 7 3 9 3 9H3s3-2 3-9"/><path d="M10 21a2 2 0 0 0 4 0"/></>,
  alert:   <><circle cx="12" cy="12" r="10"/><path d="M12 8v4M12 16h.01"/></>,
  check:   <path d="M20 6 9 17l-5-5"/>,
  x:       <path d="M18 6 6 18M6 6l12 12"/>,
  arrow:   <path d="M5 12h14M13 5l7 7-7 7"/>,
  up:      <path d="m6 9 6-6 6 6"/>,
  down:    <path d="m6 15 6 6 6-6"/>,
  edit:    <><path d="m12 20 9-9-3-3-9 9v3h3Z"/><path d="m14 7 4 4"/></>,
  trash:   <><path d="M3 6h18M8 6V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2M6 6v14a2 2 0 0 0 2 2h8a2 2 0 0 0 2-2V6"/></>,
  filter:  <path d="M3 6h18M6 12h12M10 18h4"/>,
  download:<><path d="M12 3v12M7 10l5 5 5-5M3 21h18"/></>,
  power:   <><path d="M12 2v10"/><path d="M18.4 6.6a9 9 0 1 1-12.8 0"/></>,
  eye:     <><path d="M2 12s3.5-7 10-7 10 7 10 7-3.5 7-10 7-10-7-10-7Z"/><circle cx="12" cy="12" r="3"/></>,
  copy:    <><rect x="9" y="9" width="13" height="13" rx="2"/><path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"/></>,
  ai:      <><path d="M12 2v4M12 18v4M4.93 4.93l2.83 2.83M16.24 16.24l2.83 2.83M2 12h4M18 12h4M4.93 19.07l2.83-2.83M16.24 7.76l2.83-2.83"/><circle cx="12" cy="12" r="4"/></>,
  send:    <><path d="M22 2 11 13M22 2l-7 20-4-9-9-4Z"/></>,
  mic:     <><rect x="9" y="3" width="6" height="11" rx="3"/><path d="M5 11a7 7 0 0 0 14 0M12 18v3"/></>,
  zap:     <path d="M13 2 3 14h9l-1 8 10-12h-9l1-8Z"/>,
  key:     <><circle cx="8" cy="15" r="4"/><path d="m10.5 12.5 9-9M16 8l3 3M14 10l3 3"/></>,
};
const Icon = ({ d, s = 18, c = "currentColor", sw = 1.8 }) => (
  <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth={sw} strokeLinecap="round" strokeLinejoin="round">{d}</svg>
);

// ─── SHELL ─────────────────────────────────────────────────────
const Shell = ({ children }) => (
  <div style={{
    minHeight: "100vh", background: C.bg, fontFamily: F_BODY, color: C.ink,
    fontSize: 14,
  }}>
    {children}
  </div>
);

const NAV = [
  { k: "dashboard", l: "Dashboard",   i: I.dash },
  { k: "users",     l: "Users",       i: I.users },
  { k: "pricing",   l: "Pricing",     i: I.money, badge: "12" },
  { k: "features",  l: "Features",    i: I.flag },
  { k: "kill",      l: "Kill-switch", i: I.power, danger: true },
  { k: "notify",    l: "Notifications", i: I.send, badge: "2" },
  { k: "ai",        l: "AI providers", i: I.ai },
  { k: "compliance",l: "Compliance",  i: I.shield },
  { k: "config",    l: "System",      i: I.cog },
  { k: "support",   l: "Support",     i: I.ticket, badge: "3" },
  { k: "analytics", l: "Analytics",   i: I.chart },
  { k: "admins",    l: "Admin users", i: I.lock },
];

const Sidebar = ({ active, go }) => (
  <aside style={{
    width: 240, background: C.panel, borderRight: `1px solid ${C.line}`,
    padding: "22px 14px", display: "flex", flexDirection: "column", gap: 4,
    position: "sticky", top: 0, height: "100vh", overflowY: "auto", flexShrink: 0,
  }}>
    {/* Logo */}
    <div style={{ display: "flex", alignItems: "center", gap: 10, padding: "0 8px 18px", borderBottom: `1px solid ${C.line}`, marginBottom: 14 }}>
      <div style={{
        width: 34, height: 34, borderRadius: 10,
        background: `linear-gradient(135deg, ${C.sage}, ${C.sageDk})`,
        display: "grid", placeItems: "center",
        boxShadow: `0 4px 10px -3px ${C.sageDk}`,
      }}>
        <span style={{ color: "#fff", fontFamily: "'Noto Sans Bengali', 'Hind Siliguri', sans-serif", fontSize: 22, fontWeight: 700, lineHeight: 1, marginTop: -2 }}>খ</span>
      </div>
      <div>
        <div style={{ fontFamily: F_TITLE, fontSize: 15, fontWeight: 800, letterSpacing: -.3, lineHeight: 1 }}>Khatir</div>
        <div style={{ fontSize: 9.5, color: C.muted, marginTop: 3, letterSpacing: .5, textTransform: "uppercase", fontWeight: 700 }}>Admin · ops</div>
      </div>
    </div>

    {NAV.map(n => {
      const isActive = n.k === active;
      return (
        <button key={n.k} onClick={() => go(n.k)} style={{
          background: isActive ? (n.danger ? C.dangerBg : C.sageBg) : "transparent",
          color: isActive ? (n.danger ? C.danger : C.sageDk) : C.ink2,
          border: 0, borderRadius: 10, padding: "10px 12px",
          display: "flex", alignItems: "center", gap: 11,
          fontSize: 13.5, fontWeight: isActive ? 700 : 500, cursor: "pointer",
          textAlign: "left", width: "100%", fontFamily: F_BODY,
          transition: "background .12s",
        }}>
          <Icon d={n.i} s={17} c={isActive ? (n.danger ? C.danger : C.sageDk) : C.muted} sw={isActive ? 2 : 1.7}/>
          <span style={{ flex: 1 }}>{n.l}</span>
          {n.badge && (
            <span style={{
              background: n.danger ? C.danger : C.rose, color: "#fff",
              fontSize: 10, fontWeight: 700, padding: "2px 7px", borderRadius: 999, minWidth: 18, textAlign: "center",
            }}>{n.badge}</span>
          )}
        </button>
      );
    })}

    {/* Admin profile pill at bottom */}
    <div style={{ marginTop: "auto", paddingTop: 16, borderTop: `1px solid ${C.line}` }}>
      <div style={{ display: "flex", alignItems: "center", gap: 10, padding: "8px 8px" }}>
        <div style={{
          width: 32, height: 32, borderRadius: 16, background: C.ink, color: "#fff",
          display: "grid", placeItems: "center", fontSize: 13, fontWeight: 700,
        }}>N</div>
        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{ fontSize: 12.5, fontWeight: 700, color: C.ink }}>Nuhin · Founder</div>
          <div style={{ fontSize: 10.5, color: C.muted, marginTop: 1, display: "flex", alignItems: "center", gap: 4 }}>
            <span style={{ width: 6, height: 6, borderRadius: 3, background: C.sage }}/> Super Admin
          </div>
        </div>
      </div>
    </div>
  </aside>
);

const TopBar = ({ title, subtitle, action }) => (
  <header style={{
    background: C.panel, borderBottom: `1px solid ${C.line}`,
    padding: "16px 28px", display: "flex", alignItems: "center", gap: 16,
    position: "sticky", top: 0, zIndex: 5,
  }}>
    <div style={{ flex: 1 }}>
      <h1 style={{ fontFamily: F_TITLE, fontSize: 19, fontWeight: 800, color: C.ink, margin: 0, letterSpacing: -.3, lineHeight: 1.2 }}>{title}</h1>
      {subtitle && <div style={{ fontSize: 12.5, color: C.muted, marginTop: 3 }}>{subtitle}</div>}
    </div>
    {action}
    <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
      <button style={iconBtn}><Icon d={I.search} s={17} c={C.muted}/></button>
      <button style={{ ...iconBtn, position: "relative" }}>
        <Icon d={I.bell} s={17} c={C.muted}/>
        <span style={{ position: "absolute", top: 8, right: 8, width: 8, height: 8, borderRadius: 4, background: C.danger, border: "1.5px solid #fff" }}/>
      </button>
    </div>
  </header>
);

const Content = ({ children }) => (
  <main style={{ padding: 28, maxWidth: 1400 }}>{children}</main>
);

const Card = ({ children, style, pad = 22 }) => (
  <div style={{
    background: C.panel, borderRadius: 14, padding: pad,
    border: `1px solid ${C.line}`,
    boxShadow: "0 1px 2px rgba(60,40,30,.04)",
    ...style,
  }}>{children}</div>
);

const Btn = ({ children, onClick, kind = "primary", size = "md", style, disabled }) => {
  const variants = {
    primary: { background: C.ink, color: "#fff", border: 0 },
    sage:    { background: C.sage, color: "#fff", border: 0 },
    danger:  { background: C.danger, color: "#fff", border: 0 },
    ghost:   { background: "transparent", color: C.ink, border: `1px solid ${C.lineDk}` },
    soft:    { background: C.sageBg, color: C.sageDk, border: 0 },
    softDanger:{ background: C.dangerBg, color: C.danger, border: 0 },
  };
  const sizes = {
    sm: { padding: "6px 12px", fontSize: 12 },
    md: { padding: "9px 16px", fontSize: 13 },
    lg: { padding: "11px 20px", fontSize: 14 },
  };
  return (
    <button onClick={onClick} disabled={disabled} style={{
      ...variants[kind], ...sizes[size],
      borderRadius: 8, fontFamily: F_TITLE, fontWeight: 600,
      cursor: disabled ? "not-allowed" : "pointer", opacity: disabled ? .5 : 1,
      display: "inline-flex", alignItems: "center", gap: 6,
      ...style,
    }}>{children}</button>
  );
};

const iconBtn = {
  background: "transparent", border: `1px solid ${C.line}`,
  width: 34, height: 34, borderRadius: 8, display: "grid", placeItems: "center",
  cursor: "pointer", position: "relative",
};

const Chip = ({ children, bg = C.sageBg, fg = C.sageDk, style }) => (
  <span style={{
    background: bg, color: fg, fontSize: 11, fontWeight: 600,
    padding: "3px 9px", borderRadius: 6, display: "inline-flex", alignItems: "center", gap: 4,
    ...style,
  }}>{children}</span>
);

const Toggle = ({ on, onChange, color = C.sage }) => (
  <button onClick={() => onChange(!on)} style={{
    width: 38, height: 22, borderRadius: 11, border: 0, padding: 0,
    background: on ? color : C.lineDk, position: "relative", cursor: "pointer",
    transition: "background .15s",
  }}>
    <div style={{
      width: 18, height: 18, borderRadius: 9, background: "#fff",
      position: "absolute", top: 2, left: on ? 18 : 2, transition: "left .15s",
      boxShadow: "0 1px 3px rgba(0,0,0,.2)",
    }}/>
  </button>
);

// ─── DASHBOARD ─────────────────────────────────────────────────
const Dashboard = () => (
  <Content>
    {/* KPI tiles */}
    <div style={{ display: "grid", gridTemplateColumns: "repeat(4, 1fr)", gap: 14, marginBottom: 22 }}>
      {[
        { l: "Total accounts",   v: "4,832",     d: "+127 this week",  c: C.sage,   bg: C.sageBg,   up: true },
        { l: "Paying landlords", v: "312",       d: "+18 this week",   c: C.sageDk, bg: C.sageBg,   up: true },
        { l: "MRR",              v: "৳1.42L",    d: "+8.2% vs last",   c: C.roseDk, bg: C.roseBg,   up: true },
        { l: "Churn (30d)",      v: "4.1%",      d: "-0.6% vs last",   c: C.sageDk, bg: C.sageBg,   up: true },
      ].map((k, i) => (
        <Card key={i}>
          <div style={{ fontSize: 11.5, color: C.muted, fontWeight: 600, textTransform: "uppercase", letterSpacing: .5 }}>{k.l}</div>
          <div style={{ fontFamily: F_TITLE, fontSize: 28, fontWeight: 800, color: C.ink, marginTop: 8, letterSpacing: -.5, lineHeight: 1 }}>{k.v}</div>
          <div style={{ marginTop: 10, display: "flex", alignItems: "center", gap: 6 }}>
            <Chip bg={k.bg} fg={k.c}>
              <Icon d={k.up ? I.up : I.down} s={11} c={k.c} sw={2.5}/>{k.d}
            </Chip>
          </div>
        </Card>
      ))}
    </div>

    <div style={{ display: "grid", gridTemplateColumns: "2fr 1fr", gap: 14 }}>
      {/* Activity feed */}
      <Card pad={0}>
        <div style={{ padding: "18px 22px", borderBottom: `1px solid ${C.line}`, display: "flex", alignItems: "center", justifyContent: "space-between" }}>
          <div>
            <div style={{ fontFamily: F_TITLE, fontSize: 14.5, fontWeight: 700, color: C.ink }}>Recent activity</div>
            <div style={{ fontSize: 11.5, color: C.muted, marginTop: 2 }}>Platform events · last 24 hours</div>
          </div>
          <Btn kind="ghost" size="sm">View all</Btn>
        </div>
        <div>
          {[
            { t: "2 min ago",  a: "Subscription", who: "Md. Ibrahim",   what: "upgraded to Bundle 20 · ৳599/mo", c: C.sage },
            { t: "14 min ago", a: "New signup",   who: "Salim Ahmed",   what: "landlord · Mirpur · via referral", c: C.sageDk },
            { t: "32 min ago", a: "Refund",       who: "Karim Sheikh",  what: "৳299 refunded · disputed charge", c: C.rose },
            { t: "1 hr ago",   a: "Kill-switch",  who: "system",        what: "warnings feature toggled OFF by Compliance", c: C.danger },
            { t: "2 hr ago",   a: "Subscription", who: "Rashid Khan",   what: "downgraded to Free · tenant count = 2", c: C.muted },
            { t: "3 hr ago",   a: "Pricing",      who: "Nuhin",         what: "edited Unlimited Annual: ৳999 → ৳949/mo", c: C.sageDk },
            { t: "5 hr ago",   a: "New signup",   who: "Fatima Begum",  what: "landlord · Dhanmondi · via Facebook", c: C.sageDk },
          ].map((e, i) => (
            <div key={i} style={{
              padding: "13px 22px", display: "flex", alignItems: "center", gap: 14,
              borderBottom: i < 6 ? `1px solid ${C.line}` : 0,
            }}>
              <div style={{ width: 8, height: 8, borderRadius: 4, background: e.c, flexShrink: 0 }}/>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ fontSize: 13, color: C.ink }}>
                  <span style={{ fontWeight: 700 }}>{e.a}</span>
                  <span style={{ color: C.muted }}> · </span>
                  <span style={{ fontWeight: 600 }}>{e.who}</span>
                  <span style={{ color: C.ink2 }}> {e.what}</span>
                </div>
              </div>
              <div style={{ fontSize: 11.5, color: C.muted, flexShrink: 0, fontFamily: F_MONO }}>{e.t}</div>
            </div>
          ))}
        </div>
      </Card>

      {/* Side column */}
      <div style={{ display: "flex", flexDirection: "column", gap: 14 }}>
        <Card>
          <div style={{ fontFamily: F_TITLE, fontSize: 14, fontWeight: 700, color: C.ink, marginBottom: 12 }}>System health</div>
          {[
            ["API uptime",          "99.94%", C.sage],
            ["OCR success",         "97.2%",  C.sage],
            ["WhatsApp delivery",   "94.8%",  C.sage],
            ["EC API",              "OFFLINE", C.danger],
          ].map(([l, v, c], i) => (
            <div key={i} style={{ display: "flex", justifyContent: "space-between", alignItems: "center", padding: "8px 0", borderBottom: i < 3 ? `1px solid ${C.line}` : 0 }}>
              <span style={{ fontSize: 13, color: C.ink2 }}>{l}</span>
              <span style={{ fontFamily: F_MONO, fontSize: 12.5, fontWeight: 700, color: c }}>{v}</span>
            </div>
          ))}
        </Card>

        <Card style={{ background: C.dangerBg, border: `1px solid ${C.danger}33` }}>
          <div style={{ display: "flex", alignItems: "center", gap: 8, marginBottom: 8 }}>
            <Icon d={I.alert} s={16} c={C.danger}/>
            <div style={{ fontFamily: F_TITLE, fontSize: 13, fontWeight: 700, color: C.danger }}>Needs attention</div>
          </div>
          <div style={{ fontSize: 12.5, color: C.ink2, lineHeight: 1.5 }}>
            EC NID API endpoint returning 503 since 14:22. Verifications failing for ~8 users. Falling back to OCR-only.
          </div>
          <Btn kind="softDanger" size="sm" style={{ marginTop: 10 }}>Investigate →</Btn>
        </Card>
      </div>
    </div>
  </Content>
);

// ─── PRICING ───────────────────────────────────────────────────
const Pricing = () => {
  const [tiers, setTiers] = useState([
    { key: "free",              labelEn: "Free",                labelBn: "ফ্রি",                tmin: 1, tmax: 2,    monthly: 0,    annual: null, verif: false, credits: 0,  active: true,  affected: 3122 },
    { key: "per_tenant",        labelEn: "Per-tenant",          labelBn: "প্রতি ভাড়াটিয়া",     tmin: 3, tmax: 10,   monthly: 50,   annual: null, verif: true,  credits: 1,  active: true,  affected: 487 },
    { key: "bundle_20",         labelEn: "Bundle 20",           labelBn: "বান্ডেল ২০",           tmin: 11,tmax: 20,   monthly: 599,  annual: null, verif: true,  credits: 8,  active: true,  affected: 142 },
    { key: "bundle_40",         labelEn: "Bundle 40",           labelBn: "বান্ডেল ৪০",           tmin: 21,tmax: 40,   monthly: 899,  annual: null, verif: true,  credits: 20, active: true,  affected: 71 },
    { key: "unlimited_monthly", labelEn: "Unlimited Monthly",   labelBn: "অনিয়মিত মাসিক",       tmin: 1, tmax: null, monthly: 1299, annual: null, verif: true,  credits: 50, active: true,  affected: 38 },
    { key: "unlimited_annual",  labelEn: "Unlimited Annual",    labelBn: "অনিয়মিত বার্ষিক",    tmin: 1, tmax: null, monthly: 999,  annual: 11988,verif: true,  credits: 60, active: true,  affected: 22 },
  ]);
  const [edit, setEdit] = useState(null);
  const [draft, setDraft] = useState(null);

  const startEdit = (i) => { setEdit(i); setDraft({ ...tiers[i] }); };
  const cancelEdit = () => { setEdit(null); setDraft(null); };
  const save = () => {
    const next = [...tiers]; next[edit] = draft;
    setTiers(next); setEdit(null); setDraft(null);
  };

  return (
    <Content>
      <Card style={{ marginBottom: 18, background: C.sageBg, border: `1px solid ${C.sage}44` }}>
        <div style={{ display: "flex", alignItems: "flex-start", gap: 12 }}>
          <Icon d={I.shield} s={20} c={C.sageDk}/>
          <div style={{ flex: 1 }}>
            <div style={{ fontFamily: F_TITLE, fontWeight: 700, fontSize: 13.5, color: C.sageDk }}>Pricing is live-configurable</div>
            <div style={{ fontSize: 12.5, color: C.ink2, marginTop: 4, lineHeight: 1.5 }}>
              Every tier breakpoint and price below can be changed without a code deploy. Changes take effect within 60 seconds and are fully audit-logged with before/after diff. Affected user counts shown for impact assessment.
            </div>
          </div>
        </div>
      </Card>

      <Card pad={0}>
        <div style={{ padding: "16px 22px", borderBottom: `1px solid ${C.line}`, display: "flex", justifyContent: "space-between", alignItems: "center" }}>
          <div>
            <div style={{ fontFamily: F_TITLE, fontSize: 15, fontWeight: 700 }}>Pricing tiers</div>
            <div style={{ fontSize: 11.5, color: C.muted, marginTop: 2 }}>6 active · last changed 3 hours ago by Nuhin</div>
          </div>
          <Btn kind="primary" size="sm">+ New tier</Btn>
        </div>

        <table style={{ width: "100%", borderCollapse: "collapse", fontSize: 13 }}>
          <thead>
            <tr style={{ background: C.bg }}>
              {["Tier","Tenants","Monthly","Annual","Verification","Active users","",""].map((h, i) => (
                <th key={i} style={{ padding: "10px 16px", textAlign: i > 1 && i < 5 ? "right" : "left", fontSize: 11, fontWeight: 700, color: C.muted, textTransform: "uppercase", letterSpacing: .4, borderBottom: `1px solid ${C.line}` }}>{h}</th>
              ))}
            </tr>
          </thead>
          <tbody>
            {tiers.map((t, i) => (
              <tr key={i} style={{ borderBottom: i < tiers.length - 1 ? `1px solid ${C.line}` : 0 }}>
                <td style={{ padding: "14px 16px" }}>
                  <div style={{ fontFamily: F_TITLE, fontWeight: 700, fontSize: 13.5, color: C.ink }}>{t.labelEn}</div>
                  <div style={{ fontSize: 11, color: C.muted, marginTop: 2 }}>{t.labelBn} · <span style={{ fontFamily: F_MONO }}>{t.key}</span></div>
                </td>
                <td style={{ padding: "14px 16px" }}>
                  <span style={{ fontFamily: F_MONO, fontSize: 12.5, color: C.ink2 }}>
                    {t.tmin}–{t.tmax || "∞"}
                  </span>
                </td>
                <td style={{ padding: "14px 16px", textAlign: "right", fontFamily: F_MONO, fontWeight: 700, color: C.ink }}>
                  {t.monthly === 0 ? <span style={{ color: C.sage }}>FREE</span> : `৳${t.monthly}`}
                </td>
                <td style={{ padding: "14px 16px", textAlign: "right", fontFamily: F_MONO, color: C.muted, fontSize: 12.5 }}>
                  {t.annual ? `৳${t.annual.toLocaleString()}` : "—"}
                </td>
                <td style={{ padding: "14px 16px", textAlign: "right" }}>
                  {t.verif
                    ? <Chip bg={C.sageBg} fg={C.sageDk}><Icon d={I.check} s={10} sw={3}/>{t.credits} credits</Chip>
                    : <Chip bg={C.lineDk + "44"} fg={C.muted}>None</Chip>
                  }
                </td>
                <td style={{ padding: "14px 16px", textAlign: "right", fontFamily: F_MONO, fontSize: 13, color: C.ink2 }}>
                  {t.affected.toLocaleString()}
                </td>
                <td style={{ padding: "14px 16px" }}>
                  <Toggle on={t.active} onChange={() => {}} />
                </td>
                <td style={{ padding: "14px 16px", textAlign: "right" }}>
                  <button onClick={() => startEdit(i)} style={{ ...iconBtn, width: 30, height: 30 }}>
                    <Icon d={I.edit} s={15} c={C.muted}/>
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </Card>

      {/* Edit modal */}
      {edit !== null && draft && (
        <div style={{
          position: "fixed", inset: 0, background: "rgba(20,15,10,.4)",
          display: "grid", placeItems: "center", zIndex: 100, padding: 20,
        }}>
          <div style={{
            background: C.panel, borderRadius: 16, width: "100%", maxWidth: 580,
            maxHeight: "90vh", overflow: "auto",
            boxShadow: "0 30px 60px -20px rgba(0,0,0,.4)",
          }}>
            <div style={{ padding: "18px 24px", borderBottom: `1px solid ${C.line}`, display: "flex", justifyContent: "space-between", alignItems: "center" }}>
              <div>
                <div style={{ fontFamily: F_TITLE, fontSize: 16, fontWeight: 800 }}>Edit tier · {draft.labelEn}</div>
                <div style={{ fontSize: 11.5, color: C.muted, marginTop: 2, fontFamily: F_MONO }}>{draft.key}</div>
              </div>
              <button onClick={cancelEdit} style={iconBtn}><Icon d={I.x} s={16} c={C.muted}/></button>
            </div>

            <div style={{ padding: 24, display: "grid", gap: 16 }}>
              <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 14 }}>
                <Field l="Label (EN)" v={draft.labelEn} onChange={v => setDraft({...draft, labelEn: v})}/>
                <Field l="Label (BN)" v={draft.labelBn} onChange={v => setDraft({...draft, labelBn: v})}/>
                <Field l="Min tenants" v={draft.tmin} type="number" onChange={v => setDraft({...draft, tmin: +v})}/>
                <Field l="Max tenants" v={draft.tmax ?? ""} placeholder="∞ leave blank" type="number" onChange={v => setDraft({...draft, tmax: v ? +v : null})}/>
                <Field l="Monthly (BDT)" v={draft.monthly} type="number" onChange={v => setDraft({...draft, monthly: +v})}/>
                <Field l="Annual (BDT)" v={draft.annual ?? ""} placeholder="leave blank if N/A" type="number" onChange={v => setDraft({...draft, annual: v ? +v : null})}/>
                <Field l="Credits/mo" v={draft.credits} type="number" onChange={v => setDraft({...draft, credits: +v})}/>
                <div>
                  <label style={lbl}>Includes verification</label>
                  <div style={{ marginTop: 10, display: "flex", alignItems: "center", gap: 10 }}>
                    <Toggle on={draft.verif} onChange={v => setDraft({...draft, verif: v})}/>
                    <span style={{ fontSize: 13, color: C.ink2 }}>{draft.verif ? "Yes" : "No"}</span>
                  </div>
                </div>
              </div>

              {/* live impact */}
              <div style={{ padding: 14, background: C.butterBg, borderRadius: 10, border: `1px solid ${C.butter}88` }}>
                <div style={{ display: "flex", alignItems: "center", gap: 8, marginBottom: 6 }}>
                  <Icon d={I.alert} s={15} c={C.roseDk}/>
                  <div style={{ fontFamily: F_TITLE, fontSize: 12.5, fontWeight: 700, color: C.roseDk, textTransform: "uppercase", letterSpacing: .4 }}>Impact preview</div>
                </div>
                <div style={{ fontSize: 13, color: C.ink2, lineHeight: 1.55 }}>
                  Changing <b>{draft.labelEn}</b> from <code style={code}>{tiers[edit].monthly === 0 ? "FREE" : `৳${tiers[edit].monthly}`}</code> to <code style={code}>{draft.monthly === 0 ? "FREE" : `৳${draft.monthly}`}</code>. <br/>
                  <b style={{ color: C.roseDk }}>{draft.affected.toLocaleString()}</b> active subscribers affected. <br/>
                  Estimated MRR impact: <b style={{ color: C.roseDk, fontFamily: F_MONO }}>{draft.monthly > tiers[edit].monthly ? "+" : ""}৳{((draft.monthly - tiers[edit].monthly) * draft.affected).toLocaleString()}/mo</b>
                </div>
              </div>

              <div>
                <label style={lbl}>Reason for change (required)</label>
                <textarea
                  placeholder="e.g. Q3 pricing review — competitor parity adjustment"
                  rows={2}
                  style={{ ...inputSt, marginTop: 8, resize: "vertical", fontFamily: F_BODY }}
                />
              </div>

              <div>
                <label style={lbl}>Rollout</label>
                <div style={{ marginTop: 10, display: "grid", gridTemplateColumns: "1fr 1fr 1fr", gap: 8 }}>
                  {[["Immediately", true],["At midnight", false],["Next billing cycle", false]].map(([l, sel], i) => (
                    <button key={i} style={{
                      padding: "10px 12px", borderRadius: 8,
                      border: `1px solid ${sel ? C.sage : C.line}`,
                      background: sel ? C.sageBg : C.panel,
                      color: sel ? C.sageDk : C.ink2,
                      fontSize: 12, fontWeight: 600, cursor: "pointer", fontFamily: F_BODY,
                    }}>{l}</button>
                  ))}
                </div>
              </div>
            </div>

            <div style={{ padding: "16px 24px", borderTop: `1px solid ${C.line}`, display: "flex", gap: 10, justifyContent: "flex-end", background: C.bg }}>
              <Btn kind="ghost" onClick={cancelEdit}>Cancel</Btn>
              <Btn kind="sage" onClick={save}>Save & apply</Btn>
            </div>
          </div>
        </div>
      )}
    </Content>
  );
};

const lbl = { fontSize: 11.5, fontWeight: 700, color: C.muted, textTransform: "uppercase", letterSpacing: .4, display: "block" };
const inputSt = {
  width: "100%", padding: "9px 12px", borderRadius: 8, border: `1px solid ${C.lineDk}`,
  fontSize: 13, fontFamily: F_BODY, color: C.ink, background: C.panel, outline: "none",
};
const code = { fontFamily: F_MONO, fontSize: 12, background: C.cream, padding: "1px 6px", borderRadius: 4, fontWeight: 700 };
const Field = ({ l, v, onChange, type = "text", placeholder }) => (
  <div>
    <label style={lbl}>{l}</label>
    <input
      type={type} value={v} placeholder={placeholder}
      onChange={e => onChange(e.target.value)}
      style={{ ...inputSt, marginTop: 8 }}
    />
  </div>
);

// ─── FEATURE FLAGS ─────────────────────────────────────────────
const Features = () => {
  const [flags, setFlags] = useState([
    { k: "intro_slides_v2",      d: "Show new intro slide variant",                     phase: "MVP", scope: "A/B 50/50",  on: true },
    { k: "voice_form_fill",      d: "Enable Bangla voice tenant onboarding",            phase: "MVP", scope: "Global",     on: true },
    { k: "ocr_form_fill",        d: "NID OCR for tenant onboarding",                    phase: "MVP", scope: "Global",     on: true },
    { k: "rent_request_link",    d: "WhatsApp web-link rent collection",                phase: "MVP", scope: "Global",     on: true },
    { k: "expense_tracker",      d: "Per-flat expense and maintenance",                 phase: "MVP", scope: "Global",     on: true },
    { k: "map_pin",              d: "Optional address pin on buildings",                phase: "MVP", scope: "Global",     on: true },
    { k: "nid_verification",     d: "EC NID Matched/Not Matched verification",          phase: "P1",  scope: "Global",     on: false },
    { k: "ai_lease_gen",         d: "AI lease generation (DNCC-compliant)",             phase: "P1",  scope: "Global",     on: false },
    { k: "tenant_app_signup",    d: "Allow tenants to self-register",                   phase: "P1",  scope: "Global",     on: false },
    { k: "mutual_reviews",       d: "Reviews between app-using parties",                phase: "P1",  scope: "Global",     on: false, lockReason: "Awaiting legal sign-off" },
    { k: "warnings_feature",     d: "Private landlord-to-tenant warnings",              phase: "P1",  scope: "Global",     on: false, lockReason: "Awaiting legal sign-off" },
    { k: "history_flags",        d: "Phase 2 reputation graph",                         phase: "P2",  scope: "Allowlist",  on: false, lockReason: "Phase 2 · pilot only" },
    { k: "gatekeeper_module",    d: "Caretaker QR visitor logging",                     phase: "P2",  scope: "Per-building",on: false },
  ]);

  return (
    <Content>
      <Card style={{ marginBottom: 18, background: C.sageBg, border: `1px solid ${C.sage}44` }}>
        <div style={{ display: "flex", alignItems: "flex-start", gap: 12 }}>
          <Icon d={I.flag} s={20} c={C.sageDk}/>
          <div style={{ flex: 1 }}>
            <div style={{ fontFamily: F_TITLE, fontWeight: 700, fontSize: 13.5, color: C.sageDk }}>Feature flags control what's live in production</div>
            <div style={{ fontSize: 12.5, color: C.ink2, marginTop: 4, lineHeight: 1.5 }}>
              Toggling a flag takes effect across all clients within 60 seconds. Some flags are locked pending legal sign-off — these can be unlocked only by Super Admin with documented reason.
            </div>
          </div>
        </div>
      </Card>

      <Card pad={0}>
        <div style={{ padding: "14px 22px", borderBottom: `1px solid ${C.line}`, display: "flex", gap: 12, alignItems: "center" }}>
          <div style={{ flex: 1, position: "relative" }}>
            <Icon d={I.search} s={15} c={C.muted}/>
            <input
              placeholder="Search flags..."
              style={{
                width: "100%", paddingLeft: 36, paddingRight: 12, padding: "9px 12px 9px 36px",
                borderRadius: 8, border: `1px solid ${C.line}`, fontSize: 13, fontFamily: F_BODY,
                outline: "none", background: C.bg,
              }}
            />
            <div style={{ position: "absolute", top: 11, left: 12 }}><Icon d={I.search} s={15} c={C.muted}/></div>
          </div>
          <Btn kind="ghost" size="sm"><Icon d={I.filter} s={14}/> Filter</Btn>
        </div>

        {flags.map((f, i) => (
          <div key={i} style={{
            padding: "14px 22px", display: "flex", alignItems: "center", gap: 14,
            borderBottom: i < flags.length - 1 ? `1px solid ${C.line}` : 0,
            background: f.lockReason ? C.bg : C.panel,
          }}>
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{ display: "flex", alignItems: "center", gap: 8, flexWrap: "wrap" }}>
                <code style={{ ...code, fontSize: 12.5 }}>{f.k}</code>
                <Chip bg={f.phase === "MVP" ? C.sageBg : f.phase === "P1" ? C.butterBg : C.roseBg}
                      fg={f.phase === "MVP" ? C.sageDk : f.phase === "P1" ? C.roseDk : C.roseDk}>
                  {f.phase}
                </Chip>
                <Chip bg={C.lineDk + "33"} fg={C.muted}>{f.scope}</Chip>
                {f.lockReason && <Chip bg={C.dangerBg} fg={C.danger}><Icon d={I.lock} s={10}/>{f.lockReason}</Chip>}
              </div>
              <div style={{ fontSize: 12.5, color: C.ink2, marginTop: 5 }}>{f.d}</div>
            </div>
            <Toggle on={f.on} onChange={v => { const n = [...flags]; n[i].on = v; setFlags(n); }} />
          </div>
        ))}
      </Card>
    </Content>
  );
};

// ─── KILL-SWITCH ───────────────────────────────────────────────
const KillSwitch = () => {
  const [switches, setSwitches] = useState([
    { k: "warnings_system",   l: "Warnings system",        d: "All warning creation. Existing warnings remain readable.",     on: false, audit: "Disabled 3hr ago by Nuhin · Reason: legal review pending" },
    { k: "reviews_system",    l: "Mutual reviews",         d: "Reviews between consenting app users.",                       on: false, audit: "Never enabled" },
    { k: "history_flags",     l: "History flags (P2)",     d: "Phase 2 reputation graph viewing.",                           on: false, audit: "Phase 2 · not yet shipped" },
    { k: "free_text_fields",  l: "All free-text fields",   d: "Force structured-only in warnings/reviews/flags.",            on: true,  audit: "Always allowed" },
    { k: "tenant_app_reviews",l: "Tenant-side reviews",    d: "Disable only the tenant→landlord direction of reviews.",      on: false, audit: "Awaiting tenant app launch" },
    { k: "public_features",   l: "Master · all public features", d: "EMERGENCY MASTER SWITCH. Disables everything publicly viewable.", on: true, audit: "Always allowed · MFA required to disable", master: true },
  ]);
  const [confirm, setConfirm] = useState(null);

  return (
    <Content>
      <Card style={{ marginBottom: 18, background: C.dangerBg, border: `2px solid ${C.danger}66` }}>
        <div style={{ display: "flex", alignItems: "flex-start", gap: 14 }}>
          <div style={{ width: 40, height: 40, borderRadius: 20, background: C.danger, display: "grid", placeItems: "center", flexShrink: 0 }}>
            <Icon d={I.power} s={20} c="#fff"/>
          </div>
          <div style={{ flex: 1 }}>
            <div style={{ fontFamily: F_TITLE, fontWeight: 800, fontSize: 15, color: C.danger }}>Emergency Kill-Switch Panel</div>
            <div style={{ fontSize: 13, color: C.ink2, marginTop: 6, lineHeight: 1.55 }}>
              Use these switches to immediately disable any reputation, warning, or public feature in response to legal or operational events. Every action requires MFA re-prompt, reason text (min 20 chars), and is permanently audit-logged.
            </div>
          </div>
        </div>
      </Card>

      <div style={{ display: "grid", gap: 12 }}>
        {switches.map((s, i) => (
          <Card key={s.k} style={{
            border: s.master ? `2px solid ${C.danger}66` : `1px solid ${C.line}`,
            background: s.master ? "#FFF8F6" : C.panel,
          }}>
            <div style={{ display: "flex", alignItems: "flex-start", gap: 16 }}>
              <div style={{
                width: 44, height: 44, borderRadius: 22,
                background: s.on ? C.sageBg : C.dangerBg,
                display: "grid", placeItems: "center", flexShrink: 0,
              }}>
                <Icon d={s.on ? I.check : I.x} s={20} c={s.on ? C.sageDk : C.danger} sw={2.5}/>
              </div>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ display: "flex", alignItems: "center", gap: 10, flexWrap: "wrap" }}>
                  <div style={{ fontFamily: F_TITLE, fontWeight: 700, fontSize: 15, color: C.ink }}>{s.l}</div>
                  {s.master && <Chip bg={C.danger} fg="#fff">★ MASTER</Chip>}
                  <Chip bg={s.on ? C.sageBg : C.dangerBg} fg={s.on ? C.sageDk : C.danger}>
                    {s.on ? "● ENABLED" : "○ DISABLED"}
                  </Chip>
                </div>
                <div style={{ fontSize: 13, color: C.ink2, marginTop: 6, lineHeight: 1.5 }}>{s.d}</div>
                <div style={{ fontSize: 11.5, color: C.muted, marginTop: 8, fontFamily: F_MONO }}>
                  <Icon d={I.shield} s={11} c={C.muted}/> {s.audit}
                </div>
              </div>
              <Btn
                kind={s.on ? "softDanger" : "soft"}
                onClick={() => setConfirm(s)}
                style={{ flexShrink: 0 }}
              >
                {s.on ? "Disable" : "Enable"}
              </Btn>
            </div>
          </Card>
        ))}
      </div>

      {confirm && (
        <div style={{
          position: "fixed", inset: 0, background: "rgba(20,15,10,.5)",
          display: "grid", placeItems: "center", zIndex: 100, padding: 20,
        }}>
          <div style={{
            background: C.panel, borderRadius: 16, width: "100%", maxWidth: 520,
            boxShadow: "0 30px 60px -20px rgba(0,0,0,.4)",
          }}>
            <div style={{ padding: "20px 24px", borderBottom: `1px solid ${C.line}` }}>
              <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
                <Icon d={I.alert} s={20} c={C.danger}/>
                <div style={{ fontFamily: F_TITLE, fontSize: 16, fontWeight: 800, color: C.danger }}>
                  Confirm: {confirm.on ? "Disable" : "Enable"} {confirm.l}
                </div>
              </div>
            </div>
            <div style={{ padding: 24, display: "grid", gap: 16 }}>
              <div style={{ padding: 14, background: C.dangerBg, borderRadius: 10, fontSize: 12.5, color: C.ink2, lineHeight: 1.55 }}>
                This action will <b>{confirm.on ? "immediately disable" : "immediately re-enable"}</b> the {confirm.l.toLowerCase()} feature across all clients on next refresh (within ~60s). All affected users will lose access. This is permanently audit-logged.
              </div>
              <div>
                <label style={lbl}>Reason (required, min 20 chars)</label>
                <textarea
                  rows={3}
                  placeholder="e.g. CSO §29 complaint received — legal advised immediate disable pending review"
                  style={{ ...inputSt, marginTop: 8, resize: "vertical", fontFamily: F_BODY }}
                />
              </div>
              <div>
                <label style={lbl}>Lawyer reference (optional)</label>
                <input placeholder="e.g. Barrister Karim · Memo 2026-05-22" style={{ ...inputSt, marginTop: 8 }}/>
              </div>
              <div style={{ padding: 12, background: C.bg, borderRadius: 8, display: "flex", alignItems: "center", gap: 10 }}>
                <Icon d={I.lock} s={16} c={C.muted}/>
                <span style={{ fontSize: 12, color: C.muted }}>MFA re-prompt required on Confirm</span>
              </div>
            </div>
            <div style={{ padding: "16px 24px", borderTop: `1px solid ${C.line}`, display: "flex", gap: 10, justifyContent: "flex-end", background: C.bg }}>
              <Btn kind="ghost" onClick={() => setConfirm(null)}>Cancel</Btn>
              <Btn kind="danger" onClick={() => setConfirm(null)}>Confirm with MFA →</Btn>
            </div>
          </div>
        </div>
      )}
    </Content>
  );
};

// ─── USERS ─────────────────────────────────────────────────────
const Users = () => {
  const users = [
    { id: "USR-04812", n: "Md. Ibrahim Hossain",  p: "+8801711-***-111", r: "Landlord",  t: "Bundle 20",         st: "Active",     loc: "Uttara",    units: 14, since: "Mar 2026" },
    { id: "USR-04811", n: "Salim Ahmed",          p: "+8801712-***-098", r: "Landlord",  t: "Free",               st: "Active",     loc: "Mirpur",    units: 2,  since: "May 2026" },
    { id: "USR-04810", n: "Karim Sheikh",         p: "+8801713-***-456", r: "Landlord",  t: "Per-tenant",         st: "Past due",   loc: "Banasree",  units: 8,  since: "Feb 2026" },
    { id: "USR-04809", n: "Fatima Begum",         p: "+8801714-***-222", r: "Landlord",  t: "Free",               st: "Active",     loc: "Dhanmondi", units: 1,  since: "May 2026" },
    { id: "USR-04808", n: "Rashid Khan",          p: "+8801715-***-789", r: "Landlord",  t: "Free",               st: "Active",     loc: "Mohammadpur",units: 2, since: "Apr 2026" },
    { id: "USR-04807", n: "Asif Rahman",          p: "+8801716-***-345", r: "Manager",   t: "B2B",                st: "Active",     loc: "Gulshan",   units: 42, since: "Jan 2026" },
    { id: "USR-04806", n: "Nasrin Akter",         p: "+8801717-***-901", r: "Tenant",    t: "—",                  st: "Active",     loc: "Mirpur",    units: 1,  since: "Apr 2026" },
    { id: "USR-04805", n: "Tariq Aziz",           p: "+8801718-***-567", r: "Landlord",  t: "Unlimited Monthly",  st: "Active",     loc: "Banani",    units: 38, since: "Dec 2025" },
    { id: "USR-04804", n: "Sabina Yasmin",        p: "+8801719-***-234", r: "Landlord",  t: "Bundle 40",          st: "Suspended",  loc: "Uttara",    units: 31, since: "Nov 2025" },
  ];

  return (
    <Content>
      <Card pad={0}>
        <div style={{ padding: "16px 22px", borderBottom: `1px solid ${C.line}`, display: "flex", gap: 12, alignItems: "center" }}>
          <div style={{ flex: 1, position: "relative" }}>
            <div style={{ position: "absolute", top: 10, left: 12 }}><Icon d={I.search} s={15} c={C.muted}/></div>
            <input
              placeholder="Search by phone, name, NID (masked), email, ID..."
              style={{
                width: "100%", padding: "9px 12px 9px 36px",
                borderRadius: 8, border: `1px solid ${C.line}`, fontSize: 13, fontFamily: F_BODY,
                outline: "none", background: C.bg,
              }}
            />
          </div>
          <Btn kind="ghost" size="sm"><Icon d={I.filter} s={14}/> All roles</Btn>
          <Btn kind="ghost" size="sm"><Icon d={I.filter} s={14}/> All tiers</Btn>
          <Btn kind="ghost" size="sm"><Icon d={I.download} s={14}/> Export</Btn>
        </div>

        <table style={{ width: "100%", borderCollapse: "collapse", fontSize: 13 }}>
          <thead>
            <tr style={{ background: C.bg }}>
              {["ID","Name","Phone","Role","Tier","Status","Location","Units","Since",""].map((h, i) => (
                <th key={i} style={{ padding: "10px 16px", textAlign: i === 7 ? "right" : "left", fontSize: 11, fontWeight: 700, color: C.muted, textTransform: "uppercase", letterSpacing: .4, borderBottom: `1px solid ${C.line}` }}>{h}</th>
              ))}
            </tr>
          </thead>
          <tbody>
            {users.map((u, i) => (
              <tr key={u.id} style={{ borderBottom: i < users.length - 1 ? `1px solid ${C.line}` : 0 }}>
                <td style={{ padding: "11px 16px", fontFamily: F_MONO, fontSize: 11.5, color: C.muted }}>{u.id}</td>
                <td style={{ padding: "11px 16px", fontWeight: 600, color: C.ink }}>{u.n}</td>
                <td style={{ padding: "11px 16px", fontFamily: F_MONO, fontSize: 12, color: C.ink2 }}>{u.p}</td>
                <td style={{ padding: "11px 16px" }}>
                  <Chip bg={u.r === "Landlord" ? C.sageBg : u.r === "Manager" ? C.butterBg : C.roseBg}
                        fg={u.r === "Landlord" ? C.sageDk : u.r === "Manager" ? C.roseDk : C.roseDk}>{u.r}</Chip>
                </td>
                <td style={{ padding: "11px 16px", color: C.ink2, fontSize: 12.5 }}>{u.t}</td>
                <td style={{ padding: "11px 16px" }}>
                  <Chip bg={u.st === "Active" ? C.sageBg : u.st === "Past due" ? C.butterBg : C.dangerBg}
                        fg={u.st === "Active" ? C.sageDk : u.st === "Past due" ? C.roseDk : C.danger}>
                    <span style={{ width: 5, height: 5, borderRadius: 3, background: u.st === "Active" ? C.sage : u.st === "Past due" ? C.butter : C.danger }}/>
                    {u.st}
                  </Chip>
                </td>
                <td style={{ padding: "11px 16px", fontSize: 12.5, color: C.ink2 }}>{u.loc}</td>
                <td style={{ padding: "11px 16px", textAlign: "right", fontFamily: F_MONO, fontSize: 12.5, color: C.ink2 }}>{u.units}</td>
                <td style={{ padding: "11px 16px", fontSize: 12, color: C.muted }}>{u.since}</td>
                <td style={{ padding: "11px 16px" }}>
                  <button style={{ ...iconBtn, width: 28, height: 28 }}><Icon d={I.eye} s={14} c={C.muted}/></button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>

        <div style={{ padding: "12px 22px", borderTop: `1px solid ${C.line}`, display: "flex", justifyContent: "space-between", alignItems: "center", fontSize: 12, color: C.muted }}>
          <div>Showing 1–9 of 4,832 users</div>
          <div style={{ display: "flex", gap: 6 }}>
            <Btn kind="ghost" size="sm" disabled>← Prev</Btn>
            <Btn kind="ghost" size="sm">Next →</Btn>
          </div>
        </div>
      </Card>
    </Content>
  );
};

// ─── COMPLIANCE / AUDIT LOG ────────────────────────────────────
const Compliance = () => (
  <Content>
    <div style={{ display: "grid", gridTemplateColumns: "repeat(4, 1fr)", gap: 14, marginBottom: 18 }}>
      {[
        ["Audit entries (24h)", "1,247", C.sage],
        ["Consent records",     "4,118", C.sageDk],
        ["NID verifications",   "1,832", C.roseDk],
        ["Open data requests",  "3",     C.butter],
      ].map(([l, v, c], i) => (
        <Card key={i}>
          <div style={{ fontSize: 11.5, color: C.muted, fontWeight: 600, textTransform: "uppercase", letterSpacing: .4 }}>{l}</div>
          <div style={{ fontFamily: F_TITLE, fontSize: 26, fontWeight: 800, color: C.ink, marginTop: 8, letterSpacing: -.5, lineHeight: 1 }}>{v}</div>
        </Card>
      ))}
    </div>

    <Card pad={0}>
      <div style={{ padding: "16px 22px", borderBottom: `1px solid ${C.line}`, display: "flex", gap: 12, alignItems: "center" }}>
        <div>
          <div style={{ fontFamily: F_TITLE, fontSize: 15, fontWeight: 700 }}>Audit log</div>
          <div style={{ fontSize: 11.5, color: C.muted, marginTop: 2 }}>Every consequential action — admin and user</div>
        </div>
        <div style={{ flex: 1 }}/>
        <Btn kind="ghost" size="sm"><Icon d={I.filter} s={14}/> Actor</Btn>
        <Btn kind="ghost" size="sm"><Icon d={I.filter} s={14}/> Action</Btn>
        <Btn kind="ghost" size="sm"><Icon d={I.filter} s={14}/> Last 24h</Btn>
        <Btn kind="primary" size="sm"><Icon d={I.download} s={14}/> CSV</Btn>
      </div>

      <table style={{ width: "100%", borderCollapse: "collapse", fontSize: 12.5 }}>
        <thead>
          <tr style={{ background: C.bg }}>
            {["Timestamp","Actor","Action","Target","IP","Result"].map((h, i) => (
              <th key={i} style={{ padding: "10px 16px", textAlign: "left", fontSize: 11, fontWeight: 700, color: C.muted, textTransform: "uppercase", letterSpacing: .4, borderBottom: `1px solid ${C.line}` }}>{h}</th>
            ))}
          </tr>
        </thead>
        <tbody>
          {[
            ["15:42:18", "Nuhin (admin)",      "pricing.tier.update",    "tier=unlimited_annual", "203.82.x.x",    "success"],
            ["15:38:02", "Compliance (admin)", "killswitch.toggle",      "warnings_system=OFF",   "203.82.x.x",    "success"],
            ["15:21:45", "USR-04812 (user)",   "subscription.upgrade",   "free→bundle_20",         "180.234.x.x",   "success"],
            ["14:58:11", "system",             "nid.verify.fail",        "USR-04810",              "—",             "503 EC API"],
            ["14:32:09", "Ops (admin)",        "user.suspend",           "USR-04804",              "203.82.x.x",    "success"],
            ["13:14:55", "USR-04808 (user)",   "tenant.add",             "tenant#01872",           "180.234.x.x",   "success"],
            ["12:48:23", "Nuhin (admin)",      "config.update",          "rent_reminder_1_hours=24→12", "203.82.x.x", "success"],
            ["11:22:01", "system",             "rent.reminder.send",     "92 tenants",             "—",             "92 sent"],
            ["10:15:34", "Finance (admin)",    "refund.approve",         "USR-04810 ₹299",         "203.82.x.x",    "success"],
          ].map((r, i) => (
            <tr key={i} style={{ borderBottom: i < 8 ? `1px solid ${C.line}` : 0 }}>
              <td style={{ padding: "10px 16px", fontFamily: F_MONO, fontSize: 11.5, color: C.muted }}>{r[0]}</td>
              <td style={{ padding: "10px 16px", fontSize: 12.5, fontWeight: 600, color: C.ink }}>{r[1]}</td>
              <td style={{ padding: "10px 16px", fontFamily: F_MONO, fontSize: 11.5, color: C.sageDk }}>{r[2]}</td>
              <td style={{ padding: "10px 16px", fontFamily: F_MONO, fontSize: 11.5, color: C.ink2 }}>{r[3]}</td>
              <td style={{ padding: "10px 16px", fontFamily: F_MONO, fontSize: 11, color: C.muted }}>{r[4]}</td>
              <td style={{ padding: "10px 16px" }}>
                <Chip bg={r[5].startsWith("success") || r[5].endsWith("sent") ? C.sageBg : C.dangerBg}
                      fg={r[5].startsWith("success") || r[5].endsWith("sent") ? C.sageDk : C.danger}>{r[5]}</Chip>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </Card>
  </Content>
);

// ─── SYSTEM CONFIG ─────────────────────────────────────────────
const SysConfig = () => {
  const cfgs = [
    { k: "rent_reminder_1_hours",     v: "24",      t: "int",   d: "Hours after rent request before first nudge" },
    { k: "rent_reminder_2_hours",     v: "48",      t: "int",   d: "Hours before second nudge" },
    { k: "verification_fee_bdt",      v: "75",      t: "money", d: "NID verification fee shown to user (BDT)" },
    { k: "visitor_log_retention_days",v: "90",      t: "int",   d: "Days to retain gatekeeper visitor logs before auto-purge" },
    { k: "dmp_form_template_version", v: "v2.1",   t: "text",  d: "Which DMP form template to render" },
    { k: "lease_template_version",    v: "v1.0",   t: "text",  d: "AI lease generator template version" },
    { k: "referral_reward_months",    v: "1",       t: "int",   d: "Free months awarded for referring a paying landlord" },
    { k: "support_whatsapp_number",   v: "+8801700-000000", t: "text", d: "Support contact shown in client apps" },
    { k: "intro_slide_skip_allowed",  v: "true",    t: "bool",  d: "Whether users can skip the 3 intro slides" },
    { k: "free_tier_tenant_limit",    v: "2",       t: "int",   d: "Free-tier max tenants without NID verification" },
  ];
  return (
    <Content>
      <Card style={{ marginBottom: 18, background: C.butterBg, border: `1px solid ${C.butter}` }}>
        <div style={{ display: "flex", alignItems: "flex-start", gap: 12 }}>
          <Icon d={I.cog} s={20} c={C.roseDk}/>
          <div>
            <div style={{ fontFamily: F_TITLE, fontWeight: 700, fontSize: 13.5, color: C.roseDk }}>System configuration</div>
            <div style={{ fontSize: 12.5, color: C.ink2, marginTop: 4, lineHeight: 1.5 }}>
              These values are admin-tunable without code deploy. Every change is audit-logged with before/after diff and takes effect within 60 seconds.
            </div>
          </div>
        </div>
      </Card>

      <Card pad={0}>
        {cfgs.map((c, i) => (
          <div key={c.k} style={{
            padding: "16px 22px", display: "flex", alignItems: "center", gap: 16,
            borderBottom: i < cfgs.length - 1 ? `1px solid ${C.line}` : 0,
          }}>
            <div style={{ flex: 1 }}>
              <div style={{ display: "flex", alignItems: "center", gap: 8, marginBottom: 4 }}>
                <code style={code}>{c.k}</code>
                <Chip bg={C.lineDk + "33"} fg={C.muted}>{c.t}</Chip>
              </div>
              <div style={{ fontSize: 12.5, color: C.ink2 }}>{c.d}</div>
            </div>
            <div style={{
              minWidth: 200, padding: "8px 12px", borderRadius: 8,
              border: `1px solid ${C.line}`, background: C.bg,
              fontFamily: F_MONO, fontSize: 13, color: C.ink, fontWeight: 600,
              display: "flex", alignItems: "center", justifyContent: "space-between", gap: 8,
            }}>
              <span>{c.v}</span>
              <button style={{ background: "transparent", border: 0, cursor: "pointer", display: "grid", placeItems: "center" }}>
                <Icon d={I.edit} s={14} c={C.muted}/>
              </button>
            </div>
          </div>
        ))}
      </Card>
    </Content>
  );
};

// ─── AI PROVIDERS ──────────────────────────────────────────────
const AIProviders = () => {
  const [tab, setTab] = useState("chat");

  const PROVIDERS = {
    chat: {
      title: "Chat / LLM",
      desc: "Powers the support chatbot, lease generation, and Bangla AI summaries.",
      icon: "💬",
      providers: [
        { k: "openai",     n: "OpenAI",          models: ["gpt-4o", "gpt-4o-mini", "gpt-4-turbo"], selected: false, cost: "$0.0025/1K" },
        { k: "anthropic",  n: "Anthropic Claude",models: ["claude-sonnet-4-7", "claude-opus-4-7", "claude-haiku-4-5"], selected: true, cost: "$0.003/1K" },
        { k: "openrouter", n: "OpenRouter",      models: ["auto", "meta/llama-3.3-70b", "qwen/qwen-2.5-72b"], selected: false, cost: "varies" },
        { k: "gemini",     n: "Google Gemini",   models: ["gemini-2.5-pro", "gemini-2.5-flash"], selected: false, cost: "$0.0015/1K" },
        { k: "local",      n: "Self-hosted (Ollama)", models: ["llama-3.3-70b", "qwen-2.5-72b"], selected: false, cost: "compute only" },
      ],
      current: "anthropic", fallback: "openai", model: "claude-sonnet-4-7",
    },
    voice: {
      title: "Voice / ASR",
      desc: "Bangla voice-to-text for tenant onboarding (FR-3.3) and chatbot voice input.",
      icon: "🎤",
      providers: [
        { k: "verbex",     n: "Verbex",                models: ["bangla-v2", "bangla-v1"],   selected: true,  cost: "৳0.4/min" },
        { k: "google_stt", n: "Google Speech-to-Text", models: ["latest_long", "phone_call"], selected: false, cost: "$0.024/min" },
        { k: "whisper",    n: "OpenAI Whisper",        models: ["whisper-1"],                 selected: false, cost: "$0.006/min" },
        { k: "azure_stt",  n: "Azure Speech",          models: ["bn-BD"],                     selected: false, cost: "$1/hr" },
        { k: "local",      n: "Self-hosted (Whisper)", models: ["whisper-large-v3"],          selected: false, cost: "compute only" },
      ],
      current: "verbex", fallback: "whisper", model: "bangla-v2",
    },
    ocr: {
      title: "OCR / Vision",
      desc: "NID card extraction (FR-3.2). Must be Bangla-aware and BD-hosted for NID data.",
      icon: "📇",
      providers: [
        { k: "google_vision", n: "Google Cloud Vision", models: ["text-detection", "document-text"], selected: true,  cost: "$1.5/1K" },
        { k: "azure_ocr",     n: "Azure Document Intelligence", models: ["prebuilt-idDocument", "prebuilt-document"], selected: false, cost: "$1.5/1K" },
        { k: "aws_textract",  n: "AWS Textract",        models: ["DetectDocumentText", "AnalyzeID"], selected: false, cost: "$1.5/1K" },
        { k: "tesseract",     n: "Tesseract (self-hosted)", models: ["ben+eng"],                 selected: false, cost: "compute only" },
      ],
      current: "google_vision", fallback: "tesseract", model: "document-text",
    },
    lease: {
      title: "Lease generation",
      desc: "DNCC-2025-compliant rental agreement generator (FR-8.1).",
      icon: "📄",
      providers: [
        { k: "anthropic",  n: "Anthropic Claude",models: ["claude-opus-4-7", "claude-sonnet-4-7"], selected: true, cost: "$0.015/1K" },
        { k: "openai",     n: "OpenAI",          models: ["gpt-4o"],                              selected: false, cost: "$0.005/1K" },
        { k: "gemini",     n: "Google Gemini",   models: ["gemini-2.5-pro"],                      selected: false, cost: "$0.0125/1K" },
      ],
      current: "anthropic", fallback: "openai", model: "claude-opus-4-7",
    },
  };

  const TABS = [
    { k: "chat",  l: "Chat / LLM",    i: I.ai,    n: "12.4K reqs" },
    { k: "voice", l: "Voice / ASR",   i: I.mic,   n: "3.1K mins" },
    { k: "ocr",   l: "OCR / Vision",  i: I.eye,   n: "847 scans" },
    { k: "lease", l: "Lease gen",     i: I.flag,  n: "42 leases" },
  ];

  const p = PROVIDERS[tab];
  const current = p.providers.find(x => x.k === p.current);

  return (
    <Content>
      <Card style={{ marginBottom: 18, background: C.sageBg, border: `1px solid ${C.sage}44` }}>
        <div style={{ display: "flex", alignItems: "flex-start", gap: 12 }}>
          <Icon d={I.ai} s={20} c={C.sageDk}/>
          <div style={{ flex: 1 }}>
            <div style={{ fontFamily: F_TITLE, fontWeight: 700, fontSize: 13.5, color: C.sageDk }}>AI provider configuration</div>
            <div style={{ fontSize: 12.5, color: C.ink2, marginTop: 4, lineHeight: 1.5 }}>
              Swap LLM, ASR, OCR, and lease-gen providers without code changes. Set primary + fallback for resilience. NID-touching OCR must run BD-hosted or with DPA in place. Changes apply within 60 seconds and are audit-logged.
            </div>
          </div>
        </div>
      </Card>

      {/* tab bar */}
      <div style={{ display: "flex", gap: 6, marginBottom: 14, background: C.panel, padding: 6, borderRadius: 10, border: `1px solid ${C.line}` }}>
        {TABS.map(t => (
          <button key={t.k} onClick={() => setTab(t.k)} style={{
            flex: 1, padding: "10px 12px", borderRadius: 7, border: 0, cursor: "pointer",
            background: t.k === tab ? C.sageBg : "transparent",
            color: t.k === tab ? C.sageDk : C.ink2,
            fontFamily: F_TITLE, fontWeight: t.k === tab ? 700 : 600, fontSize: 13,
            display: "flex", alignItems: "center", justifyContent: "center", gap: 8,
          }}>
            <Icon d={t.i} s={15} c={t.k === tab ? C.sageDk : C.muted}/>
            <span>{t.l}</span>
            <Chip bg={t.k === tab ? "#fff" : C.bg} fg={C.muted} style={{ fontSize: 10, padding: "2px 7px" }}>{t.n}</Chip>
          </button>
        ))}
      </div>

      {/* header */}
      <Card style={{ marginBottom: 14 }}>
        <div style={{ display: "flex", alignItems: "center", gap: 16 }}>
          <div style={{ fontSize: 40 }}>{p.icon}</div>
          <div style={{ flex: 1 }}>
            <div style={{ fontFamily: F_TITLE, fontSize: 17, fontWeight: 800, color: C.ink, letterSpacing: -.3 }}>{p.title}</div>
            <div style={{ fontSize: 12.5, color: C.muted, marginTop: 4, lineHeight: 1.5 }}>{p.desc}</div>
          </div>
          <Btn kind="ghost" size="sm">View logs →</Btn>
        </div>
      </Card>

      <div style={{ display: "grid", gridTemplateColumns: "1.4fr 1fr", gap: 14 }}>
        {/* providers list */}
        <Card pad={0}>
          <div style={{ padding: "14px 18px", borderBottom: `1px solid ${C.line}`, display: "flex", alignItems: "center", justifyContent: "space-between" }}>
            <div style={{ fontFamily: F_TITLE, fontSize: 14, fontWeight: 700 }}>Available providers</div>
            <Btn kind="ghost" size="sm">+ Custom endpoint</Btn>
          </div>
          {p.providers.map((pr, i) => (
            <div key={pr.k} style={{
              padding: "16px 18px", borderBottom: i < p.providers.length - 1 ? `1px solid ${C.line}` : 0,
              background: pr.k === p.current ? C.sageBg + "55" : C.panel,
            }}>
              <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
                <div style={{
                  width: 20, height: 20, borderRadius: 10,
                  border: `2px solid ${pr.k === p.current ? C.sage : C.lineDk}`,
                  background: pr.k === p.current ? C.sage : "#fff",
                  display: "grid", placeItems: "center", flexShrink: 0,
                }}>
                  {pr.k === p.current && <div style={{ width: 8, height: 8, borderRadius: 4, background: "#fff" }}/>}
                </div>
                <div style={{ flex: 1 }}>
                  <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
                    <div style={{ fontFamily: F_TITLE, fontWeight: 700, fontSize: 14, color: C.ink }}>{pr.n}</div>
                    {pr.k === p.current && <Chip bg={C.sage} fg="#fff">PRIMARY</Chip>}
                    {pr.k === p.fallback && <Chip bg={C.butterBg} fg={C.roseDk}>FALLBACK</Chip>}
                  </div>
                  <div style={{ fontSize: 11, color: C.muted, marginTop: 4, fontFamily: F_MONO }}>
                    {pr.models.length} models · {pr.cost}
                  </div>
                </div>
                <Btn kind="ghost" size="sm">Configure</Btn>
              </div>
            </div>
          ))}
        </Card>

        {/* current config detail */}
        <div style={{ display: "flex", flexDirection: "column", gap: 14 }}>
          <Card>
            <div style={{ display: "flex", alignItems: "center", gap: 10, marginBottom: 14 }}>
              <Icon d={I.cog} s={16} c={C.sageDk}/>
              <div style={{ fontFamily: F_TITLE, fontSize: 13.5, fontWeight: 700, color: C.ink }}>Active configuration</div>
            </div>
            <div style={{ display: "grid", gap: 12 }}>
              <div>
                <label style={lbl}>Primary provider</label>
                <div style={{ marginTop: 6, padding: "8px 12px", background: C.bg, borderRadius: 8, fontSize: 13, fontFamily: F_MONO, fontWeight: 700, color: C.sageDk }}>
                  {current.n}
                </div>
              </div>
              <div>
                <label style={lbl}>Model</label>
                <select style={{ ...inputSt, marginTop: 6, fontFamily: F_MONO, fontWeight: 600 }} defaultValue={p.model}>
                  {current.models.map(m => <option key={m} value={m}>{m}</option>)}
                </select>
              </div>
              <div>
                <label style={lbl}>API key</label>
                <div style={{ marginTop: 6, display: "flex", gap: 6 }}>
                  <input type="password" defaultValue="sk-ant-••••••••••••••••••••3F2K" style={{ ...inputSt, flex: 1, fontFamily: F_MONO, fontSize: 12 }}/>
                  <button style={iconBtn}><Icon d={I.eye} s={15} c={C.muted}/></button>
                  <button style={iconBtn}><Icon d={I.copy} s={15} c={C.muted}/></button>
                </div>
              </div>
              <div>
                <label style={lbl}>Endpoint URL <span style={{ textTransform: "none", color: C.muted, fontWeight: 500 }}>(self-hosted only)</span></label>
                <input placeholder="https://api.anthropic.com/v1" style={{ ...inputSt, marginTop: 6, fontFamily: F_MONO, fontSize: 12 }}/>
              </div>
              <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 10 }}>
                <Field l="Temperature" v="0.7" type="number"/>
                <Field l="Max tokens" v="2000" type="number"/>
              </div>
              <div>
                <label style={lbl}>Fallback chain</label>
                <div style={{ marginTop: 6, padding: "8px 12px", background: C.bg, borderRadius: 8, fontSize: 12, fontFamily: F_MONO, color: C.ink2 }}>
                  {current.n} → {p.providers.find(x => x.k === p.fallback)?.n} → error
                </div>
              </div>
              <div style={{ display: "flex", gap: 8, marginTop: 4 }}>
                <Btn kind="sage" size="md" style={{ flex: 1 }}><Icon d={I.zap} s={14}/>Test connection</Btn>
                <Btn kind="primary" size="md" style={{ flex: 1 }}>Save</Btn>
              </div>
            </div>
          </Card>

          <Card>
            <div style={{ fontFamily: F_TITLE, fontSize: 13, fontWeight: 700, color: C.ink, marginBottom: 12 }}>Usage · last 30 days</div>
            <div style={{ display: "grid", gap: 8 }}>
              <div style={{ display: "flex", justifyContent: "space-between", fontSize: 12.5 }}>
                <span style={{ color: C.muted }}>Requests</span>
                <b style={{ color: C.ink, fontFamily: F_MONO }}>12,438</b>
              </div>
              <div style={{ display: "flex", justifyContent: "space-between", fontSize: 12.5 }}>
                <span style={{ color: C.muted }}>Tokens</span>
                <b style={{ color: C.ink, fontFamily: F_MONO }}>2.1M</b>
              </div>
              <div style={{ display: "flex", justifyContent: "space-between", fontSize: 12.5 }}>
                <span style={{ color: C.muted }}>Cost</span>
                <b style={{ color: C.roseDk, fontFamily: F_MONO }}>$6.31</b>
              </div>
              <div style={{ display: "flex", justifyContent: "space-between", fontSize: 12.5 }}>
                <span style={{ color: C.muted }}>Success rate</span>
                <b style={{ color: C.sage, fontFamily: F_MONO }}>99.4%</b>
              </div>
              <div style={{ display: "flex", justifyContent: "space-between", fontSize: 12.5 }}>
                <span style={{ color: C.muted }}>Avg latency</span>
                <b style={{ color: C.ink, fontFamily: F_MONO }}>1.2s</b>
              </div>
            </div>
          </Card>
        </div>
      </div>
    </Content>
  );
};

// ─── NOTIFICATIONS ─────────────────────────────────────────────
const Notifications = () => {
  const [view, setView] = useState("compose");
  const [audience, setAudience] = useState("all");
  const [roleFilter, setRoleFilter] = useState({ landlord: true, manager: false, tenant: false, caretaker: false });
  const [channels, setChannels] = useState({ inapp: true, whatsapp: true, sms: false, email: false });
  const [schedule, setSchedule] = useState("now");

  const reachEstimate = () => {
    let n = 0;
    if (audience === "all") return "4,832 users";
    if (audience === "role") {
      if (roleFilter.landlord) n += 4521;
      if (roleFilter.manager) n += 87;
      if (roleFilter.tenant) n += 224;
      if (roleFilter.caretaker) n += 0;
      return `${n.toLocaleString()} users`;
    }
    if (audience === "segment") return "312 paying landlords";
    return "0 users";
  };

  return (
    <Content>
      {/* tabs */}
      <div style={{ display: "flex", gap: 6, marginBottom: 18 }}>
        {[["compose", "✏️ Compose"], ["history", "📋 History"], ["templates", "📄 Templates"]].map(([k, l]) => (
          <button key={k} onClick={() => setView(k)} style={{
            padding: "9px 16px", borderRadius: 8, border: `1px solid ${k === view ? C.sage : C.line}`,
            background: k === view ? C.sageBg : C.panel,
            color: k === view ? C.sageDk : C.ink2,
            fontFamily: F_TITLE, fontWeight: k === view ? 700 : 600, fontSize: 13, cursor: "pointer",
          }}>{l}</button>
        ))}
      </div>

      {view === "compose" && (
        <div style={{ display: "grid", gridTemplateColumns: "1.5fr 1fr", gap: 14 }}>
          {/* composer */}
          <Card>
            <div style={{ fontFamily: F_TITLE, fontSize: 14.5, fontWeight: 700, color: C.ink, marginBottom: 16 }}>
              Compose notification
            </div>

            <div style={{ display: "grid", gap: 16 }}>
              {/* audience */}
              <div>
                <label style={lbl}>Audience</label>
                <div style={{ marginTop: 8, display: "grid", gridTemplateColumns: "1fr 1fr 1fr 1fr", gap: 6 }}>
                  {[
                    ["all",      "🌐 All users",   "4,832"],
                    ["role",     "👥 By role",     "select →"],
                    ["segment",  "🎯 Segment",     "paying"],
                    ["specific", "🔍 Specific",    "search →"],
                  ].map(([k, l, sub]) => (
                    <button key={k} onClick={() => setAudience(k)} style={{
                      padding: "10px 8px", borderRadius: 8,
                      border: `1.5px solid ${k === audience ? C.sage : C.line}`,
                      background: k === audience ? C.sageBg : C.panel,
                      cursor: "pointer", textAlign: "left", fontFamily: F_BODY,
                    }}>
                      <div style={{ fontSize: 12.5, fontWeight: 700, color: k === audience ? C.sageDk : C.ink }}>{l}</div>
                      <div style={{ fontSize: 10.5, color: C.muted, marginTop: 3 }}>{sub}</div>
                    </button>
                  ))}
                </div>

                {audience === "role" && (
                  <div style={{ marginTop: 10, padding: 12, background: C.bg, borderRadius: 8, display: "flex", gap: 14, flexWrap: "wrap" }}>
                    {[
                      ["landlord",  "Landlord",      "4,521"],
                      ["manager",   "Manager (B2B)", "87"],
                      ["tenant",    "Tenant",        "224"],
                      ["caretaker", "Caretaker",     "0"],
                    ].map(([k, l, n]) => (
                      <label key={k} style={{ display: "flex", alignItems: "center", gap: 7, cursor: "pointer", fontSize: 12.5 }}>
                        <input
                          type="checkbox"
                          checked={roleFilter[k]}
                          onChange={e => setRoleFilter({ ...roleFilter, [k]: e.target.checked })}
                          style={{ width: 16, height: 16, accentColor: C.sage }}
                        />
                        <span style={{ color: C.ink, fontWeight: 600 }}>{l}</span>
                        <span style={{ color: C.muted, fontFamily: F_MONO, fontSize: 11 }}>({n})</span>
                      </label>
                    ))}
                  </div>
                )}
              </div>

              {/* channels */}
              <div>
                <label style={lbl}>Channels</label>
                <div style={{ marginTop: 8, display: "grid", gridTemplateColumns: "1fr 1fr 1fr 1fr", gap: 6 }}>
                  {[
                    ["inapp",    "🔔 In-app",    "free"],
                    ["whatsapp", "💚 WhatsApp",  "৳0.5/msg"],
                    ["sms",      "📱 SMS",       "৳0.3/msg"],
                    ["email",    "✉️ Email",     "free"],
                  ].map(([k, l, cost]) => (
                    <button key={k} onClick={() => setChannels({ ...channels, [k]: !channels[k] })} style={{
                      padding: "10px 8px", borderRadius: 8,
                      border: `1.5px solid ${channels[k] ? C.sage : C.line}`,
                      background: channels[k] ? C.sageBg : C.panel,
                      cursor: "pointer", textAlign: "left", fontFamily: F_BODY,
                    }}>
                      <div style={{ fontSize: 12.5, fontWeight: 700, color: channels[k] ? C.sageDk : C.ink2 }}>{l}</div>
                      <div style={{ fontSize: 10.5, color: C.muted, marginTop: 3 }}>{cost}</div>
                    </button>
                  ))}
                </div>
              </div>

              {/* message */}
              <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 12 }}>
                <Field l="Title (English)" v="" placeholder="e.g. New feature: AI lease generator"/>
                <Field l="শিরোনাম (বাংলা)" v="" placeholder="যেমন: নতুন ফিচার!"/>
              </div>

              <div>
                <label style={lbl}>Body (English)</label>
                <textarea
                  rows={3}
                  placeholder="Hi {name}, we just launched..."
                  style={{ ...inputSt, marginTop: 8, resize: "vertical", fontFamily: F_BODY }}
                />
              </div>
              <div>
                <label style={lbl}>বিবরণ (বাংলা)</label>
                <textarea
                  rows={3}
                  placeholder="হ্যালো {name}, আমরা সম্প্রতি চালু করেছি..."
                  style={{ ...inputSt, marginTop: 8, resize: "vertical", fontFamily: "'Hind Siliguri', sans-serif" }}
                />
              </div>

              <div style={{ padding: 10, background: C.butterBg, borderRadius: 8, fontSize: 11.5, color: C.ink2, lineHeight: 1.5 }}>
                <b style={{ color: C.roseDk }}>Template variables:</b> <code style={{ ...code, fontSize: 10.5 }}>{`{name}`}</code> <code style={{ ...code, fontSize: 10.5 }}>{`{unit}`}</code> <code style={{ ...code, fontSize: 10.5 }}>{`{tier}`}</code> <code style={{ ...code, fontSize: 10.5 }}>{`{rent_amount}`}</code> — auto-filled per recipient
              </div>

              {/* schedule */}
              <div>
                <label style={lbl}>Send</label>
                <div style={{ marginTop: 8, display: "grid", gridTemplateColumns: "1fr 1fr 1fr", gap: 6 }}>
                  {[["now", "⚡ Immediately"],["later","🕐 Schedule"],["recurring","🔄 Recurring"]].map(([k, l]) => (
                    <button key={k} onClick={() => setSchedule(k)} style={{
                      padding: "10px 8px", borderRadius: 8,
                      border: `1.5px solid ${k === schedule ? C.sage : C.line}`,
                      background: k === schedule ? C.sageBg : C.panel,
                      color: k === schedule ? C.sageDk : C.ink2,
                      fontSize: 12.5, fontWeight: 600, cursor: "pointer", fontFamily: F_BODY,
                    }}>{l}</button>
                  ))}
                </div>
              </div>
            </div>
          </Card>

          {/* preview / summary */}
          <div style={{ display: "flex", flexDirection: "column", gap: 14 }}>
            <Card style={{ background: C.bg }}>
              <div style={{ fontFamily: F_TITLE, fontSize: 13, fontWeight: 700, color: C.ink, marginBottom: 12 }}>
                📲 Preview · WhatsApp
              </div>
              <div style={{ background: "#dcf8c6", borderRadius: 12, padding: 12, fontSize: 13, color: C.ink, lineHeight: 1.55, position: "relative", maxWidth: 280, marginLeft: "auto" }}>
                <div style={{ fontWeight: 700, marginBottom: 4 }}>নতুন ফিচার! 🎉</div>
                <div>হ্যালো করিম সাহেব, খাতির-এ এখন AI দিয়ে লিজ এগ্রিমেন্ট তৈরি করতে পারবেন। মাত্র ৩০ সেকেন্ডে!</div>
                <a style={{ display: "block", marginTop: 6, color: "#075e54", textDecoration: "underline", fontSize: 12 }}>khatir.com.bd/new</a>
                <div style={{ position: "absolute", bottom: 4, right: 8, fontSize: 9, color: C.muted }}>now ✓✓</div>
              </div>
            </Card>

            <Card>
              <div style={{ fontFamily: F_TITLE, fontSize: 13, fontWeight: 700, color: C.ink, marginBottom: 12 }}>Send summary</div>
              <div style={{ display: "grid", gap: 8, fontSize: 12.5 }}>
                <div style={{ display: "flex", justifyContent: "space-between" }}>
                  <span style={{ color: C.muted }}>Recipients</span>
                  <b style={{ color: C.ink, fontFamily: F_MONO }}>{reachEstimate()}</b>
                </div>
                <div style={{ display: "flex", justifyContent: "space-between" }}>
                  <span style={{ color: C.muted }}>Channels</span>
                  <b style={{ color: C.ink }}>{Object.entries(channels).filter(([,v]) => v).length} selected</b>
                </div>
                <div style={{ display: "flex", justifyContent: "space-between" }}>
                  <span style={{ color: C.muted }}>Est. cost</span>
                  <b style={{ color: C.roseDk, fontFamily: F_MONO }}>~৳2,265</b>
                </div>
                <div style={{ display: "flex", justifyContent: "space-between" }}>
                  <span style={{ color: C.muted }}>Delivery time</span>
                  <b style={{ color: C.ink }}>{schedule === "now" ? "Immediate" : "Scheduled"}</b>
                </div>
              </div>
              <div style={{ marginTop: 14, padding: 10, background: C.butterBg, borderRadius: 8, fontSize: 11, color: C.ink2, lineHeight: 1.5 }}>
                ⚠️ <b>Audit-logged.</b> All notifications are permanently logged with sender, recipients, content, and delivery status.
              </div>
              <div style={{ display: "flex", gap: 8, marginTop: 14 }}>
                <Btn kind="ghost" size="md" style={{ flex: 1 }}>Save draft</Btn>
                <Btn kind="primary" size="md" style={{ flex: 1.5 }}><Icon d={I.send} s={14}/>{schedule === "now" ? "Send now" : "Schedule"}</Btn>
              </div>
            </Card>
          </div>
        </div>
      )}

      {view === "history" && (
        <Card pad={0}>
          <div style={{ padding: "16px 22px", borderBottom: `1px solid ${C.line}`, display: "flex", gap: 12, alignItems: "center" }}>
            <div>
              <div style={{ fontFamily: F_TITLE, fontSize: 15, fontWeight: 700 }}>Notification history</div>
              <div style={{ fontSize: 11.5, color: C.muted, marginTop: 2 }}>142 sent · last 30 days</div>
            </div>
            <div style={{ flex: 1 }}/>
            <Btn kind="ghost" size="sm"><Icon d={I.filter} s={14}/> Filter</Btn>
            <Btn kind="ghost" size="sm"><Icon d={I.download} s={14}/> Export</Btn>
          </div>
          <table style={{ width: "100%", borderCollapse: "collapse", fontSize: 12.5 }}>
            <thead>
              <tr style={{ background: C.bg }}>
                {["Sent at","Title","Audience","Channels","Sent","Delivered","Opened","Status"].map((h, i) => (
                  <th key={i} style={{ padding: "10px 16px", textAlign: i > 3 ? "right" : "left", fontSize: 11, fontWeight: 700, color: C.muted, textTransform: "uppercase", letterSpacing: .4, borderBottom: `1px solid ${C.line}` }}>{h}</th>
                ))}
              </tr>
            </thead>
            <tbody>
              {[
                ["May 28 14:22", "নতুন ফিচার: AI লিজ", "All landlords",      "WA · in-app", "4,521", "4,489", "3,127", "delivered"],
                ["May 26 10:00", "মাসিক রিপোর্ট",      "Paying landlords",   "Email",       "312",   "308",   "187",   "delivered"],
                ["May 25 09:00", "ভাড়া রিমাইন্ডার",   "Landlords w/ tenants","WA",          "1,847", "1,802", "1,654", "delivered"],
                ["May 22 16:30", "Maintenance window",  "All users",          "in-app · SMS","4,832", "—",     "—",     "delivered"],
                ["May 20 11:00", "Promo: Bundle 20",    "Free tier > 2 tenants","WA · in-app","412",  "406",   "298",   "delivered"],
                ["May 18 09:00", "নতুন: ভয়েস ফর্ম",  "All landlords",      "WA · in-app", "4,498", "4,471", "2,932", "delivered"],
              ].map((r, i) => (
                <tr key={i} style={{ borderBottom: i < 5 ? `1px solid ${C.line}` : 0 }}>
                  <td style={{ padding: "11px 16px", fontFamily: F_MONO, fontSize: 11.5, color: C.muted }}>{r[0]}</td>
                  <td style={{ padding: "11px 16px", fontWeight: 600, color: C.ink }}>{r[1]}</td>
                  <td style={{ padding: "11px 16px", color: C.ink2, fontSize: 12 }}>{r[2]}</td>
                  <td style={{ padding: "11px 16px", fontFamily: F_MONO, fontSize: 11, color: C.muted }}>{r[3]}</td>
                  <td style={{ padding: "11px 16px", textAlign: "right", fontFamily: F_MONO, fontSize: 12, color: C.ink2 }}>{r[4]}</td>
                  <td style={{ padding: "11px 16px", textAlign: "right", fontFamily: F_MONO, fontSize: 12, color: C.sageDk }}>{r[5]}</td>
                  <td style={{ padding: "11px 16px", textAlign: "right", fontFamily: F_MONO, fontSize: 12, color: C.ink2 }}>{r[6]}</td>
                  <td style={{ padding: "11px 16px", textAlign: "right" }}>
                    <Chip bg={C.sageBg} fg={C.sageDk}>{r[7]}</Chip>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </Card>
      )}

      {view === "templates" && (
        <Card pad={0}>
          <div style={{ padding: "16px 22px", borderBottom: `1px solid ${C.line}`, display: "flex", alignItems: "center", justifyContent: "space-between" }}>
            <div>
              <div style={{ fontFamily: F_TITLE, fontSize: 15, fontWeight: 700 }}>Templates</div>
              <div style={{ fontSize: 11.5, color: C.muted, marginTop: 2 }}>Reusable notification templates</div>
            </div>
            <Btn kind="primary" size="sm">+ New template</Btn>
          </div>
          {[
            ["Rent reminder (1st)",      "Sent 24h after rent request",       "WhatsApp",    "auto"],
            ["Rent reminder (2nd)",      "Sent 48h after rent request",       "WhatsApp · SMS","auto"],
            ["Welcome — new landlord",   "First-time signup",                 "WhatsApp · in-app","auto"],
            ["Free tier limit reached",  "When landlord adds 3rd tenant",     "in-app",        "auto"],
            ["Payment received",         "On rent verification",              "WhatsApp · in-app","auto"],
            ["Maintenance resolved",     "When landlord marks request done", "in-app",        "auto"],
            ["Subscription expiring",    "7 days before billing",             "WhatsApp · email","auto"],
          ].map((t, i) => (
            <div key={i} style={{
              padding: "13px 22px", display: "flex", alignItems: "center", gap: 14,
              borderBottom: i < 6 ? `1px solid ${C.line}` : 0,
            }}>
              <div style={{ width: 32, height: 32, borderRadius: 16, background: C.sageBg, display: "grid", placeItems: "center", fontSize: 14 }}>📨</div>
              <div style={{ flex: 1 }}>
                <div style={{ fontFamily: F_TITLE, fontWeight: 700, fontSize: 13.5, color: C.ink }}>{t[0]}</div>
                <div style={{ fontSize: 11.5, color: C.muted, marginTop: 2 }}>{t[1]}</div>
              </div>
              <Chip bg={C.lineDk + "33"} fg={C.muted}>{t[2]}</Chip>
              <Chip bg={C.sageBg} fg={C.sageDk}>{t[3]}</Chip>
              <button style={{ ...iconBtn, width: 30, height: 30 }}><Icon d={I.edit} s={14} c={C.muted}/></button>
            </div>
          ))}
        </Card>
      )}
    </Content>
  );
};

// ─── PLACEHOLDER ──────────────────────────────────────────────
const Placeholder = ({ name, icon }) => (
  <Content>
    <Card style={{ textAlign: "center", padding: 60 }}>
      <div style={{ width: 56, height: 56, borderRadius: 28, background: C.sageBg, display: "grid", placeItems: "center", margin: "0 auto 16px" }}>
        <Icon d={icon} s={26} c={C.sageDk}/>
      </div>
      <div style={{ fontFamily: F_TITLE, fontSize: 18, fontWeight: 700, color: C.ink }}>{name}</div>
      <div style={{ fontSize: 13, color: C.muted, marginTop: 6, maxWidth: 400, margin: "6px auto 0", lineHeight: 1.5 }}>
        See <code style={code}>04_Admin_Portal_Khatir.md</code> for the full specification of this module. Implementation per backlog phase.
      </div>
    </Card>
  </Content>
);

// ─── ROUTER ────────────────────────────────────────────────────
export default function KhatirAdmin() {
  const [active, setActive] = useState("dashboard");

  const titles = {
    dashboard:  ["Dashboard",     "Platform health · last 24 hours"],
    users:      ["Users & accounts", "4,832 total · 312 paying"],
    pricing:    ["Pricing & subscriptions", "6 active tiers · live-configurable"],
    features:   ["Feature management",     "Feature flags and rollout controls"],
    kill:       ["Kill-switch panel",      "Emergency disable of reputation/public features"],
    notify:     ["Notifications",          "Compose · history · templates · multi-channel"],
    ai:         ["AI providers",           "Chat · voice · OCR · lease-gen · live-configurable"],
    compliance: ["Compliance",             "Audit log · consent records · data requests"],
    config:     ["System configuration",   "Runtime tunables · all admin-configurable"],
    support:    ["Support",                "Open tickets · WhatsApp escalations"],
    analytics:  ["Analytics",              "Acquisition · activation · revenue · retention"],
    admins:     ["Admin users",            "Internal staff access · roles · MFA"],
  };

  const screens = {
    dashboard:  <Dashboard/>,
    users:      <Users/>,
    pricing:    <Pricing/>,
    features:   <Features/>,
    kill:       <KillSwitch/>,
    notify:     <Notifications/>,
    ai:         <AIProviders/>,
    compliance: <Compliance/>,
    config:     <SysConfig/>,
    support:    <Placeholder name="Support tickets" icon={I.ticket}/>,
    analytics:  <Placeholder name="Analytics dashboards" icon={I.chart}/>,
    admins:     <Placeholder name="Admin user management" icon={I.lock}/>,
  };

  return (
    <Shell>
      <style>{`
        @import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&family=Plus+Jakarta+Sans:wght@600;700;800&family=JetBrains+Mono:wght@500;700&family=Caveat:wght@700&display=swap');
        * { box-sizing: border-box; }
        button:active { transform: scale(.98); }
        code { font-family: 'JetBrains Mono', monospace; }
      `}</style>
      <div style={{ display: "flex", minHeight: "100vh" }}>
        <Sidebar active={active} go={setActive}/>
        <div style={{ flex: 1, minWidth: 0 }}>
          <TopBar title={titles[active][0]} subtitle={titles[active][1]}/>
          {screens[active]}
        </div>
      </div>
    </Shell>
  );
}
