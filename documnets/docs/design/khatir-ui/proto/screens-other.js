/* ═══ Khatir prototype — Manager, Tenant (app), Tenant (web link), Caretaker ═══ */

/* ────────── MANAGER ────────── */
let mgrOwner=0;
const OWNERS=[{n:'Md. Ibrahim',u:14,occ:11,mrr:'৯৭K',c:'var(--sage)'},{n:'Tariq Aziz',u:38,occ:35,mrr:'২.৮L',c:'var(--rose)'},{n:'Sabina Yasmin',u:31,occ:28,mrr:'২.১L',c:'var(--butter-dk)'}];
reg('mgrHome', { group:'Manager · ভবন ম্যানেজার', gcolor:'#C9755F', en:'Manager home', bn:'ম্যানেজার হোম', ph:1, ico:'home', render(){
  return statusbar() + topbar({brand:true, action:bellbtn()}) + `
  <div class="scroll"><div style="padding:2px 20px 12px;">
    <span class="k-chip butter">${kicon('users',{s:13,c:'#C9755F'})} Manager · ম্যানেজার</span>
    <div style="font-family:var(--f-hand);font-size:23px;color:var(--sage-dk);line-height:1;margin-top:8px;">আসসালামু আলাইকুম,</div>
    <div style="font-family:var(--f-title);font-weight:800;font-size:22px;letter-spacing:-.5px;margin-top:3px;">আসিফ ভাই 👋</div>
    <div style="color:var(--muted);font-size:12px;margin-top:3px;">৩ মালিক · 83 units · 74 occupied</div>
  </div>
  <div style="padding:0 20px;">
    <div class="hero-card" style="background:linear-gradient(135deg,var(--ink),#3D4A42);">
      <span class="k-chip" style="background:rgba(255,255,255,.18);color:#fff;">পুরো পোর্টফোলিও · Whole portfolio</span>
      <div style="font-family:var(--f-hand);font-size:21px;margin-top:8px;opacity:.85;">Total under management</div>
      <div style="font-family:var(--f-title);font-weight:800;font-size:36px;letter-spacing:-1px;margin-top:2px;">৳৫.৯L<span style="font-size:14px;opacity:.7;">/mo</span></div>
      <div style="margin-top:10px;display:flex;gap:14px;font-size:12px;"><div><b style="color:var(--butter);">৭৪</b>/৮৩ occupied</div><div style="opacity:.4;">·</div><div><b style="color:var(--sage);">৮৯%</b> collected</div></div>
      <div style="position:absolute;right:-10px;top:-6px;opacity:.1;">${kicon('building',{s:120,c:'#fff',sw:1})}</div>
    </div>
  </div>
  <div style="padding:16px 20px 0;">
    <div class="sectit">মালিক পোর্টফোলিও · Owners</div>
    <div style="display:flex;gap:10px;overflow-x:auto;padding-bottom:6px;">
      ${OWNERS.map((o,i)=>`<div class="k-card" onclick="mgrOwner=${i};repaint()" style="min-width:172px;flex-shrink:0;cursor:pointer;${i===mgrOwner?'border:2px solid var(--sage);':''}"><div class="rowcard" style="margin-bottom:8px;">${avatar(o.n[0],o.c)}<div style="font-family:var(--f-title);font-weight:700;font-size:13px;">${o.n}</div></div><div style="display:flex;justify-content:space-between;font-size:11px;color:var(--muted);"><span>${o.occ}/${o.u} units</span><b style="color:var(--rose-dk);">৳${o.mrr}</b></div></div>`).join('')}
      <div class="k-card" style="min-width:96px;flex-shrink:0;display:grid;place-items:center;text-align:center;border:2px dashed var(--line);cursor:pointer;" onclick="go('mgrAddOwner')"><div>${kicon('plus',{s:22,c:'#8C8578'})}<div style="font-size:11px;color:var(--muted);font-weight:600;margin-top:2px;">মালিক যোগ</div></div></div>
    </div>
  </div>
  <div style="padding:14px 20px 0;">
    <div class="sectit">দ্রুত কাজ — ${OWNERS[mgrOwner].n}</div>
    <div style="display:grid;grid-template-columns:1fr 1fr;gap:10px;">
      ${[['addBuilding','building','বিল্ডিং যোগ','Add building','var(--sage-bg)','#5C8067'],['rentReq','send','ভাড়া চান','Collect rent','var(--rose-bg)','#C9755F'],['expenses','wrench','মেরামত','Maintenance','var(--butter-bg)','#C9755F'],['mgrReport','chart','রিপোর্ট','Report','var(--sage-bg)','#5C8067']].map(([k,ic,bn,en,bg,fg])=>`<div class="k-card k-soft qa" style="background:${bg};" onclick="go('${k}')">${iconBadge(ic,'rgba(255,255,255,.65)',fg,20,40)}<div class="qt" style="color:${fg};margin-top:8px;">${bn}</div><div class="qe">${en}</div></div>`).join('')}
    </div>
  </div>
  <div style="padding:14px 20px 0;">
    <div class="k-card rowcard" style="cursor:pointer;" onclick="go('mgrTeam')">${iconBadge('users','var(--sage-bg)','#5C8067',20,44)}<div style="flex:1;"><div style="font-family:var(--f-title);font-weight:700;font-size:14px;">টিম মেম্বার · Team</div><div style="font-size:11.5px;color:var(--muted);">২ জন সহকারী · 1 accountant</div></div><button class="k-btn soft sm">পরিচালনা</button></div>
  </div>
  <div style="padding:12px 20px 22px;">
    <div class="k-card k-soft rowcard" style="background:var(--butter-bg);"><div style="font-size:30px;">💼</div><div style="flex:1;"><div style="font-family:var(--f-title);font-size:13.5px;font-weight:700;">B2B Manager Tier</div><div style="font-size:11px;color:var(--muted);">একীভূত রিপোর্ট · টিম সিট · বার্ষিক বিলিং</div></div><span class="k-chip solid">Active</span></div>
  </div>
  </div>` + bottomnav('mgrHome','manager');
}});

