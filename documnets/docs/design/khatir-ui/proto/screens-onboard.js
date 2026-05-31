/* ═══ Khatir prototype — Onboarding & Auth screens ═══ */

// ── SPLASH ──
reg('splash', { group:'Onboarding & Auth', gcolor:'#5C8067', en:'Splash', bn:'স্প্ল্যাশ', ph:0, ico:'sparkle', render(){
  return statusbar() + `
  <div class="scroll" style="display:grid;place-items:center;">
    <div style="text-align:center;padding:24px;">
      <img src="assets/khatir-icon-512.png" width="118" height="118" style="border-radius:30px;box-shadow:var(--sh-lg);">
      <div style="font-family:var(--f-title);font-weight:800;font-size:34px;letter-spacing:-1px;margin-top:22px;">Khatir</div>
      <div style="font-family:var(--f-body);font-weight:700;font-size:24px;color:var(--sage-dk);margin-top:2px;">খাতির</div>
      <div style="width:32px;height:4px;background:var(--butter);border-radius:99px;margin:16px auto;"></div>
      <div style="font-family:var(--f-body);font-weight:600;color:var(--ink-2);font-size:14px;">বাড়িওয়ালার ডিজিটাল খাতা</div>
      <div style="font-family:var(--f-hand);color:var(--muted-dk);font-size:18px;margin-top:2px;">The landlord's digital ledger</div>
      <div style="margin-top:34px;"><button class="k-btn primary lg" onclick="go('intro')">${kicon('arrow',{s:18,c:'#fff'})} শুরু করি · Start</button></div>
    </div>
  </div>`;
}});

// ── INTRO SLIDES ──
let introI = 0;
const INTRO = [
  { e:'🏠', bg:'var(--sage-bg)', ac:'var(--sage)', acd:'var(--sage-dk)', k:'স্বাগতম · Welcome', en:"The landlord's digital ledger", bn:'বাড়িওয়ালার ডিজিটাল খাতা', body:'কাগজের ঝামেলা শেষ। ভাড়াটিয়ার তথ্য, ভাড়ার হিসাব, খরচ — সব এক জায়গায়।', bodyEn:'No more paperwork hassle. Tenant records, rent, expenses — all in one place.' },
  { e:'⚡', bg:'var(--butter-bg)', ac:'var(--butter)', acd:'var(--butter-dk)', k:'প্রধান সুবিধা · The wedge', en:'Police form, in 2 minutes', bn:'পুলিশ ফর্ম, ২ মিনিটে!', body:'থানায় দৌড়ানো বন্ধ। NID-এর ছবি তুলুন, ফর্ম নিজে থেকেই পূরণ হবে।', bodyEn:'Stop running to the thana. Snap the NID, the form fills itself.' },
  { e:'🎁', bg:'var(--rose-bg)', ac:'var(--rose)', acd:'var(--rose-dk)', k:'একদম ফ্রি! · Free hook', en:'First 2 tenants free', bn:'প্রথম ২ ভাড়াটিয়া ফ্রি', body:'কোনো খরচ ছাড়াই পুরো ব্যবস্থা ব্যবহার করুন। NID যাচাই ছাড়া সব ফিচার।', bodyEn:'Use the whole system at zero cost — every feature except NID verification.' },
];
reg('intro', { group:'Onboarding & Auth', gcolor:'#5C8067', en:'Intro slides', bn:'ইন্ট্রো (৩টি)', ph:0, ico:'grid', render(){
  const s = INTRO[introI];
  return statusbar() + `
  <div style="padding:14px 22px 4px;display:flex;justify-content:space-between;align-items:center;">
    <div style="display:flex;gap:6px;">
      ${INTRO.map((_,k)=>`<div style="width:${k===introI?28:8}px;height:8px;background:${k===introI?s.acd:'var(--line)'};border-radius:4px;transition:all .3s;"></div>`).join('')}
    </div>
    <button onclick="introI=0;go('login')" style="background:none;border:0;color:var(--muted);font-size:13px;font-weight:600;cursor:pointer;">এড়িয়ে যান · Skip</button>
  </div>
  <div class="scroll"><div style="padding:24px 28px;text-align:center;">
    <div style="width:212px;height:212px;background:${s.bg};border-radius:50%;margin:8px auto 26px;display:grid;place-items:center;font-size:104px;position:relative;box-shadow:0 30px 60px -26px ${s.ac};">
      <span style="filter:drop-shadow(0 4px 12px rgba(0,0,0,.12));">${s.e}</span>
      <div style="position:absolute;top:22px;right:18px;width:22px;height:22px;border-radius:99px;background:${s.ac};opacity:.8;"></div>
      <div style="position:absolute;bottom:30px;left:14px;width:13px;height:13px;border-radius:99px;background:${s.ac};opacity:.55;"></div>
    </div>
    <span class="k-chip" style="background:${s.bg};color:${s.acd};">${s.k}</span>
    <div style="font-family:var(--f-title);font-weight:800;font-size:27px;letter-spacing:-.6px;line-height:1.15;margin-top:12px;">${s.bn}</div>
    <div style="font-family:var(--f-hand);font-size:24px;color:${s.acd};line-height:1;margin-top:6px;">${s.en}</div>
    <div style="font-size:15px;color:var(--muted-dk);line-height:1.6;margin-top:14px;max-width:300px;margin-left:auto;margin-right:auto;">${s.body}</div>
    <div style="font-size:12.5px;color:var(--muted);line-height:1.5;margin-top:8px;max-width:290px;margin-left:auto;margin-right:auto;font-style:italic;">${s.bodyEn}</div>
  </div></div>
  <div style="padding:14px 22px 22px;flex-shrink:0;">
    ${introI<INTRO.length-1
      ? `<button class="k-btn full lg" style="background:${s.ac};color:${s.ac==='var(--butter)'?'var(--ink)':'#fff'};" onclick="introI++;repaint()">পরবর্তী · Next →</button>`
      : `<button class="k-btn primary full lg" onclick="introI=0;go('login')">শুরু করি! · Get started 🎉</button>`}
  </div>`;
}});

