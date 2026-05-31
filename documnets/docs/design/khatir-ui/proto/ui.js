/* ═══════════════════════════════════════════════════════════════
   Khatir prototype — shared builders + screen registry + router
   ═══════════════════════════════════════════════════════════════ */

// ── screen registry ──  id -> { group, gcolor, en, bn, ph, render(go) }
const SCREENS = {};
let GROUP_ORDER = [];
function reg(id, meta) {
  SCREENS[id] = meta;
  if (!GROUP_ORDER.find(g => g.key === meta.group))
    GROUP_ORDER.push({ key: meta.group, color: meta.gcolor || '#7BA084' });
}

// ── builders ──
function statusbar() {
  return `<div class="statusbar">
    <div class="t">9:41</div>
    <div class="r"><span class="d"></span><span class="d" style="opacity:.5"></span>${kicon('globe',{s:13,c:'#2C3530',sw:2})}<i></i></div>
  </div>`;
}

function topbar(o) {
  o = o || {};
  if (o.brand) {
    return `<div class="topbar ${o.tr?'tr':''}">
      <div class="brandmini">
        <div class="m"><span>খ</span></div>
        <div class="nm">Khatir <em>খাতির</em><small>বাড়িওয়ালার ডিজিটাল খাতা</small></div>
      </div>
      ${o.action||''}
    </div>`;
  }
  return `<div class="topbar ${o.tr?'tr':''}">
    ${o.back ? `<button class="iconbtn" onclick="go('${o.back}')">${kicon('back',{s:20})}</button>` : ''}
    <div class="ttl">${o.title||''}</div>
    ${o.action||''}
  </div>`;
}

function bellbtn() {
  return `<button class="iconbtn">${kicon('bell',{s:18})}<span class="dotbadge"></span></button>`;
}

function bottomnav(active, role) {
  role = role || 'landlord';
  const home = role==='manager'?'mgrHome':role==='tenant'?'tenHome':'home';
  const items = [
    [home, 'home', 'হোম', 'Home'],
    ['dashboard', 'chart', 'চার্ট', 'Charts'],
    ['addTenant', 'plus', 'যোগ', 'Add', true],
    ['rentReq', 'cash', 'ভাড়া', 'Rent'],
    ['more', 'more', 'আরও', 'More'],
  ];
  return `<div class="bottomnav">${items.map(([id,ic,bn,en,fab])=>{
    const on = id===active;
    return `<button class="navitem ${on?'on':''} ${fab?'fab':''}" onclick="go('${id}')">
      <div class="nd">${kicon(ic,{s:fab?21:20,c:fab?'#fff':(on?'#5C8067':'#8C8578')})}</div>
      <span class="lab">${bn}</span>
    </button>`;
  }).join('')}</div>`;
}

function bil(en, bn, opts) {
  opts = opts||{};
  return `<span class="bil"><span class="en2" style="${opts.es||''}">${en}</span><span class="bn2" style="font-size:${opts.bs||'11px'};color:${opts.bc||'var(--muted)'};${opts.bstyle||''}">${bn}</span></span>`;
}

function iconBadge(ic, bg, c, s, sz) {
  return `<span class="k-iconbadge" style="width:${sz||44}px;height:${sz||44}px;background:${bg}">${kicon(ic,{s:s||20,c:c})}</span>`;
}

function avatar(letter, bg) { return `<div class="avatar" style="background:${bg}">${letter}</div>`; }

function field(lab, val, ph) {
  return `<div class="k-field" style="margin-bottom:10px;">
    <div class="lab">${lab}</div>
    <input class="k-input" value="${val||''}" placeholder="${ph||''}">
  </div>`;
}

// emoji hero block (warmth, per hybrid rule)
function emojiHero(e, hand, sub) {
  return `<div class="emoji-hero" style="padding:6px 0 4px;">
    <div class="e">${e}</div>
    ${hand?`<div class="h">${hand}</div>`:''}
    ${sub?`<div class="s">${sub}</div>`:''}
  </div>`;
}

// ── router ──
let CURRENT = 'splash';
let ROLE = 'landlord';

function deviceShell(inner) {
  return `<div class="notch"></div><div class="app fadein">${inner}</div>`;
}

function go(id) {
  if (!SCREENS[id]) { console.warn('no screen', id); return; }
  CURRENT = id;
  // role inference from home screens
  if (id==='home') ROLE='landlord';
  if (id==='mgrHome') ROLE='manager';
  if (id==='tenHome') ROLE='tenant';
  const dev = document.getElementById('device');
  dev.innerHTML = deviceShell(SCREENS[id].render());
  kiconHydrate(dev);
  dev.querySelector('.scroll') && (dev.querySelector('.scroll').scrollTop = 0);
  renderIndex();
  if (window.innerWidth <= 900) document.getElementById('idx').classList.remove('open');
  try { localStorage.setItem('khatir_screen', id); } catch(e){}
  history.replaceState(null,'','#'+id);
}

// ── sidebar index ──
function renderIndex() {
  const groups = {};
  Object.entries(SCREENS).forEach(([id,m])=>{ (groups[m.group]=groups[m.group]||[]).push([id,m]); });
  const html = GROUP_ORDER.map(g=>{
    const items = groups[g.key]||[];
    return `<div class="idx-group"><span class="gd" style="background:${g.color}"></span>${g.key}</div>` +
      items.map(([id,m])=>`
        <button class="idx-item ${id===CURRENT?'on':''}" onclick="go('${id}')">
          <i class="lead k-ico">${kicon(m.ico||'grid',{s:16,c:id===CURRENT?'#fff':'#6B6558'})}</i>
          <span class="t"><b>${m.en}</b><span>${m.bn}</span></span>
          <span class="ph ph${m.ph}">P${m.ph}</span>
        </button>`).join('');
  }).join('');
  document.getElementById('idxList').innerHTML = html;
}

// re-render current screen in place (for internal step/slide state) — no scroll reset, no index churn
function repaint() {
  const dev = document.getElementById('device');
  dev.innerHTML = deviceShell(SCREENS[CURRENT].render());
  kiconHydrate(dev);
}

function boot() {  let start = 'splash';
  const h = location.hash.replace('#','');
  if (h && SCREENS[h]) start = h;
  go(start);
}
window.addEventListener('DOMContentLoaded', boot);