reg('mgrAddOwner', { group:'Manager · ভবন ম্যানেজার', gcolor:'#C9755F', en:'Add owner', bn:'মালিক যোগ', ph:1, ico:'plus', render(){
  return statusbar() + topbar({title:'মালিক যোগ · Add owner', back:'mgrHome'}) + `
  <div class="scroll"><div class="pad">
    ${emojiHero('🤝','Link an owner','মালিকের তথ্য দিন')}
    ${field('মালিকের নাম ★ · Owner name','')}
    ${field('মোবাইল ★ · Mobile','01xxx-xxxxxx')}
    <div class="k-field" style="margin-bottom:10px;"><div class="lab">অনুমতি · Permissions</div><div style="display:flex;flex-wrap:wrap;gap:7px;margin-top:4px;">${['ভাড়া আদায়','খরচ','রিপোর্ট','সম্পূর্ণ'].map((c,i)=>`<button style="padding:8px 13px;border-radius:99px;border:0;background:${i===3?'var(--sage)':'var(--sage-bg)'};color:${i===3?'#fff':'var(--sage-dk)'};font-size:12px;font-weight:700;font-family:var(--f-title);">${c}</button>`).join('')}</div></div>
    <div class="k-card k-soft rowcard" style="background:var(--sage-bg);">${kicon('wa',{s:18,c:'#5C8067'})}<div style="font-size:11.5px;color:var(--sage-dk);font-weight:600;">মালিককে WhatsApp-এ আমন্ত্রণ পাঠানো হবে · Invite via WhatsApp</div></div>
    <button class="k-btn primary full lg" style="margin-top:14px;" onclick="go('mgrHome')">${kicon('send',{s:18,c:'#fff'})} আমন্ত্রণ পাঠান · Send invite</button>
  </div></div>`;
}});

reg('mgrTeam', { group:'Manager · ভবন ম্যানেজার', gcolor:'#C9755F', en:'Team members', bn:'টিম', ph:1, ico:'users', render(){
  const team=[['Nasir Ahmed','Accountant','অ্যাকাউন্ট্যান্ট','var(--sage)'],['Sumi Akter','Assistant','সহকারী','var(--rose)'],['Rakib Hasan','Viewer','ভিউয়ার','var(--butter-dk)']];
  return statusbar() + topbar({title:'টিম · Team', back:'mgrHome', action:`<button class="iconbtn">${kicon('plus',{s:20})}</button>`}) + `
  <div class="scroll"><div class="pad">
    <div class="sectit">টিম মেম্বার · ${team.length} members</div>
    <div style="display:grid;gap:10px;">
      ${team.map(([n,en,bn,c])=>`<div class="k-card rowcard">${avatar(n[0],c)}<div style="flex:1;"><div style="font-family:var(--f-title);font-weight:700;font-size:14.5px;">${n}</div><div style="font-size:11.5px;color:var(--muted);">${bn} · ${en}</div></div>${kicon('cog',{s:18,c:'#8C8578'})}</div>`).join('')}
    </div>
    <div class="k-card k-soft rowcard" style="background:var(--sage-bg);margin-top:12px;">${kicon('shield',{s:18,c:'#5C8067'})}<div style="font-size:11.5px;color:var(--sage-dk);font-weight:600;line-height:1.5;">প্রতিটি সিটের আলাদা অনুমতি — owner/manager/staff scope · Role-based access</div></div>
  </div></div>`;
}});

reg('mgrReport', { group:'Manager · ভবন ম্যানেজার', gcolor:'#C9755F', en:'Consolidated report', bn:'একীভূত রিপোর্ট', ph:1, ico:'chart', render(){
  return statusbar() + topbar({title:'রিপোর্ট · Report', back:'mgrHome', action:`<button class="iconbtn">${kicon('download',{s:18})}</button>`}) + `
  <div class="scroll"><div class="pad">
    <div class="k-card" style="background:linear-gradient(135deg,var(--ink),#3D4A42);color:#fff;border:0;"><div style="font-size:12px;opacity:.8;">৩ মালিক · মোট মাসিক আয় · Combined income</div><div style="font-family:var(--f-title);font-weight:800;font-size:32px;letter-spacing:-1px;margin-top:2px;">৳৫.৯L <span style="font-size:13px;color:var(--butter);">↑ ৮%</span></div></div>
    <div class="sectit" style="margin-top:16px;">মালিক অনুযায়ী · By owner</div>
    <div class="k-card" style="padding:0;">${OWNERS.map((o,i)=>`<div class="fieldrow" style="border-bottom:${i<OWNERS.length-1?'1px solid var(--line)':'0'};">${avatar(o.n[0],o.c)}<div style="flex:1;"><div style="font-family:var(--f-title);font-weight:700;font-size:14px;">${o.n}</div><div style="font-size:11px;color:var(--muted);">${o.occ}/${o.u} occupied</div></div><b style="font-family:var(--f-title);color:var(--rose-dk);">৳${o.mrr}</b></div>`).join('')}</div>
    <div class="sectit" style="margin-top:16px;">সম্মিলিত অকুপেন্সি · Combined occupancy</div>
    <div class="k-card"><div style="display:flex;justify-content:space-between;margin-bottom:6px;"><span style="font-size:13px;font-weight:600;">৭৪ / ৮৩ ইউনিট</span><span class="k-chip">৮৯%</span></div><div class="k-track"><i style="width:89%"></i></div></div>
  </div></div>` + bottomnav('dashboard','manager');
}});

