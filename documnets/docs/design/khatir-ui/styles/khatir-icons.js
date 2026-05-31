/* ═══════════════════════════════════════════════════════════════
   Khatir line-icon set — hybrid system
   Usage: kicon('home', {s:22, c:'#5C8067', sw:1.8})  → returns <svg> string
   Or:    <i class="ico" data-ico="home"></i> then kiconHydrate()
   ═══════════════════════════════════════════════════════════════ */
const KICONS = {
  // nav
  home:    '<path d="M3 10.5 12 3l9 7.5V21h-6v-6h-6v6H3Z"/>',
  chart:   '<path d="M4 19V5M4 19h16"/><rect x="7" y="11" width="3" height="6"/><rect x="12" y="8" width="3" height="9"/><rect x="17" y="13" width="3" height="4"/>',
  plus:    '<path d="M12 5v14M5 12h14"/>',
  cash:    '<rect x="2" y="6" width="20" height="12" rx="2"/><circle cx="12" cy="12" r="3"/><path d="M6 9v6M18 9v6" stroke-width="1.2"/>',
  more:    '<circle cx="5" cy="12" r="1.6"/><circle cx="12" cy="12" r="1.6"/><circle cx="19" cy="12" r="1.6"/>',
  grid:    '<rect x="3" y="3" width="7" height="7" rx="1.5"/><rect x="14" y="3" width="7" height="7" rx="1.5"/><rect x="3" y="14" width="7" height="7" rx="1.5"/><rect x="14" y="14" width="7" height="7" rx="1.5"/>',
  // entities
  building:'<path d="M4 21V5a1 1 0 0 1 1-1h8a1 1 0 0 1 1 1v16"/><path d="M14 9h5a1 1 0 0 1 1 1v11"/><path d="M2 21h20"/><path d="M7 8h2M7 12h2M7 16h2M17 13h0M17 17h0"/>',
  door:    '<path d="M5 21V4a1 1 0 0 1 1-1h12a1 1 0 0 1 1 1v17"/><path d="M3 21h18"/><circle cx="15" cy="12" r="1"/>',
  user:    '<circle cx="12" cy="8" r="4"/><path d="M4 21a8 8 0 0 1 16 0"/>',
  users:   '<circle cx="9" cy="8" r="3.6"/><path d="M2.5 20a6.5 6.5 0 0 1 13 0"/><path d="M16 5.2a3.6 3.6 0 0 1 0 6.6M21.5 20a6.5 6.5 0 0 0-4-6"/>',
  wrench:  '<path d="M14.5 5.5a4 4 0 0 1-5.4 5L4 15.5 8.5 20l5-5.1a4 4 0 0 1 5-5.4l-2.8 2.8-2.2-2.2 2.8-2.8a4 4 0 0 0-.5-.8Z"/>',
  doc:     '<path d="M14 3H6a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V9Z"/><path d="M14 3v6h6"/><path d="M8 13h8M8 17h5"/>',
  receipt: '<path d="M5 3v18l2-1.4 2 1.4 2-1.4 2 1.4 2-1.4 2 1.4V3l-2 1.4-2-1.4-2 1.4-2-1.4-2 1.4Z"/><path d="M8 8h8M8 12h8M8 16h5"/>',
  // actions
  cam:     '<path d="M3 8a2 2 0 0 1 2-2h2l1.5-2h7L19 6h0a2 2 0 0 1 2 2v9a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2Z"/><circle cx="12" cy="13" r="3.5"/>',
  mic:     '<rect x="9" y="3" width="6" height="11" rx="3"/><path d="M5 11a7 7 0 0 0 14 0M12 18v3"/>',
  pencil:  '<path d="m12 20 9-9-3-3-9 9v3h3Z"/><path d="m14 7 4 4"/>',
  send:    '<path d="M22 2 11 13M22 2l-7 20-4-9-9-4Z"/>',
  download:'<path d="M12 3v12M7 10l5 5 5-5M4 21h16"/>',
  share:   '<circle cx="18" cy="5" r="3"/><circle cx="6" cy="12" r="3"/><circle cx="18" cy="19" r="3"/><path d="M8.6 13.5 15.4 17.5M15.4 6.5 8.6 10.5"/>',
  search:  '<circle cx="11" cy="11" r="7"/><path d="m21 21-4.3-4.3"/>',
  bell:    '<path d="M6 8a6 6 0 0 1 12 0c0 7 3 9 3 9H3s3-2 3-9"/><path d="M10 21a2 2 0 0 0 4 0"/>',
  back:    '<path d="M15 18l-6-6 6-6"/>',
  arrow:   '<path d="M5 12h14M13 5l7 7-7 7"/>',
  chevron: '<path d="m9 6 6 6-6 6"/>',
  chevdown:'<path d="m6 9 6 6 6-6"/>',
  check:   '<path d="M20 6 9 17l-5-5"/>',
  x:       '<path d="M18 6 6 18M6 6l12 12"/>',
  edit:    '<path d="m12 20 9-9-3-3-9 9v3h3Z"/><path d="m14 7 4 4"/>',
  trash:   '<path d="M3 6h18M8 6V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2M6 6v14a2 2 0 0 0 2 2h8a2 2 0 0 0 2-2V6"/>',
  eye:     '<path d="M2 12s3.5-7 10-7 10 7 10 7-3.5 7-10 7-10-7-10-7Z"/><circle cx="12" cy="12" r="3"/>',
  copy:    '<rect x="9" y="9" width="13" height="13" rx="2"/><path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"/>',
  phone:   '<path d="M5 4h4l2 5-2.5 1.5a11 11 0 0 0 5 5L20 18l1 4a16 16 0 0 1-17-17Z"/>',
  wa:      '<path d="M12 3a9 9 0 0 0-7.7 13.6L3 21l4.6-1.2A9 9 0 1 0 12 3Z"/><path d="M8.5 8.8c.2-.6.5-.6.8-.6h.6c.2 0 .4 0 .6.5l.6 1.4c.1.2 0 .4-.1.5l-.4.5c-.1.2-.2.3 0 .6a6 6 0 0 0 2.4 2c.3.1.4 0 .6-.1l.5-.6c.2-.2.3-.2.5-.1l1.3.7c.3.1.4.2.4.4 0 .4-.2 1.2-.9 1.4-.6.3-1.4.4-3.3-.5a8 8 0 0 1-3.5-3.4c-.5-.9-.6-1.6-.5-2.1Z" stroke-width="0" fill="currentColor"/>',
  pin:     '<path d="M12 22s8-7.6 8-13a8 8 0 0 0-16 0c0 5.4 8 13 8 13Z"/><circle cx="12" cy="9" r="2.5"/>',
  map:     '<path d="m9 4-6 2.5V20l6-2.5L15 20l6-2.5V4l-6 2.5L9 4Z"/><path d="M9 4v13.5M15 6.5V20"/>',
  shield:  '<path d="M12 3l8 3v6c0 5-3.5 7.5-8 9-4.5-1.5-8-4-8-9V6Z"/><path d="M9 12l2 2 4-4"/>',
  qr:      '<rect x="3" y="3" width="7" height="7" rx="1"/><rect x="14" y="3" width="7" height="7" rx="1"/><rect x="3" y="14" width="7" height="7" rx="1"/><path d="M14 14h3v3M21 14v.01M14 21h.01M17 21h4v-4M21 17v.01"/>',
  star:    '<path d="m12 3 2.6 5.7 6.2.7-4.6 4.2 1.2 6.1L12 16.8 6.6 19.7l1.2-6.1L3.2 9.4l6.2-.7L12 3Z"/>',
  clock:   '<circle cx="12" cy="12" r="9"/><path d="M12 7v5l3.5 2"/>',
  alert:   '<path d="M10.3 3.3 1.8 18a2 2 0 0 0 1.7 3h17a2 2 0 0 0 1.7-3L13.7 3.3a2 2 0 0 0-3.4 0Z"/><path d="M12 9v4M12 17h.01"/>',
  flag:    '<path d="M5 21V4M5 4h12l-2 4 2 4H5"/>',
  lock:    '<rect x="4" y="11" width="16" height="10" rx="2"/><path d="M8 11V7a4 4 0 0 1 8 0v4"/>',
  cog:     '<circle cx="12" cy="12" r="3"/><path d="M19.4 13a1.7 1.7 0 0 0 .3 1.8 2 2 0 1 1-2.8 2.8 1.7 1.7 0 0 0-2.8 1.2 2 2 0 1 1-4 0 1.7 1.7 0 0 0-2.8-1.2 2 2 0 1 1-2.8-2.8A1.7 1.7 0 0 0 4 13a2 2 0 1 1 0-4 1.7 1.7 0 0 0 1.7-2.8 2 2 0 1 1 2.8-2.8A1.7 1.7 0 0 0 11 4a2 2 0 1 1 4 0 1.7 1.7 0 0 0 2.8 1.2 2 2 0 1 1 2.8 2.8A1.7 1.7 0 0 0 20 9a2 2 0 1 1 0 4Z"/>',
  globe:   '<circle cx="12" cy="12" r="9"/><path d="M3 12h18M12 3a14 14 0 0 1 0 18M12 3a14 14 0 0 0 0 18"/>',
  logout:  '<path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/><path d="M16 17l5-5-5-5M21 12H9"/>',
  sparkle: '<path d="M12 3l1.6 5.4L19 10l-5.4 1.6L12 17l-1.6-5.4L5 10l5.4-1.6L12 3Z"/><path d="M19 15l.7 2.3L22 18l-2.3.7L19 21l-.7-2.3L16 18l2.3-.7L19 15Z" stroke-width="1.2"/>',
  card:    '<rect x="2" y="5" width="20" height="14" rx="2.5"/><path d="M2 10h20M6 15h4"/>',
  filter:  '<path d="M3 5h18M6 12h12M10 19h4"/>',
  refresh: '<path d="M21 12a9 9 0 1 1-3-6.7L21 8M21 3v5h-5"/>',
  badge:   '<circle cx="12" cy="10" r="6"/><path d="M9 15.5 8 22l4-2 4 2-1-6.5"/>',
};

function kicon(name, o) {
  o = o || {};
  const s = o.s || 22, c = o.c || 'currentColor', sw = o.sw == null ? 1.8 : o.sw;
  const inner = KICONS[name] || '';
  return `<svg class="k-ico" width="${s}" height="${s}" viewBox="0 0 24 24" fill="none" stroke="${c}" stroke-width="${sw}" stroke-linecap="round" stroke-linejoin="round">${inner}</svg>`;
}

function kiconHydrate(root) {
  (root || document).querySelectorAll('[data-ico]').forEach(el => {
    if (el.dataset.done) return;
    el.dataset.done = '1';
    el.innerHTML = kicon(el.dataset.ico, {
      s: +el.dataset.s || 22,
      c: el.dataset.c || 'currentColor',
      sw: el.dataset.sw ? +el.dataset.sw : 1.8,
    });
  });
}
if (typeof window !== 'undefined') { window.kicon = kicon; window.kiconHydrate = kiconHydrate; window.KICONS = KICONS; }