// ── LOGIN (phone) ──
reg('login', { group:'Onboarding & Auth', gcolor:'#5C8067', en:'Phone + OTP', bn:'মোবাইল ও OTP', ph:0, ico:'phone', render(){
  return statusbar() + topbar({tr:true}) + `
  <div class="scroll"><div class="pad">
    ${emojiHero('👋','Hello!','স্বাগতম, বাড়িওয়ালা')}
    <div style="text-align:center;color:var(--muted);font-size:13.5px;margin-top:6px;">Welcome — sign in with your mobile number<br>মোবাইল নম্বর দিয়ে শুরু করুন</div>
    <div class="k-field" style="margin-top:20px;">
      <div class="lab">মোবাইল নম্বর · Mobile number</div>
      <div style="display:flex;align-items:center;">
        <span style="font-weight:700;color:var(--sage-dk);font-size:17px;font-family:var(--f-title);">🇧🇩 +88</span>
        <div style="width:1px;height:26px;background:var(--line);margin:0 12px;"></div>
        <input class="k-input" value="01711-000111">
      </div>
    </div>
    <button class="k-btn primary full lg" style="margin-top:16px;" onclick="go('otp')">OTP পাঠান · Send code ${kicon('arrow',{s:18,c:'#fff'})}</button>
    <div style="margin-top:12px;padding:12px 14px;background:var(--sage-bg);border-radius:16px;display:flex;gap:10px;align-items:center;">
      ${kicon('wa',{s:20,c:'#5C8067'})}
      <div style="font-size:13px;color:var(--sage-dk);font-weight:600;">WhatsApp-এ কোড পাবেন · Code via WhatsApp</div>
    </div>
    <div class="k-card k-soft" style="background:var(--butter-bg);margin-top:18px;">
      <div style="display:flex;gap:3px;margin-bottom:6px;">${'★'.repeat(5).split('').map(()=>`<span style="color:var(--rose-dk);font-size:13px;">★</span>`).join('')}</div>
      <div style="font-family:var(--f-title);font-size:14.5px;font-weight:600;line-height:1.5;">"পুলিশ ফর্ম এখন ২ মিনিটে শেষ। অনেক উপকার হয়েছে!"</div>
      <div style="margin-top:10px;display:flex;align-items:center;gap:8px;">
        ${avatar('I','var(--rose)')}
        <div style="font-size:12px;color:var(--muted-dk);"><b style="color:var(--ink);">Md. Ibrahim</b> · উত্তরা landlord</div>
      </div>
    </div>
  </div></div>`;
}});

// ── OTP ──
reg('otp', { group:'Onboarding & Auth', gcolor:'#5C8067', en:'Verify OTP', bn:'OTP যাচাই', ph:0, ico:'lock', render(){
  return statusbar() + topbar({title:'কোড যাচাই', back:'login'}) + `
  <div class="scroll"><div class="pad">
    ${emojiHero('🔐', null, 'কোড লিখুন · Enter code')}
    <div style="text-align:center;color:var(--muted);font-size:13px;margin-top:6px;">WhatsApp-এ পাঠানো ৪-সংখ্যার কোড<br>4-digit code sent to +88 01711-000111</div>
    <div style="display:flex;gap:12px;justify-content:center;margin-top:24px;">
      ${['৪','৭','২','৯'].map((d,i)=>`<div style="width:60px;height:68px;border-radius:18px;background:var(--card);border:2px solid ${i<4?'var(--sage)':'var(--line)'};display:grid;place-items:center;font-family:var(--f-title);font-weight:800;font-size:28px;box-shadow:var(--sh-sm);">${d}</div>`).join('')}
    </div>
    <div style="text-align:center;margin-top:18px;color:var(--muted);font-size:12.5px;">কোড আসেনি? <b style="color:var(--sage-dk);">আবার পাঠান (০:২৪)</b></div>
    <button class="k-btn primary full lg" style="margin-top:24px;" onclick="go('roleChooser')">যাচাই করুন · Verify ${kicon('check',{s:18,c:'#fff'})}</button>
  </div></div>`;
}});