/* ────────── TENANT (app) ────────── */
reg('tenHome', { group:'Tenant · ভাড়াটিয়া (app)', gcolor:'#E89B8B', en:'Tenant home', bn:'ভাড়াটিয়া হোম', ph:0, ico:'home', render(){
  return statusbar() + topbar({brand:true, action:bellbtn()}) + `
  <div class="scroll"><div style="padding:2px 20px 12px;">
    <span class="k-chip rose">${kicon('user',{s:13,c:'#C9755F'})} Tenant · ভাড়াটিয়া</span>
    <div style="font-family:var(--f-hand);font-size:23px;color:var(--sage-dk);line-height:1;margin-top:8px;">আসসালামু আলাইকুম,</div>
    <div style="font-family:var(--f-title);font-weight:800;font-size:22px;letter-spacing:-.5px;margin-top:3px;">নাসরিন আক্তার 👋</div>
    <div style="color:var(--muted);font-size:12px;margin-top:3px;">Mirpur 10 · ফ্ল্যাট 4B</div>
  </div>
  <div style="padding:0 20px;">
    <div class="hero-card" onclick="go('tenPay')" style="cursor:pointer;background:linear-gradient(135deg,var(--rose),var(--rose-dk));">
      <span class="k-chip" style="background:rgba(255,255,255,.22);color:#fff;">${kicon('clock',{s:13,c:'#fff'})} এ মাসের ভাড়া · Rent due</span>
      <div style="font-family:var(--f-title);font-weight:800;font-size:36px;letter-spacing:-1px;margin-top:10px;">৳২৬,০০০</div>
      <div style="font-size:12.5px;opacity:.9;margin-top:6px;">বাকি · মে ২০২৬ · ৫ মে পর্যন্ত</div>
      <div style="margin-top:14px;background:#fff;color:var(--rose-dk);padding:11px 16px;border-radius:99px;font-family:var(--f-title);font-weight:800;font-size:14px;display:inline-flex;align-items:center;gap:8px;">${kicon('download',{s:16,c:'#C9755F'})} পেমেন্ট প্রমাণ আপলোড ${kicon('arrow',{s:16,c:'#C9755F'})}</div>
      <div style="position:absolute;right:-4px;bottom:-8px;opacity:.13;">${kicon('cash',{s:110,c:'#fff',sw:1})}</div>
    </div>
  </div>
  <div style="padding:12px 20px 0;">
    <div class="k-card"><div class="rowcard" style="margin-bottom:12px;">${iconBadge('doc','var(--sage-bg)','#5C8067',20,44)}<div style="flex:1;"><div style="font-family:var(--f-title);font-weight:800;font-size:14px;">আমার লিজ · My lease</div><div style="font-size:11px;color:var(--muted);">মার্চ ২০২৬ — চলমান</div></div><button class="k-btn soft sm" onclick="go('tenLease')">দেখুন</button></div><div style="padding-top:10px;border-top:1px solid var(--line);display:grid;grid-template-columns:1fr 1fr;gap:8px;font-size:12px;"><div><span style="color:var(--muted);">মালিক:</span> <b>আব্দুল করিম</b></div><div><span style="color:var(--muted);">অগ্রিম:</span> <b>৳৫২,০০০</b></div></div></div>
  </div>
  <div style="padding:14px 20px 0;">
    <div class="sectit">দ্রুত কাজ · Quick actions</div>
    <div style="display:grid;grid-template-columns:1fr 1fr;gap:10px;">
      ${[['tenMaint','wrench','মেরামত চাই','Request fix','var(--butter-bg)','#C9755F'],['tenReceipts','receipt','রসিদ দেখুন','Receipts','var(--sage-bg)','#5C8067'],['tenPay','cash','ভাড়া দিন','Pay rent','var(--rose-bg)','#C9755F'],['tenReview','star','রিভিউ দিন','Review','var(--sage-bg)','#5C8067']].map(([k,ic,bn,en,bg,fg])=>`<div class="k-card k-soft qa" style="background:${bg};" onclick="go('${k}')">${iconBadge(ic,'rgba(255,255,255,.65)',fg,20,40)}<div class="qt" style="color:${fg};margin-top:8px;">${bn}</div><div class="qe">${en}</div></div>`).join('')}
    </div>
  </div>
  <div style="padding:14px 20px 0;">
    <div class="sectit">সাম্প্রতিক রসিদ · Recent receipts</div>
    <div class="k-card" style="padding:0;">${[['এপ্রিল ২০২৬','৳২৬,০০০'],['মার্চ ২০২৬','৳২৬,০০০'],['ফেব ২০২৬','৳২৬,০০০']].map((r,i)=>`<div class="fieldrow" style="border-bottom:${i<2?'1px solid var(--line)':'0'};">${iconBadge('receipt','var(--sage-bg)','#5C8067',16,36)}<div style="flex:1;"><div style="font-family:var(--f-title);font-weight:700;font-size:13.5px;">${r[0]}</div><div style="font-size:11px;color:var(--sage);font-weight:700;">✓ পরিশোধিত · Paid</div></div><b style="font-family:var(--f-title);">${r[1]}</b></div>`).join('')}</div>
  </div>
  <div style="padding:12px 20px 22px;">
    <div class="k-card k-soft rowcard" style="background:var(--sage-bg);cursor:pointer;" onclick="go('tenRecord')"><div style="font-size:34px;">🌟</div><div style="flex:1;"><div style="font-family:var(--f-hand);font-size:22px;color:var(--sage-dk);line-height:.9;">You're a star!</div><div style="font-family:var(--f-title);font-size:13px;font-weight:700;margin-top:2px;">৩ মাস সময়মতো ভাড়া · 3 months on time</div><div style="font-size:11px;color:var(--muted);">পরের বাসায় ভালো রেকর্ড পাবেন</div></div></div>
  </div>
  </div>` + bottomnav('tenHome','tenant');
}});

reg('tenLease', { group:'Tenant · ভাড়াটিয়া (app)', gcolor:'#E89B8B', en:'Lease detail', bn:'লিজ', ph:0, ico:'doc', render(){
  return statusbar() + topbar({title:'আমার লিজ · Lease', back:'tenHome'}) + `
  <div class="scroll"><div class="pad">
    <div class="k-card" style="background:linear-gradient(135deg,var(--sage),var(--sage-dk));color:#fff;border:0;"><span class="k-chip" style="background:rgba(255,255,255,.22);color:#fff;">চলমান · Active</span><div style="font-family:var(--f-title);font-weight:800;font-size:24px;margin-top:8px;">৳২৬,০০০<span style="font-size:14px;opacity:.8;">/মাস</span></div><div style="font-size:12px;opacity:.9;margin-top:4px;">ফ্ল্যাট 4B · করিম মঞ্জিল · Mirpur 10</div></div>
    <div class="k-card" style="margin-top:12px;">${[['মালিক · Landlord','আব্দুল করিম'],['শুরু · Start','মার্চ ২০২৬'],['মেয়াদ · Term','১১ মাস'],['অগ্রিম · Advance','৳৫২,০০০'],['নোটিশ · Notice','২ মাস']].map((r,i)=>`<div style="display:flex;justify-content:space-between;padding:9px 0;border-bottom:${i<4?'1px dotted var(--line)':'0'};font-size:13px;"><span style="color:var(--muted);">${r[0]}</span><b style="font-family:var(--f-title);">${r[1]}</b></div>`).join('')}</div>
    <button class="k-btn soft full" style="margin-top:14px;">${kicon('download',{s:16,c:'#5C8067'})} চুক্তি PDF · Lease PDF</button>
  </div></div>`;
}});

reg('tenPay', { group:'Tenant · ভাড়াটিয়া (app)', gcolor:'#E89B8B', en:'Pay rent', bn:'ভাড়া পরিশোধ', ph:0, ico:'cash', render(){
  return statusbar() + topbar({title:'ভাড়া পরিশোধ · Pay rent', back:'tenHome'}) + `
  <div class="scroll"><div class="pad">
    <div class="k-card" style="text-align:center;"><div style="font-size:12px;color:var(--muted);">মে ২০২৬-এর ভাড়া · Rent due</div><div style="font-family:var(--f-title);font-weight:800;font-size:34px;color:var(--rose-dk);letter-spacing:-1px;margin-top:4px;">৳২৬,০০০</div><div style="font-size:11.5px;color:var(--muted);margin-top:2px;">আব্দুল করিম · বিকাশ 01711-000111</div></div>
    <div class="sectit" style="margin-top:16px;">প্রমাণ দিন · Submit proof</div>
    <div style="display:grid;gap:10px;">
      <div class="k-card rowcard" style="cursor:pointer;border:2px solid var(--rose);">${iconBadge('download','var(--rose-bg)','#C9755F',20,44)}<div style="flex:1;"><div style="font-family:var(--f-title);font-weight:700;font-size:14px;">স্ক্রিনশট আপলোড · Upload screenshot</div><div style="font-size:11px;color:var(--muted);">bKash / Nagad payment proof</div></div></div>
      <div class="k-card rowcard" style="cursor:pointer;">${iconBadge('copy','var(--sage-bg)','#5C8067',20,44)}<div style="flex:1;"><div style="font-family:var(--f-title);font-weight:700;font-size:14px;">Txn ID লিখুন · Enter txn ID</div><div style="font-size:11px;color:var(--muted);">e.g. 8GH4K2L9PQ</div></div></div>
      <div class="k-card rowcard" style="cursor:pointer;">${iconBadge('pencil','var(--butter-bg)','#C9755F',20,44)}<div style="flex:1;"><div style="font-family:var(--f-title);font-weight:700;font-size:14px;">নোট লিখুন · Add note</div><div style="font-size:11px;color:var(--muted);">নগদ দিয়েছি / cash handed over</div></div></div>
    </div>
    <button class="k-btn rose full lg" style="margin-top:16px;" onclick="go('tenHome')">${kicon('send',{s:18,c:'#fff'})} প্রমাণ জমা দিন · Submit proof</button>
    <div style="text-align:center;font-size:11px;color:var(--muted);margin-top:8px;">মালিক যাচাই করলে রসিদ পাবেন · Receipt after landlord verifies</div>
  </div></div>`;
}});