// ── ROLE CHOOSER ──
const ROLE_CARDS = [
  { k:'home', set:'landlord', e:'🏠', bn:'বাড়িওয়ালা', en:'Landlord', d:'নিজের বিল্ডিং ও ভাড়াটিয়া পরিচালনা · Manage my own buildings', ac:'var(--sage)', acd:'var(--sage-dk)', bg:'var(--sage-bg)', perks:['DMP ফর্ম','ভাড়া আদায়','খরচের হিসাব'], rec:true },
  { k:'mgrHome', set:'manager', e:'🏢', bn:'ভবন ম্যানেজার', en:'Building Manager', d:'একাধিক মালিকের সম্পত্তি · Manage multiple owners', ac:'var(--butter)', acd:'var(--rose-dk)', bg:'var(--butter-bg)', perks:['মাল্টি-ওনার','টিম এক্সেস','একীভূত রিপোর্ট'] },
  { k:'tenHome', set:'tenant', e:'👤', bn:'ভাড়াটিয়া', en:'Tenant', d:'একটি ফ্ল্যাটে ভাড়া থাকি · I rent a flat', ac:'var(--rose)', acd:'var(--rose-dk)', bg:'var(--rose-bg)', perks:['ভাড়া পরিশোধ','রসিদ','মেরামত'] },
];
reg('roleChooser', { group:'Onboarding & Auth', gcolor:'#5C8067', en:'Role chooser', bn:'ভূমিকা নির্বাচন', ph:0, ico:'users', render(){
  return statusbar() + topbar({tr:true}) + `
  <div class="scroll"><div style="padding:4px 20px 22px;">
    <div style="text-align:center;">
      <div style="font-family:var(--f-hand);font-size:28px;color:var(--sage-dk);line-height:1;">Tell us who you are</div>
      <div style="font-family:var(--f-title);font-weight:800;font-size:21px;margin-top:4px;letter-spacing:-.4px;">আপনি কে?</div>
      <div style="font-size:12.5px;color:var(--muted);margin-top:6px;">যথাযথ ফিচার পেতে ভূমিকা নির্বাচন করুন · Pick your role</div>
    </div>
    <div style="display:grid;gap:12px;margin-top:18px;">
      ${ROLE_CARDS.map(r=>`
        <div class="k-card" onclick="go('${r.k}')" style="border:2px solid ${r.rec?r.ac:'transparent'};background:${r.bg};position:relative;cursor:pointer;">
          ${r.rec?`<div style="position:absolute;top:-10px;right:16px;background:${r.acd};color:#fff;font-size:10px;font-weight:800;padding:4px 10px;border-radius:99px;font-family:var(--f-title);">⭐ সাধারণত এটিই · Most common</div>`:''}
          <div style="display:flex;align-items:center;gap:14px;">
            <div style="width:62px;height:62px;border-radius:31px;background:#fff;display:grid;place-items:center;font-size:30px;box-shadow:0 6px 14px -6px ${r.acd};flex-shrink:0;">${r.e}</div>
            <div style="flex:1;">
              <div style="font-family:var(--f-title);font-weight:800;font-size:18px;line-height:1.1;">${r.bn}</div>
              <div style="font-family:var(--f-hand);font-size:18px;color:${r.acd};line-height:1;margin-top:3px;">${r.en}</div>
              <div style="font-size:11.5px;color:var(--muted-dk);margin-top:6px;line-height:1.4;">${r.d}</div>
            </div>
            ${kicon('arrow',{s:20,c:r.acd})}
          </div>
          <div style="display:flex;flex-wrap:wrap;gap:6px;margin-top:13px;padding-top:12px;border-top:1px dashed rgba(0,0,0,.08);">
            ${r.perks.map(p=>`<span style="background:rgba(255,255,255,.8);color:${r.acd};font-size:10.5px;font-weight:700;padding:4px 10px;border-radius:99px;">✓ ${p}</span>`).join('')}
          </div>
        </div>`).join('')}
    </div>
    <div style="text-align:center;font-size:11.5px;color:var(--muted);margin-top:16px;">পরে More মেনু থেকে পরিবর্তন করা যাবে · Change later in More</div>
  </div></div>`;
}});