reg('tenMaint', { group:'Tenant · ভাড়াটিয়া (app)', gcolor:'#E89B8B', en:'Request maintenance', bn:'মেরামত চাই', ph:0, ico:'wrench', render(){
  const cats=['🚿 পানি','💡 বিদ্যুৎ','🎨 রং','🔧 অন্যান্য'];
  return statusbar() + topbar({title:'মেরামত চাই · Maintenance', back:'tenHome'}) + `
  <div class="scroll"><div class="pad">
    ${emojiHero('🔧','What needs fixing?','সমস্যা জানান')}
    <div class="k-field" style="margin-top:14px;"><div class="lab">ধরন · Category</div><div style="display:flex;flex-wrap:wrap;gap:7px;margin-top:4px;">${cats.map((c,i)=>`<button style="padding:8px 13px;border-radius:99px;border:0;background:${i===0?'var(--rose)':'var(--rose-bg)'};color:${i===0?'#fff':'var(--rose-dk)'};font-size:12px;font-weight:700;font-family:var(--f-title);">${c}</button>`).join('')}</div></div>
    <div class="k-field" style="margin:10px 0;"><div class="lab">বিবরণ · Description</div><textarea class="k-input" style="font-family:var(--f-body);font-weight:400;font-size:14px;resize:none;" rows="3" placeholder="কী সমস্যা হচ্ছে লিখুন">রান্নাঘরের কলে পানি পড়ছে।</textarea></div>
    <div class="k-card rowcard" style="cursor:pointer;border:1px dashed var(--line-dk);">${iconBadge('cam','var(--sage-bg)','#5C8067',20,44)}<div style="flex:1;"><div style="font-family:var(--f-title);font-weight:700;font-size:13.5px;">ছবি যোগ করুন · Add photo</div><div style="font-size:11px;color:var(--muted);">ঐচ্ছিক · Optional</div></div></div>
    <button class="k-btn rose full lg" style="margin-top:14px;" onclick="go('tenHome')">${kicon('send',{s:18,c:'#fff'})} অনুরোধ পাঠান · Send request</button>
  </div></div>`;
}});

reg('tenReceipts', { group:'Tenant · ভাড়াটিয়া (app)', gcolor:'#E89B8B', en:'Receipts', bn:'রসিদ', ph:0, ico:'receipt', render(){
  const r=[['মে ২০২৬','৳২৬,০০০','pending'],['এপ্রিল ২০২৬','৳২৬,০০০','paid'],['মার্চ ২০২৬','৳২৬,০০০','paid'],['ফেব ২০২৬','৳২৬,০০০','paid'],['জানু ২০২৬','৳২৬,০০০','paid']];
  return statusbar() + topbar({title:'রসিদ · Receipts', back:'tenHome'}) + `
  <div class="scroll"><div class="pad">
    <div class="k-card k-soft rowcard" style="background:var(--sage-bg);"><div style="font-size:28px;">📃</div><div style="flex:1;"><div style="font-family:var(--f-title);font-weight:700;font-size:14px;">৪ মাস পরিশোধিত · 4 months paid</div><div style="font-size:11.5px;color:var(--muted-dk);">মোট ৳১,০৪,০০০ · all on time</div></div></div>
    <div style="display:grid;gap:10px;margin-top:14px;">
      ${r.map(([m,a,st])=>`<div class="k-card rowcard">${iconBadge('receipt',st==='paid'?'var(--sage-bg)':'var(--butter-bg)',st==='paid'?'#5C8067':'#C9755F',18,40)}<div style="flex:1;"><div style="font-family:var(--f-title);font-weight:700;font-size:14px;">${m}</div><div style="font-size:11px;color:${st==='paid'?'var(--sage)':'var(--rose-dk)'};font-weight:700;">${st==='paid'?'✓ পরিশোধিত · Paid':'⏳ অপেক্ষায় · Pending'}</div></div><div style="text-align:right;"><b style="font-family:var(--f-title);">${a}</b>${st==='paid'?`<div style="margin-top:4px;">${kicon('download',{s:15,c:'#8C8578'})}</div>`:''}</div></div>`).join('')}
    </div>
  </div></div>`;
}});

reg('tenReview', { group:'Tenant · ভাড়াটিয়া (app)', gcolor:'#E89B8B', en:'Review landlord', bn:'রিভিউ', ph:1, ico:'star', render(){
  return statusbar() + topbar({title:'রিভিউ · Review', back:'tenHome'}) + `
  <div class="scroll"><div class="pad">
    <div class="k-card k-soft rowcard" style="background:var(--rose-bg);">${kicon('lock',{s:18,c:'#C9755F'})}<div style="font-size:11.5px;color:var(--rose-dk);font-weight:600;line-height:1.5;"><b>পারস্পরিক ও ব্যক্তিগত · Mutual &amp; private.</b> শুধু অ্যাপ-ব্যবহারকারীদের মধ্যে · only between app users.</div></div>
    <div class="k-card" style="margin-top:12px;text-align:center;"><div style="font-family:var(--f-title);font-weight:700;font-size:14px;">আব্দুল করিম · মালিক</div><div style="display:flex;gap:8px;justify-content:center;margin-top:12px;">${[1,2,3,4,5].map(i=>`<span style="font-size:30px;color:${i<=4?'var(--butter-dk)':'var(--line-dk)'};">★</span>`).join('')}</div></div>
    <div class="k-field" style="margin-top:12px;"><div class="lab">কেমন অভিজ্ঞতা? · Your experience</div><div style="display:flex;flex-wrap:wrap;gap:7px;margin-top:4px;">${['সাড়া দেন দ্রুত','মেরামত করেন','ভদ্র','ন্যায্য'].map((c,i)=>`<button style="padding:8px 13px;border-radius:99px;border:0;background:${i<2?'var(--sage)':'var(--sage-bg)'};color:${i<2?'#fff':'var(--sage-dk)'};font-size:12px;font-weight:700;font-family:var(--f-title);">✓ ${c}</button>`).join('')}</div></div>
    <button class="k-btn primary full lg" style="margin-top:14px;" onclick="go('tenHome')">${kicon('star',{s:18,c:'#fff'})} রিভিউ জমা দিন · Submit</button>
  </div></div>`;
}});

reg('tenRecord', { group:'Tenant · ভাড়াটিয়া (app)', gcolor:'#E89B8B', en:'Good-tenant record', bn:'ভালো রেকর্ড', ph:2, ico:'badge', render(){
  return statusbar() + topbar({title:'আমার রেকর্ড · My record', back:'tenHome'}) + `
  <div class="scroll"><div class="pad">
    <div class="k-card" style="text-align:center;background:linear-gradient(135deg,var(--sage),var(--sage-dk));color:#fff;border:0;"><div style="font-size:48px;">🌟</div><div style="font-family:var(--f-hand);font-size:28px;line-height:1;margin-top:4px;">Trusted tenant</div><div style="font-family:var(--f-title);font-weight:800;font-size:18px;margin-top:6px;">ভালো ভাড়াটিয়া রেকর্ড</div></div>
    <div style="display:grid;grid-template-columns:1fr 1fr;gap:10px;margin-top:12px;">
      ${[['১২','মাস সময়মতো','On-time months'],['২','সম্পন্ন লিজ','Completed leases'],['৪.৮','গড় রেটিং','Avg rating'],['০','বিরোধ','Disputes']].map(s=>`<div class="k-card statbox"><div class="n" style="color:var(--sage-dk);">${s[0]}</div><div class="l">${s[1]}<br><span style="font-style:italic;">${s[2]}</span></div></div>`).join('')}
    </div>
    <div class="k-card k-soft rowcard" style="background:var(--butter-bg);margin-top:12px;">${kicon('shield',{s:18,c:'#C9755F'})}<div style="font-size:11.5px;color:var(--muted-dk);line-height:1.5;">শুধু আপনার সম্মতিতে পরবর্তী মালিক দেখতে পাবেন · Shared only with your per-request consent.</div></div>
  </div></div>`;
}});

/* ────────── TENANT WEB LINK (no install) ────────── */
function webChrome(inner, title){
  return statusbar() + `
  <div style="background:#e7e0d2;padding:8px 12px;display:flex;align-items:center;gap:8px;flex-shrink:0;border-bottom:1px solid var(--line-dk);">
    ${kicon('lock',{s:13,c:'#6B6558'})}
    <div style="flex:1;background:#fff;border-radius:99px;padding:6px 12px;font-family:var(--f-mono);font-size:11px;color:var(--muted-dk);white-space:nowrap;overflow:hidden;text-overflow:ellipsis;">khatir.app/r/${title}</div>
    ${kicon('refresh',{s:14,c:'#6B6558'})}
  </div>
  <div style="background:var(--sage-dk);color:#fff;padding:6px 14px;font-size:10.5px;text-align:center;flex-shrink:0;">📱 কোনো অ্যাপ লাগবে না · No app needed — opens in browser</div>
  <div class="scroll">${inner}</div>`;
}
reg('webPay', { group:'Tenant · web link (no install)', gcolor:'#D9B45F', en:'Rent pay link', bn:'ভাড়ার লিংক', ph:0, ico:'cash', render(){
  return webChrome(`<div class="pad" style="padding-top:16px;">
    <div style="text-align:center;"><img src="assets/khatir-icon-128.png" width="48" style="border-radius:13px;box-shadow:var(--sh-sage);"><div style="font-family:var(--f-title);font-weight:800;font-size:17px;margin-top:8px;">আব্দুল করিম চাইছেন</div><div style="font-size:12px;color:var(--muted);">Abdul Karim requests rent</div></div>
    <div class="k-card" style="margin-top:14px;text-align:center;"><div style="font-size:12px;color:var(--muted);">মে ২০২৬ · ফ্ল্যাট 4B</div><div style="font-family:var(--f-title);font-weight:800;font-size:38px;color:var(--rose-dk);letter-spacing:-1px;margin-top:4px;">৳২৬,০০০</div></div>
    <div class="k-card k-soft rowcard" style="background:var(--sage-bg);margin-top:12px;">${kicon('cash',{s:18,c:'#5C8067'})}<div style="font-size:12px;color:var(--sage-dk);font-weight:600;line-height:1.5;">নিজের বিকাশ/নগদ থেকে পাঠান · Pay from your own bKash → 01711-000111</div></div>
    <div class="sectit" style="margin-top:16px;">প্রমাণ দিন · Submit proof</div>
    <div style="display:grid;gap:10px;">
      <button class="k-btn soft full" style="justify-content:flex-start;gap:12px;">${kicon('download',{s:18,c:'#5C8067'})} স্ক্রিনশট আপলোড · Upload screenshot</button>
      <button class="k-btn soft full" style="justify-content:flex-start;gap:12px;">${kicon('copy',{s:18,c:'#5C8067'})} Txn ID লিখুন · Enter txn ID</button>
    </div>
    <button class="k-btn rose full lg" style="margin-top:14px;" onclick="go('webReceipt')">${kicon('send',{s:18,c:'#fff'})} জমা দিন · Submit</button>
    <div style="text-align:center;font-size:10.5px;color:var(--muted);margin-top:10px;font-family:var(--f-mono);">Loads in &lt;2s on 3G · no account, no install</div>
  </div>`,'a8Fk2');
}});
reg('webReceipt', { group:'Tenant · web link (no install)', gcolor:'#D9B45F', en:'Receipt view', bn:'রসিদ দেখুন', ph:0, ico:'receipt', render(){
  return webChrome(`<div class="pad" style="padding-top:16px;">
    ${emojiHero('🎉','Submitted!','মালিক যাচাই করছেন')}
    <div class="k-card" style="margin-top:8px;text-align:center;"><div style="font-family:var(--f-title);font-weight:700;font-size:14px;color:var(--rose-dk);">⏳ অপেক্ষায় · Pending verification</div><div style="font-size:12px;color:var(--muted);margin-top:6px;line-height:1.5;">মালিক "টাকা পেয়েছি" চাপলে আপনি রসিদ পাবেন · You'll get a receipt once verified.</div></div>
    <div class="k-card" style="margin-top:12px;"><div style="font-family:var(--f-title);font-weight:800;font-size:13px;margin-bottom:10px;">জমা প্রমাণ · Your submission</div>${[['পরিমাণ · Amount','৳২৬,০০০'],['পদ্ধতি · Via','bKash · 8GH4K2L9PQ'],['সময় · At','১৫ মে, ৩:২২ PM']].map(r=>`<div style="display:flex;justify-content:space-between;padding:7px 0;font-size:13px;border-bottom:1px dotted var(--line);"><span style="color:var(--muted);">${r[0]}</span><b style="font-family:var(--f-title);">${r[1]}</b></div>`).join('')}</div>
  </div>`,'a8Fk2');
}});
reg('webMaint', { group:'Tenant · web link (no install)', gcolor:'#D9B45F', en:'Maintenance form', bn:'মেরামত ফর্ম', ph:0, ico:'wrench', render(){
  const cats=['🚿 পানি','💡 বিদ্যুৎ','🎨 রং','🔧 অন্যান্য'];
  return webChrome(`<div class="pad" style="padding-top:16px;">
    ${emojiHero('🔧','Report a problem','সমস্যা জানান')}
    <div style="text-align:center;font-size:12px;color:var(--muted);">করিম মঞ্জিল · ফ্ল্যাট 4B</div>
    <div class="k-field" style="margin-top:14px;"><div class="lab">ধরন · Category</div><div style="display:flex;flex-wrap:wrap;gap:7px;margin-top:4px;">${cats.map((c,i)=>`<button style="padding:8px 13px;border-radius:99px;border:0;background:${i===0?'var(--sage)':'var(--sage-bg)'};color:${i===0?'#fff':'var(--sage-dk)'};font-size:12px;font-weight:700;font-family:var(--f-title);">${c}</button>`).join('')}</div></div>
    <div class="k-field" style="margin:10px 0;"><div class="lab">বিবরণ · Description</div><textarea class="k-input" style="font-family:var(--f-body);font-weight:400;font-size:14px;resize:none;" rows="3" placeholder="কী সমস্যা?"></textarea></div>
    <button class="k-btn primary full lg" onclick="go('webReceipt')">${kicon('send',{s:18,c:'#fff'})} পাঠান · Send</button>
  </div>`,'m3Qx7');
}});
reg('webVisitor', { group:'Tenant · web link (no install)', gcolor:'#D9B45F', en:'Visitor QR form', bn:'ভিজিটর ফর্ম', ph:2, ico:'qr', render(){
  return webChrome(`<div class="pad" style="padding-top:16px;">
    ${emojiHero('👋','Welcome, visitor','অতিথি তথ্য দিন')}
    <div style="text-align:center;font-size:12px;color:var(--muted);">করিম মঞ্জিল গেট · Building gate</div>
    ${field('নাম ★ · Your name','')}
    ${field('মোবাইল ★ · Mobile','')}
    <div style="display:flex;gap:10px;"><div style="flex:1;">${field('যে ফ্ল্যাটে · Flat','4B')}</div><div style="flex:1;">${field('কার কাছে · Meet','নাসরিন')}</div></div>
    ${field('উদ্দেশ্য · Purpose','')}
    <div class="k-card rowcard" style="cursor:pointer;border:1px dashed var(--line-dk);margin-top:10px;">${iconBadge('cam','var(--sage-bg)','#5C8067',20,44)}<div style="flex:1;"><div style="font-family:var(--f-title);font-weight:700;font-size:13.5px;">সেলফি তুলুন · Take selfie</div></div></div>
    <button class="k-btn primary full lg" style="margin-top:14px;" onclick="go('careReview')">${kicon('check',{s:18,c:'#fff'})} জমা দিন · Submit to gate</button>
  </div>`,'g1Vqz');
}});

/* ────────── CARETAKER / GATEKEEPER ────────── */
reg('careHome', { group:'Caretaker · কেয়ারটেকার', gcolor:'#3D4A42', en:'Caretaker home', bn:'কেয়ারটেকার হোম', ph:2, ico:'shield', render(){
  const q=[['Jamal Uddin','কুরিয়ার ডেলিভারি','4B','now','var(--rose)'],['Shahana Begum','আত্মীয়, দেখা করতে','2C','5m','var(--sage)']];
  return statusbar() + topbar({brand:true, action:bellbtn()}) + `
  <div class="scroll"><div style="padding:2px 20px 12px;">
    <span class="k-chip ink">${kicon('shield',{s:13,c:'#2C3530'})} Caretaker · দারোয়ান</span>
    <div style="font-family:var(--f-title);font-weight:800;font-size:21px;margin-top:8px;">করিম মঞ্জিল গেট</div>
    <div style="color:var(--muted);font-size:12px;margin-top:2px;">আজ ৬ জন ভিজিটর · 6 visitors today</div>
  </div>
  <div style="padding:0 20px;">
    <div class="k-card" style="text-align:center;"><div style="font-family:var(--f-title);font-weight:800;font-size:13px;margin-bottom:10px;">গেট QR · Building QR</div><div style="width:120px;height:120px;margin:0 auto;background:#fff;border:1px solid var(--line);border-radius:14px;display:grid;place-items:center;">${kicon('qr',{s:84,c:'#2C3530',sw:1.4})}</div><div style="font-size:11px;color:var(--muted);margin-top:8px;">ভিজিটর স্ক্যান করে ফর্ম পূরণ করবে</div></div>
  </div>
  <div style="padding:14px 20px 0;">
    <div class="sectit">অপেক্ষমাণ ভিজিটর · Waiting ${q.length}</div>
    <div style="display:grid;gap:10px;">
      ${q.map(([n,p,f,t,c])=>`<div class="k-card rowcard" style="cursor:pointer;" onclick="go('careReview')">${avatar(n[0],c)}<div style="flex:1;"><div style="font-family:var(--f-title);font-weight:700;font-size:14px;">${n}</div><div style="font-size:11.5px;color:var(--muted);">${p} · ফ্ল্যাট ${f}</div></div><span class="k-chip ${t==='now'?'rose':''}">${t}</span></div>`).join('')}
    </div>
  </div>
  <div style="padding:14px 20px 22px;">
    <button class="k-btn soft full" onclick="go('careLog')">${kicon('search',{s:18,c:'#5C8067'})} ভিজিটর লগ · Visitor log</button>
  </div>
  </div>`;
}});
reg('careReview', { group:'Caretaker · কেয়ারটেকার', gcolor:'#3D4A42', en:'Visitor review', bn:'ভিজিটর যাচাই', ph:2, ico:'user', render(){
  return statusbar() + topbar({title:'ভিজিটর যাচাই · Review', back:'careHome'}) + `
  <div class="scroll"><div class="pad">
    <div class="k-card" style="text-align:center;"><div style="width:84px;height:84px;border-radius:42px;margin:0 auto;background:linear-gradient(160deg,#dfe7e1,#cdd8d0);display:grid;place-items:center;font-size:32px;">🧍</div><div style="font-family:var(--f-title);font-weight:800;font-size:17px;margin-top:10px;">Jamal Uddin</div><div style="font-size:12px;color:var(--muted);">01812-334455</div></div>
    <div class="k-card" style="margin-top:12px;">${[['যাচ্ছেন · Visiting','ফ্ল্যাট 4B'],['কার কাছে · Meet','নাসরিন আক্তার'],['উদ্দেশ্য · Purpose','কুরিয়ার ডেলিভারি'],['সময় · Arrived','৩:২২ PM']].map((r,i)=>`<div style="display:flex;justify-content:space-between;padding:9px 0;border-bottom:${i<3?'1px dotted var(--line)':'0'};font-size:13px;"><span style="color:var(--muted);">${r[0]}</span><b style="font-family:var(--f-title);">${r[1]}</b></div>`).join('')}</div>
    <button class="k-btn soft full" style="margin-top:12px;justify-content:flex-start;gap:12px;">${kicon('phone',{s:18,c:'#5C8067'})} ভাড়াটিয়াকে কল করুন · Call tenant</button>
    <div style="display:grid;grid-template-columns:1fr 1fr;gap:10px;margin-top:12px;">
      <button class="k-btn primary lg" onclick="go('careHome')">${kicon('check',{s:18,c:'#fff'})} প্রবেশ · Admit</button>
      <button class="k-btn danger lg" onclick="go('careHome')">${kicon('x',{s:18,c:'#fff'})} ফেরান · Refuse</button>
    </div>
  </div></div>`;
}});
reg('careLog', { group:'Caretaker · কেয়ারটেকার', gcolor:'#3D4A42', en:'Visitor log', bn:'ভিজিটর লগ', ph:2, ico:'search', render(){
  const log=[['Jamal Uddin','4B','3:22 PM','admit'],['Shahana Begum','2C','2:05 PM','admit'],['Unknown','—','1:40 PM','refuse'],['Faisal Khan','1A','12:10 PM','admit'],['Courier','3C','11:30 AM','admit']];
  return statusbar() + topbar({title:'ভিজিটর লগ · Log', back:'careHome', action:`<button class="iconbtn">${kicon('search',{s:18})}</button>`}) + `
  <div class="scroll"><div class="pad">
    <div class="k-card k-soft rowcard" style="background:var(--sage-bg);">${kicon('shield',{s:18,c:'#5C8067'})}<div style="font-size:11.5px;color:var(--sage-dk);font-weight:600;line-height:1.5;">৯০ দিন পর স্বয়ংক্রিয় মুছে যায় · Auto-purged after 90 days (admin-configurable)</div></div>
    <div class="k-card" style="padding:0;margin-top:12px;">${log.map((l,i)=>`<div class="fieldrow" style="border-bottom:${i<log.length-1?'1px solid var(--line)':'0'};">${avatar(l[0][0],l[3]==='admit'?'var(--sage)':'var(--rose)')}<div style="flex:1;"><div style="font-family:var(--f-title);font-weight:700;font-size:13.5px;">${l[0]}</div><div style="font-size:11px;color:var(--muted);">ফ্ল্যাট ${l[1]} · ${l[2]}</div></div><span class="k-chip ${l[3]==='admit'?'':'rose'}">${l[3]==='admit'?'প্রবেশ':'ফেরানো'}</span></div>`).join('')}</div>
  </div></div>`;
}});
