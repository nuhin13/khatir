/* ═══ Khatir prototype — Landlord screens (onboarding tenant, rent, expenses, dashboard, P1) ═══ */

// ── ADD TENANT (method chooser) ──
reg('addTenant', { group:'Landlord · বাড়িওয়ালা', gcolor:'#7BA084', en:'Add tenant', bn:'ভাড়াটিয়া যোগ', ph:0, ico:'user', render(){
  const m=[['ocr','📸','NID-এর ছবি তুলুন','Snap the NID — AI fills everything','cam',true],
           ['voice','🎤','ভয়েস দিয়ে বলুন','Just say it in Bangla','mic',false],
           ['manualTenant','✍️','হাতে লিখুন','Fill it in yourself','pencil',false]];
  return statusbar() + topbar({title:'ভাড়াটিয়া যোগ · Add tenant', back:'home'}) + `
  <div class="scroll"><div class="pad">
    ${emojiHero('👋','Let\'s add a tenant','কীভাবে শুরু করবেন?')}
    <div style="display:grid;gap:12px;margin-top:14px;">
      ${m.map(([k,e,bn,en,ic,star])=>`
        <div class="k-card ${star?'':''}" onclick="go('${k}')" style="cursor:pointer;display:flex;gap:14px;align-items:center;${star?'border:2px solid var(--sage);background:var(--sage-bg);':''}">
          <div style="width:60px;height:60px;border-radius:30px;background:${star?'linear-gradient(135deg,var(--sage),var(--sage-dk))':'var(--butter-bg)'};display:grid;place-items:center;font-size:26px;flex-shrink:0;${star?'box-shadow:var(--sh-sage);':''}">${e}</div>
          <div style="flex:1;"><div style="font-family:var(--f-title);font-weight:800;font-size:16px;">${bn}</div><div style="font-size:12px;color:var(--muted-dk);margin-top:2px;">${en}</div></div>
          ${star?`<span class="k-chip solid">⭐</span>`:kicon('arrow',{s:18,c:'#8C8578'})}
        </div>`).join('')}
    </div>
    <div class="k-card k-soft rowcard" style="background:var(--sage-bg);margin-top:14px;">
      <div style="font-size:20px;">💡</div>
      <div style="font-size:12px;color:var(--sage-dk);font-weight:600;line-height:1.5;"><b>টিপ · Tip:</b> NID ছবি পদ্ধতি সবচেয়ে দ্রুত — ২ মিনিটে শেষ</div>
    </div>
  </div></div>` + bottomnav('addTenant','landlord');
}});

// ── OCR ──
let ocrScanned=false;
reg('ocr', { group:'Landlord · বাড়িওয়ালা', gcolor:'#7BA084', en:'NID OCR scan', bn:'NID স্ক্যান', ph:0, ico:'cam', render(){
  let body;
  if(!ocrScanned){
    body=`<div class="pad">
      <div style="font-family:var(--f-hand);font-size:25px;color:var(--sage-dk);text-align:center;margin-bottom:12px;">Snap your NID</div>
      <div class="k-card" style="padding:0;overflow:hidden;background:#1a2820;border:0;">
        <div style="aspect-ratio:1.58;position:relative;display:grid;place-items:center;">
          <div style="position:absolute;inset:18px;border:3px dashed rgba(255,255,255,.4);border-radius:16px;"></div>
          <div style="position:absolute;left:18px;right:18px;height:2px;background:var(--butter);top:50%;box-shadow:0 0 18px var(--butter);"></div>
          <div style="color:rgba(255,255,255,.78);text-align:center;z-index:2;"><div style="font-size:42px;">📇</div><div style="margin-top:8px;font-size:13px;font-weight:600;">NID কার্ড ফ্রেমে রাখুন</div></div>
        </div>
      </div>
      <div class="k-card k-soft rowcard" style="background:var(--sage-bg);margin-top:14px;">${kicon('shield',{s:20,c:'#5C8067'})}<div style="font-size:12.5px;color:var(--sage-dk);font-weight:600;line-height:1.5;">ভালো আলোতে ধরুন। ছবি কোথাও পাঠানো হবে না · Photo never leaves your phone.</div></div>
      <button class="k-btn primary full lg" style="margin-top:18px;" onclick="ocrScanned=true;repaint()">${kicon('cam',{s:18,c:'#fff'})} ছবি তুলুন · Capture</button>
    </div>`;
  } else {
    const rows=[['নাম · Name','Karim Hossain','👤'],['NID নম্বর · NID','1992 5566 7788','🆔'],['জন্ম তারিখ · DOB','12 Mar 1992','🎂'],['ঠিকানা · Address','Mirpur 10, Dhaka','🏠']];
    body=`<div class="pad">
      <div class="k-card k-soft rowcard" style="background:var(--sage-bg);margin-bottom:14px;"><div style="font-size:22px;">✨</div><div style="font-size:13.5px;color:var(--sage-dk);font-weight:700;flex:1;">AI বুঝে নিয়েছে — যাচাই করুন · AI extracted, please confirm</div></div>
      ${IS_PRO
        ? `<div class="k-card rowcard" style="border:2px solid var(--sage);background:var(--sage-bg);margin-bottom:12px;">${kicon('shield',{s:22,c:'#5C8067'})}<div style="flex:1;"><div style="font-family:var(--f-title);font-weight:800;font-size:13.5px;">✓ এই NID আগে যাচাইকৃত <span class="k-chip solid" style="font-size:9px;">PRO</span></div><div style="font-size:11px;color:var(--muted-dk);margin-top:2px;">Already verified — পুনরায় যাচাই লাগবে না (৳০)</div></div></div>`
        : `<div class="k-card k-soft rowcard" style="background:var(--butter-bg);margin-bottom:12px;">${kicon('lock',{s:20,c:'#C9755F'})}<div style="flex:1;"><div style="font-family:var(--f-title);font-weight:700;font-size:12.5px;color:var(--rose-dk);">এই NID অন্য সময় যাচাই হয়েছে</div><div style="font-size:10.5px;color:var(--muted-dk);margin-top:1px;">Pro হলে ফ্রি পুনঃব্যবহার · reuse free with Pro</div></div><button class="k-btn rose sm" onclick="togglePro()">Pro</button></div>`}
      <div style="display:grid;gap:10px;">
        ${rows.map(([l,v,e])=>`<div class="k-card rowcard"><div style="font-size:22px;">${e}</div><div style="flex:1;"><div style="font-size:11px;color:var(--muted);font-weight:600;">${l}</div><div style="font-family:var(--f-title);font-weight:700;font-size:15px;margin-top:1px;">${v}</div></div><button class="k-btn soft sm">${kicon('pencil',{s:13,c:'#5C8067'})}</button></div>`).join('')}
      </div>
      <button class="k-btn primary full lg" style="margin-top:18px;" onclick="go('dmp')">পরবর্তী — ফর্ম তৈরি · Build form 🚀</button>
    </div>`;
  }
  return statusbar() + topbar({title:'NID স্ক্যান · OCR', back:'addTenant'}) + `<div class="scroll">${body}</div>`;
}});

// ── VOICE ──
let voiceDone=false;
reg('voice', { group:'Landlord · বাড়িওয়ালা', gcolor:'#7BA084', en:'Voice fill', bn:'ভয়েস ফর্ম', ph:0, ico:'mic', render(){
  let body;
  if(!voiceDone){
    body=`<div class="pad" style="text-align:center;">
      <div style="font-family:var(--f-hand);font-size:28px;color:var(--sage-dk);margin-top:6px;line-height:1;">Talk to me!</div>
      <div style="font-family:var(--f-title);font-weight:800;font-size:18px;margin-top:4px;">মাইক চাপুন · Tap the mic</div>
      <div onclick="voiceDone=true;repaint()" style="width:158px;height:158px;border-radius:50%;background:radial-gradient(circle at 30% 30%,var(--rose),var(--rose-dk));margin:26px auto;display:grid;place-items:center;cursor:pointer;box-shadow:0 0 0 14px var(--rose-bg),0 0 0 28px rgba(232,155,139,.18),0 20px 40px -10px var(--rose-dk);">
        ${kicon('mic',{s:62,c:'#fff',sw:1.6})}
      </div>
      <div style="color:var(--muted);font-size:13px;">চেপে ধরে বাংলায় বলুন · Hold &amp; speak Bangla</div>
      <div class="k-card k-soft" style="background:var(--butter-bg);margin-top:18px;text-align:left;">
        <div style="font-size:11px;color:var(--muted-dk);font-weight:700;margin-bottom:4px;">উদাহরণ · Example</div>
        <div style="font-family:var(--f-hand);font-size:17px;line-height:1.4;">"নতুন ভাড়াটিয়া, নাম রহিম উদ্দিন, ফ্ল্যাট ৪বি, ভাড়া ছাব্বিশ হাজার, মার্চ থেকে…"</div>
      </div>
    </div>`;
  } else {
    const rows=[['নাম · Name','রহিম উদ্দিন','👤'],['ইউনিট · Unit','৪বি','🚪'],['ভাড়া · Rent','৳২৬,০০০','💰'],['শুরু · From','Mar 2026','📅']];
    body=`<div class="pad">
      <div class="k-card" style="background:#2a3530;color:#fff;border:0;">
        <div style="font-size:10.5px;color:var(--butter);font-weight:700;letter-spacing:.12em;text-transform:uppercase;margin-bottom:8px;">🎙 আপনি বললেন · You said</div>
        <div style="font-family:var(--f-title);font-size:14.5px;font-weight:600;line-height:1.55;">"নতুন ভাড়াটিয়া, নাম রহিম উদ্দিন, ফ্ল্যাট ৪বি, ভাড়া ছাব্বিশ হাজার, মার্চ থেকে"</div>
      </div>
      <div style="text-align:center;margin:14px 0;"><span class="k-chip">✨ AI বুঝে নিয়েছে · Understood</span></div>
      <div style="display:grid;gap:8px;">
        ${rows.map(([l,v,e])=>`<div class="k-card rowcard" style="padding:10px 14px;"><div style="font-size:18px;">${e}</div><div style="flex:1;font-size:12px;color:var(--muted);font-weight:600;">${l}</div><b style="font-family:var(--f-title);font-size:14px;">${v}</b></div>`).join('')}
      </div>
      <button class="k-btn primary full lg" style="margin-top:18px;" onclick="go('dmp')">ফর্ম তৈরি · Build form 🎉</button>
    </div>`;
  }
  return statusbar() + topbar({title:'ভয়েস ফর্ম · Voice', back:'addTenant'}) + `<div class="scroll">${body}</div>`;
}});

// ── MANUAL TENANT (full DMP entry) ──
let IS_PRO = false;
function togglePro(){ IS_PRO=!IS_PRO; repaint(); }
function dmpSec(t){ return `<div style="font-family:var(--f-title);font-weight:800;font-size:12px;color:var(--sage-dk);letter-spacing:.04em;text-transform:uppercase;margin:16px 2px 8px;">${t}</div>`; }
reg('manualTenant', { group:'Landlord · বাড়িওয়ালা', gcolor:'#7BA084', en:'Manual DMP form', bn:'হাতে DMP ফর্ম', ph:0, ico:'pencil', render(){
  return statusbar() + topbar({title:'হাতে DMP ফর্ম · Manual form', back:'addTenant'}) + `
  <div class="scroll"><div class="pad">
    <div class="k-card k-soft rowcard" style="background:var(--butter-bg);"><div style="font-size:22px;">✍️</div><div style="font-size:12px;color:var(--muted-dk);font-weight:600;line-height:1.5;">সরকারি ভাড়াটিয়া তথ্য ফরমের সব ঘর হাতে পূরণ করুন · Fill every official field by hand.</div></div>
    ${dmpSec('১. বাড়িওয়ালা · Landlord')}
    ${field('নাম · Name','আব্দুল করিম')}
    <div style="display:flex;gap:10px;"><div style="flex:1;">${field('NID','1985 4433 2211')}</div><div style="flex:1;">${field('মোবাইল · Mobile','01711-000111')}</div></div>
    ${dmpSec('২. ভাড়াটিয়া · Tenant')}
    ${field('পূর্ণ নাম ★ · Full name','রহিম উদ্দিন')}
    <div style="display:flex;gap:10px;"><div style="flex:1;">${field('NID ★','','১৩/১৭ সংখ্যা')}</div><div style="flex:1;">${field('জন্ম তারিখ · DOB','০৫/০৮/১৯৯০')}</div></div>
    <div style="display:flex;gap:10px;"><div style="flex:1;">${field('পেশা · Occupation','বেসরকারি চাকরি')}</div><div style="flex:1;">${field('মোবাইল · Mobile','01712-445566')}</div></div>
    ${field('স্থায়ী ঠিকানা · Permanent address','গ্রাম: শ্রীপুর, জেলা: কুমিল্লা')}
    ${dmpSec('৩. বর্তমান বাসা · Current unit')}
    <div style="display:flex;gap:10px;"><div style="flex:1;">${field('বিল্ডিং · Building','করিম মঞ্জিল')}</div><div style="flex:1;">${field('ইউনিট · Unit','4B')}</div></div>
    <div style="display:flex;gap:10px;"><div style="flex:1;">${field('ভাড়া · Rent','২৬,০০০')}</div><div style="flex:1;">${field('ওঠার তারিখ · Move-in','০১/০৩/২০২৬')}</div></div>
    ${dmpSec('৪. পরিবার ও কর্মচারী · Family & staff')}
    <div style="display:flex;gap:10px;"><div style="flex:1;">${field('পরিবার সদস্য · Family','৩')}</div><div style="flex:1;">${field('গৃহকর্মী · House staff','১')}</div></div>
    <button class="k-btn primary full lg" style="margin-top:16px;" onclick="go('dmpPdf')">${kicon('doc',{s:18,c:'#fff'})} ফর্ম তৈরি ও PDF দেখুন · Generate PDF ${kicon('arrow',{s:16,c:'#fff'})}</button>
  </div></div>`;
}});

// ── DMP FORM (quick confirmation card) ──
reg('dmp', { group:'Landlord · বাড়িওয়ালা', gcolor:'#7BA084', en:'DMP form', bn:'DMP ফর্ম', ph:0, ico:'doc', render(){
  const rows=[['ভাড়াটিয়া · Tenant','Karim Hossain'],['NID','1992 5566 7788'],['বাড়িওয়ালা · Landlord','Abdul Karim'],['ঠিকানা · Address','Mirpur 10, Flat 2C'],['শুরু · From','জানু ২০২৫'],['পরিবার · Family','৩ জন'],['পেশা · Occupation','বেসরকারি চাকরি']];
  return statusbar() + topbar({title:'DMP ফর্ম · DMP form', back:'home', action:`<span class="k-chip">${kicon('check',{s:13,c:'#5C8067'})} প্রস্তুত</span>`}) + `
  <div class="scroll"><div class="pad">
    ${emojiHero('🎉','All done!','ফর্ম তৈরি হয়েছে')}
    <div class="k-card" style="padding:20px 18px;margin-top:8px;">
      <div style="text-align:center;padding-bottom:12px;margin-bottom:14px;border-bottom:1px dashed var(--line);">
        <div style="font-size:22px;">🏛️</div>
        <div style="font-family:var(--f-title);font-weight:800;font-size:14px;letter-spacing:.2px;margin-top:4px;">ঢাকা মেট্রোপলিটন পুলিশ</div>
        <div style="font-size:10px;color:var(--muted);margin-top:3px;letter-spacing:.1em;">DMP · CIMS · TENANT INFORMATION</div>
        <span class="k-chip rose" style="margin-top:8px;">ভাড়াটিয়া তথ্য ফরম</span>
      </div>
      ${rows.map((r,i)=>`<div style="display:flex;padding:8px 0;font-size:13px;border-bottom:${i<rows.length-1?'1px dotted var(--line)':'0'};"><div style="width:140px;color:var(--muted);font-weight:600;">${r[0]}</div><div style="font-weight:700;font-family:var(--f-title);flex:1;">${r[1]}</div></div>`).join('')}
      <div style="margin-top:10px;padding-top:10px;border-top:1px solid var(--line);font-size:9.5px;color:var(--muted);text-align:center;font-family:var(--f-mono);">Generated by Khatir · KHT/2026/0512</div>
    </div>
    <div style="display:grid;gap:10px;margin-top:16px;">
      <button class="k-btn primary full lg" onclick="go('dmpPdf')">${kicon('eye',{s:18,c:'#fff'})} PDF দেখুন · Preview &amp; download</button>
      <button class="k-btn soft full" onclick="go('verify')">${kicon('shield',{s:16,c:'#5C8067'})} NID যাচাই · Verify identity</button>
    </div>
  </div></div>`;
}});

// ── DMP PDF PREVIEW (realistic A4 document) ──
reg('dmpPdf', { group:'Landlord · বাড়িওয়ালা', gcolor:'#7BA084', en:'DMP PDF preview', bn:'DMP PDF', ph:0, ico:'download', render(){
  const cell=(l,v)=>`<div style="border:.5px solid #b9b3a4;padding:5px 7px;min-height:34px;"><div style="font-size:7.5px;color:#6b6558;font-family:'Hind Siliguri',sans-serif;">${l}</div><div style="font-size:10px;font-weight:600;color:#1a1a1a;font-family:'Hind Siliguri',sans-serif;margin-top:2px;">${v}</div></div>`;
  const paper = `
    <div style="background:#fff;color:#1a1a1a;width:100%;box-shadow:0 8px 30px -12px rgba(0,0,0,.35);font-family:'Hind Siliguri',sans-serif;">
      <div style="padding:18px 16px 14px;">
        <div style="display:flex;align-items:center;gap:10px;border-bottom:2px solid #1a2820;padding-bottom:10px;">
          <div style="width:40px;height:40px;border-radius:50%;border:1.5px solid #1a2820;display:grid;place-items:center;font-size:18px;">🏛️</div>
          <div style="flex:1;text-align:center;">
            <div style="font-size:11px;font-weight:700;">গণপ্রজাতন্ত্রী বাংলাদেশ সরকার</div>
            <div style="font-size:12.5px;font-weight:800;">ঢাকা মেট্রোপলিটন পুলিশ (ডিএমপি)</div>
            <div style="font-size:9.5px;">বাসা ভাড়া / ভাড়াটিয়া তথ্য সংক্রান্ত ফরম</div>
          </div>
          <div style="width:46px;height:54px;border:1px dashed #999;display:grid;place-items:center;font-size:7px;color:#888;text-align:center;line-height:1.2;">ছবি<br>Photo</div>
        </div>
        <div style="font-size:8px;color:#666;text-align:right;margin-top:4px;font-family:'JetBrains Mono',monospace;">Form No: KHT/2026/0512 · তারিখ: ১৫/০৫/২০২৬</div>

        <div style="font-size:9.5px;font-weight:800;background:#e8f0ea;padding:4px 7px;margin-top:10px;">ক · বাড়িওয়ালার তথ্য</div>
        <div style="display:grid;grid-template-columns:1fr 1fr;gap:0;border:.5px solid #b9b3a4;border-bottom:0;">
          ${cell('বাড়িওয়ালার নাম','আব্দুল করিম')}${cell('মোবাইল','01711-000111')}
        </div>
        <div style="display:grid;grid-template-columns:1fr 1fr;gap:0;border:.5px solid #b9b3a4;border-top:0;">
          ${cell('জাতীয় পরিচয়পত্র','1985 4433 2211')}${cell('বাড়ির ঠিকানা','House 12, Rd 4, Mirpur 10')}
        </div>

        <div style="font-size:9.5px;font-weight:800;background:#e8f0ea;padding:4px 7px;margin-top:10px;">খ · ভাড়াটিয়ার তথ্য</div>
        <div style="display:grid;grid-template-columns:1fr 1fr;border:.5px solid #b9b3a4;border-bottom:0;">${cell('ভাড়াটিয়ার নাম','রহিম উদ্দিন')}${cell('পিতা/স্বামীর নাম','মৃত: আব্দুল হক')}</div>
        <div style="display:grid;grid-template-columns:1fr 1fr 1fr;border:.5px solid #b9b3a4;border-bottom:0;">${cell('NID','1992 5566 7788')}${cell('জন্ম তারিখ','05/08/1990')}${cell('মোবাইল','01712-445566')}</div>
        <div style="display:grid;grid-template-columns:1fr 1fr;border:.5px solid #b9b3a4;border-bottom:0;">${cell('পেশা','বেসরকারি চাকরি')}${cell('ওঠার তারিখ','01/03/2026')}</div>
        <div style="display:grid;grid-template-columns:1fr;border:.5px solid #b9b3a4;border-bottom:0;">${cell('স্থায়ী ঠিকানা','গ্রাম: শ্রীপুর, ডাকঘর: চান্দিনা, জেলা: কুমিল্লা')}</div>
        <div style="display:grid;grid-template-columns:1fr 1fr;border:.5px solid #b9b3a4;">${cell('ফ্ল্যাট/ইউনিট','4B · করিম মঞ্জিল')}${cell('মাসিক ভাড়া','৳ ২৬,০০০')}</div>

        <div style="font-size:9.5px;font-weight:800;background:#e8f0ea;padding:4px 7px;margin-top:10px;">গ · পরিবারের সদস্য ও গৃহকর্মী</div>
        <div style="border:.5px solid #b9b3a4;">
          <div style="display:grid;grid-template-columns:24px 1fr 1fr 1fr;background:#f3f0e8;font-size:7.5px;font-weight:700;">
            <div style="padding:3px;border-right:.5px solid #b9b3a4;">#</div><div style="padding:3px;border-right:.5px solid #b9b3a4;">নাম</div><div style="padding:3px;border-right:.5px solid #b9b3a4;">সম্পর্ক</div><div style="padding:3px;">বয়স</div>
          </div>
          ${[['১','সালমা বেগম','স্ত্রী','৩২'],['২','তানিম','ছেলে','৮'],['৩','রিয়া','মেয়ে','৫']].map(r=>`<div style="display:grid;grid-template-columns:24px 1fr 1fr 1fr;font-size:8.5px;border-top:.5px solid #d8d3c5;"><div style="padding:3px;border-right:.5px solid #d8d3c5;">${r[0]}</div><div style="padding:3px;border-right:.5px solid #d8d3c5;">${r[1]}</div><div style="padding:3px;border-right:.5px solid #d8d3c5;">${r[2]}</div><div style="padding:3px;">${r[3]}</div></div>`).join('')}
        </div>

        <div style="font-size:8px;line-height:1.5;margin-top:10px;color:#333;">আমি/আমরা অঙ্গীকার করছি যে, উপরে প্রদত্ত তথ্য সঠিক। ভুল তথ্য প্রদান করলে প্রচলিত আইন অনুযায়ী ব্যবস্থা গ্রহণ করা যাবে।</div>
        <div style="display:flex;justify-content:space-between;margin-top:22px;">
          <div style="text-align:center;font-size:8px;"><div style="border-top:1px solid #1a1a1a;width:96px;padding-top:3px;">ভাড়াটিয়ার স্বাক্ষর</div></div>
          <div style="text-align:center;font-size:8px;"><div style="border-top:1px solid #1a1a1a;width:96px;padding-top:3px;">বাড়িওয়ালার স্বাক্ষর</div></div>
        </div>
        <div style="text-align:center;font-size:7px;color:#999;margin-top:14px;font-family:'JetBrains Mono',monospace;">Generated by Khatir · খাতির — বাড়িওয়ালার ডিজিটাল খাতা · page 1/1</div>
      </div>
    </div>`;
  return statusbar() + topbar({title:'DMP PDF', back:'dmp', action:`<span class="k-chip">A4</span>`}) + `
  <div class="scroll" style="background:#9a8f7c;"><div style="padding:16px;">
    ${paper}
  </div></div>
  <div style="flex-shrink:0;padding:12px 16px;background:var(--card);border-top:1px solid var(--line);display:flex;gap:10px;">
    <button class="k-btn primary lg" style="flex:1;" onclick="go('home')">${kicon('download',{s:18,c:'#fff'})} PDF নামান</button>
    <button class="k-btn soft lg" style="flex:1;">${kicon('wa',{s:18,c:'#5C8067'})} শেয়ার</button>
  </div>`;
}});

// ── RENT REQUEST ──
let rentSent=false;
reg('rentReq', { group:'Landlord · বাড়িওয়ালা', gcolor:'#7BA084', en:'Rent request', bn:'ভাড়ার অনুরোধ', ph:0, ico:'send', render(){
  let body;
  if(!rentSent){
    const t=[['Karim Hossain','2C','৳২২,০০০','late','var(--rose)'],['Rahim Uddin','4B','৳২৬,০০০','ok','var(--sage)'],['Salim Mia','1A','৳১৮,৫০০','ok','var(--sage-dk)']];
    body=`<div class="pad">
      ${emojiHero('📤','Ask for rent','কাকে পাঠাবেন?')}
      <div style="text-align:center;color:var(--muted-dk);font-size:12.5px;margin-top:6px;line-height:1.5;max-width:300px;margin-left:auto;margin-right:auto;">অ্যাপ না থাকলেও সমস্যা নেই — WhatsApp-এ লিংক পাবেন 💚<br><span style="font-style:italic;color:var(--muted);">No app needed — they get a WhatsApp link</span></div>
      <div style="display:grid;gap:10px;margin-top:14px;">
        ${t.map(([n,u,a,st,bg])=>`<div class="k-card rowcard">${avatar(n[0],bg)}<div style="flex:1;"><div style="font-family:var(--f-title);font-weight:700;font-size:14.5px;">${n}</div><div style="font-size:11.5px;color:var(--muted);margin-top:1px;">ইউনিট ${u} · ${a}</div></div>${st==='late'?`<span class="k-chip rose">বাকি · Due</span>`:`<div style="width:24px;height:24px;border-radius:99px;border:2px solid var(--sage);display:grid;place-items:center;">${kicon('check',{s:13,c:'#5C8067',sw:3})}</div>`}</div>`).join('')}
      </div>
      <div class="k-card k-soft rowcard" style="background:var(--sage-bg);margin-top:14px;">${iconBadge('clock','rgba(255,255,255,.6)','#5C8067',20,40)}<div style="flex:1;"><div style="font-family:var(--f-title);font-weight:700;font-size:13.5px;">স্বয়ংক্রিয় তফসিল · Auto schedule</div><div style="font-size:11.5px;color:var(--muted-dk);margin-top:1px;">প্রতি মাসের ৫ তারিখে · 5th of each month</div></div><div style="width:42px;height:24px;border-radius:12px;background:var(--sage);position:relative;"><div style="width:20px;height:20px;border-radius:99px;background:#fff;position:absolute;top:2px;right:2px;"></div></div></div>
      <button class="k-btn primary full lg" style="margin-top:16px;" onclick="rentSent=true;repaint()">${kicon('send',{s:18,c:'#fff'})} সকলকে পাঠান · Send to all</button>
    </div>`;
  } else {
    const steps=[['📥','পেমেন্ট প্রমাণ আপলোড','Tenant uploads proof','শীঘ্রই',true],['🔔','আপনি বিজ্ঞপ্তি পাবেন','You get notified','অপেক্ষায়',false],['✅','\'টাকা পেয়েছি\' চাপুন','Tap “Received”','অপেক্ষায়',false]];
    body=`<div class="pad">
      ${emojiHero('🎉','Sent!','WhatsApp-এ লিংক পেয়েছেন ৩ জন')}
      <div class="k-card" style="padding:4px 0;margin-top:8px;">
        ${steps.map((s,i)=>`<div class="fieldrow" style="border-bottom:${i<2?'1px solid var(--line)':'0'};"><div style="width:44px;height:44px;border-radius:22px;display:grid;place-items:center;font-size:20px;background:${s[4]?'var(--rose-bg)':'var(--sage-bg)'};">${s[0]}</div><div style="flex:1;"><div style="font-family:var(--f-title);font-size:14px;font-weight:700;">${s[1]}</div><div style="font-size:11px;color:${s[4]?'var(--rose-dk)':'var(--muted)'};margin-top:2px;font-weight:600;">${s[2]} · ${s[3]}</div></div><div style="font-family:var(--f-title);font-weight:800;color:${s[4]?'var(--rose-dk)':'var(--line-dk)'};font-size:18px;">0${i+1}</div></div>`).join('')}
      </div>
      <button class="k-btn primary full" style="margin-top:14px;" onclick="go('verifyPay')">${kicon('eye',{s:16,c:'#fff'})} প্রমাণ যাচাই করুন · See proof (demo)</button>
      <button class="k-btn soft full" style="margin-top:10px;" onclick="rentSent=false;go('home')">হোমে ফিরি · Home 🏠</button>
    </div>`;
  }
  return statusbar() + topbar({title:'ভাড়ার অনুরোধ · Rent', back:'home'}) + `<div class="scroll">${body}</div>` + bottomnav('rentReq','landlord');
}});

// ── VERIFY PAYMENT (proof) ──
reg('verifyPay', { group:'Landlord · বাড়িওয়ালা', gcolor:'#7BA084', en:'Verify payment', bn:'পেমেন্ট যাচাই', ph:0, ico:'cash', render(){
  return statusbar() + topbar({title:'পেমেন্ট যাচাই · Verify', back:'rentReq'}) + `
  <div class="scroll"><div class="pad">
    <div class="k-card k-soft rowcard" style="background:var(--butter-bg);">${avatar('K','var(--rose)')}<div style="flex:1;"><div style="font-family:var(--f-title);font-weight:700;font-size:14.5px;">Karim says he paid ৳২২,০০০</div><div style="font-size:11.5px;color:var(--muted-dk);">করিম বলছেন টাকা দিয়েছেন · 2C · মে ২০২৬</div></div></div>
    <div class="sectit" style="margin-top:16px;">জমা প্রমাণ · Submitted proof</div>
    <div class="k-card" style="padding:0;overflow:hidden;">
      <div style="height:300px;background:linear-gradient(160deg,#dfe7e1,#cdd8d0);display:grid;place-items:center;position:relative;">
        <div style="text-align:center;color:var(--muted-dk);"><div style="font-size:46px;">📱</div><div style="font-family:var(--f-mono);font-size:11px;margin-top:8px;">bKash payment screenshot</div></div>
        <div style="position:absolute;top:12px;left:12px;right:12px;background:rgba(255,255,255,.92);border-radius:12px;padding:10px 14px;font-family:var(--f-mono);font-size:12px;"><b>Txn ID:</b> 8GH4K2L9PQ<br><b>Amount:</b> ৳22,000 · <b>To:</b> 01711-000111</div>
      </div>
    </div>
    <div style="display:grid;gap:10px;margin-top:16px;">
      <button class="k-btn primary full lg" onclick="go('receipt')">${kicon('check',{s:18,c:'#fff'})} টাকা পেয়েছি · Received</button>
      <button class="k-btn ghost full" onclick="go('home')">এখনো পাইনি · Not yet received</button>
    </div>
  </div></div>`;
}});

// ── RECEIPT ──
reg('receipt', { group:'Landlord · বাড়িওয়ালা', gcolor:'#7BA084', en:'Receipt', bn:'রসিদ', ph:0, ico:'receipt', render(){
  return statusbar() + topbar({title:'রসিদ · Receipt', back:'home'}) + `
  <div class="scroll"><div class="pad">
    ${emojiHero('🧾','Receipt ready!','রসিদ তৈরি হয়েছে')}
    <div class="k-card" style="margin-top:8px;text-align:center;">
      <img src="assets/khatir-icon-128.png" width="40" style="border-radius:11px;">
      <div style="font-family:var(--f-title);font-weight:800;font-size:15px;margin-top:8px;">ভাড়ার রসিদ · Rent Receipt</div>
      <div style="font-family:var(--f-title);font-weight:800;font-size:34px;color:var(--sage-dk);margin-top:10px;letter-spacing:-1px;">৳২২,০০০</div>
      <div style="margin:14px 0;border-top:1px dashed var(--line);"></div>
      <div style="text-align:left;font-size:13px;display:grid;gap:7px;">
        ${[['ভাড়াটিয়া · Tenant','Karim Hossain'],['ইউনিট · Unit','2C · করিম মঞ্জিল'],['সময়কাল · Period','মে ২০২৬'],['পদ্ধতি · Method','bKash · 8GH4K2L9PQ'],['স্ট্যাটাস · Status','✓ পরিশোধিত · Paid']].map(r=>`<div style="display:flex;justify-content:space-between;"><span style="color:var(--muted);">${r[0]}</span><b style="font-family:var(--f-title);">${r[1]}</b></div>`).join('')}
      </div>
      <div style="margin-top:14px;font-family:var(--f-mono);font-size:9.5px;color:var(--muted);">KHT/2026/RC-0512 · verified by landlord</div>
    </div>
    <div style="display:grid;gap:10px;margin-top:16px;">
      <button class="k-btn primary full lg">${kicon('wa',{s:18,c:'#fff'})} ভাড়াটিয়াকে পাঠান · Send to tenant</button>
      <button class="k-btn soft full" onclick="go('home')">${kicon('download',{s:16,c:'#5C8067'})} PDF · Done</button>
    </div>
  </div></div>`;
}});

// ── EXPENSES & MAINTENANCE ──
reg('expenses', { group:'Landlord · বাড়িওয়ালা', gcolor:'#7BA084', en:'Maintenance & expenses', bn:'মেরামত ও খরচ', ph:0, ico:'wrench', render(){
  const reqs=[['Karim Hossain','2C','পানির পাইপ লিক হচ্ছে','Water pipe leaking','🚿','পানি'],['Rahim Uddin','4B','বাথরুমের লাইট নষ্ট','Bathroom light broken','💡','বিদ্যুৎ']];
  const exp=[['প্লাম্বিং মেরামত','১০ মে','৳৩,৫০০','🔧'],['দেয়াল রং','৮ মে','৳১২,০০০','🎨'],['বৈদ্যুতিক তার','৫ মে','৳৪,২০০','💡'],['AC সার্ভিস','২ মে','৳২,৮০০','❄️']];
  return statusbar() + topbar({title:'মেরামত ও খরচ · Maintenance', back:'home', action:`<button class="iconbtn" onclick="go('addExpense')">${kicon('plus',{s:20})}</button>`}) + `
  <div class="scroll"><div class="pad">
    <div class="k-card" style="background:linear-gradient(135deg,var(--butter),var(--butter-dk));color:var(--ink);border:0;">
      <span class="k-chip" style="background:rgba(255,255,255,.45);color:var(--ink);">এ মাসে · This month</span>
      <div style="font-family:var(--f-hand);font-size:20px;margin-top:8px;opacity:.8;">Total expenses</div>
      <div style="font-family:var(--f-title);font-weight:800;font-size:32px;letter-spacing:-1px;margin-top:2px;">৳৪২,০০০</div>
      <div style="margin-top:6px;font-size:12px;color:var(--muted-dk);font-weight:600;">৩ টি মেরামত · 2 অপেক্ষায় pending</div>
    </div>
    <div class="sectit" style="margin-top:16px;">নতুন অনুরোধ · New requests 🔔</div>
    <div style="display:grid;gap:10px;">
      ${reqs.map(([n,u,bn,en,e,cat])=>`<div class="k-card"><div style="display:flex;gap:12px;align-items:flex-start;"><div style="font-size:26px;">${e}</div><div style="flex:1;"><div style="display:flex;justify-content:space-between;align-items:center;"><div style="font-family:var(--f-title);font-weight:700;font-size:14px;">${n}</div><span class="k-chip rose">${cat}</span></div><div style="font-size:11.5px;color:var(--muted);margin-top:1px;">ইউনিট ${u}</div><div style="font-size:13px;margin-top:6px;line-height:1.4;">${bn}<br><span style="color:var(--muted);font-size:11.5px;font-style:italic;">${en}</span></div><div style="margin-top:10px;display:flex;gap:8px;"><button class="k-btn primary sm">সমাধান + খরচ</button><button class="k-btn soft sm">দেখুন</button></div></div></div></div>`).join('')}
    </div>
    <div class="sectit" style="margin-top:16px;">সাম্প্রতিক খরচ · Recent expenses</div>
    <div class="k-card" style="padding:0;">
      ${exp.map((x,i)=>`<div class="fieldrow" style="border-bottom:${i<exp.length-1?'1px solid var(--line)':'0'};"><div style="font-size:20px;">${x[3]}</div><div style="flex:1;"><div style="font-family:var(--f-title);font-weight:700;font-size:13.5px;">${x[0]}</div><div style="font-size:11px;color:var(--muted);margin-top:1px;">${x[1]}</div></div><div style="font-family:var(--f-title);font-weight:800;color:var(--rose-dk);font-size:14px;">${x[2]}</div></div>`).join('')}
    </div>
  </div></div>` + bottomnav('home','landlord');
}});

// ── ADD EXPENSE ──
reg('addExpense', { group:'Landlord · বাড়িওয়ালা', gcolor:'#7BA084', en:'Add expense', bn:'খরচ যোগ', ph:0, ico:'plus', render(){
  const cats=['🔧 প্লাম্বিং','🎨 পেইন্ট','💡 বিদ্যুৎ','🏗️ স্ট্রাকচার','❄️ অ্যাপ্লায়েন্স','✨ অন্যান্য'];
  return statusbar() + topbar({title:'খরচ যোগ · Add expense', back:'expenses'}) + `
  <div class="scroll"><div class="pad">
    ${field('পরিমাণ ★ · Amount','','৳ ০')}
    <div class="k-field" style="margin-bottom:10px;"><div class="lab">খাত · Category</div><div style="display:flex;flex-wrap:wrap;gap:7px;margin-top:4px;">${cats.map((c,i)=>`<button style="padding:8px 13px;border-radius:99px;border:0;cursor:pointer;background:${i===0?'var(--sage)':'var(--sage-bg)'};color:${i===0?'#fff':'var(--sage-dk)'};font-size:12px;font-weight:700;font-family:var(--f-title);">${c}</button>`).join('')}</div></div>
    ${field('ইউনিট · Unit','2C · করিম মঞ্জিল')}
    ${field('তারিখ · Date','১৫ মে ২০২৬')}
    ${field('নোট · Note (optional)','')}
    <button class="k-btn primary full lg" style="margin-top:8px;" onclick="go('expenses')">${kicon('check',{s:18,c:'#fff'})} খরচ সেভ করুন · Save expense</button>
  </div></div>`;
}});

// ── DASHBOARD (charts) ──
reg('dashboard', { group:'Landlord · বাড়িওয়ালা', gcolor:'#7BA084', en:'Dashboard / charts', bn:'ড্যাশবোর্ড', ph:0, ico:'chart', render(){
  const bars=[60,72,68,80,76,88];
  const months=['ডিসে','জানু','ফেব','মার্চ','এপ্রি','মে'];
  const exp=[['প্লাম্বিং','৳১৮,৫০০','🔧',60,'var(--rose-dk)','var(--rose-bg)'],['পেইন্ট','৳১২,০০০','🎨',40,'var(--rose-dk)','var(--butter-bg)'],['বিদ্যুৎ','৳৭,০০০','💡',24,'var(--sage-dk)','var(--sage-bg)'],['অন্যান্য','৳৪,৫০০','✨',15,'var(--muted-dk)','#F0E8DA']];
  return statusbar() + topbar({title:'ড্যাশবোর্ড · Dashboard', back:'home'}) + `
  <div class="scroll"><div class="pad">
    <div class="k-card" style="background:linear-gradient(135deg,var(--ink),#3D4A42);color:#fff;border:0;">
      <div style="font-size:12px;opacity:.8;">এ মাসের মোট আয় · Income this month</div>
      <div style="font-family:var(--f-title);font-weight:800;font-size:34px;letter-spacing:-1px;margin-top:2px;">৳৭১,০০০ <span style="font-size:13px;color:var(--butter);">↑ ১২%</span></div>
    </div>
    <div class="sectit" style="margin-top:16px;">আদায় হার · Collection rate (6 mo)</div>
    <div class="k-card">
      <div style="display:flex;align-items:flex-end;gap:8px;height:120px;">
        ${bars.map((b,i)=>`<div style="flex:1;display:flex;flex-direction:column;align-items:center;gap:6px;justify-content:flex-end;height:100%;"><div style="font-size:9px;color:var(--muted);font-weight:700;">${b}%</div><div style="width:100%;height:${b}%;background:linear-gradient(180deg,var(--sage),var(--sage-dk));border-radius:7px 7px 0 0;"></div></div>`).join('')}
      </div>
      <div style="display:flex;gap:8px;margin-top:8px;">${months.map(m=>`<div style="flex:1;text-align:center;font-size:10px;color:var(--muted);font-weight:600;">${m}</div>`).join('')}</div>
    </div>
    <div class="sectit" style="margin-top:16px;">অকুপেন্সি · Occupancy</div>
    <div class="k-card rowcard">
      <div style="position:relative;width:100px;height:100px;flex-shrink:0;">
        <svg viewBox="0 0 36 36" style="transform:rotate(-90deg);"><circle cx="18" cy="18" r="15.9" fill="none" stroke="var(--sage-bg)" stroke-width="4"/><circle cx="18" cy="18" r="15.9" fill="none" stroke="var(--sage)" stroke-width="4" stroke-dasharray="78 22" stroke-linecap="round"/></svg>
        <div style="position:absolute;inset:0;display:grid;place-items:center;text-align:center;"><div><div style="font-family:var(--f-title);font-weight:800;font-size:22px;line-height:1;">৭৮%</div><div style="font-size:9.5px;color:var(--muted);font-weight:700;">১১/১৪</div></div></div>
      </div>
      <div style="flex:1;">
        ${[['ভাড়া হয়েছে · Occupied','১১','var(--sage)'],['খালি · Vacant','২','var(--rose)'],['প্রক্রিয়াধীন · Pending','১','var(--butter)']].map(r=>`<div style="display:flex;align-items:center;gap:8px;font-size:12.5px;padding:3px 0;"><span style="width:10px;height:10px;border-radius:99px;background:${r[2]};"></span><span style="flex:1;font-weight:600;">${r[0]}</span><b style="font-family:var(--f-title);">${r[1]}</b></div>`).join('')}
      </div>
    </div>
    <div class="sectit" style="margin-top:16px;">প্রধান খরচ · Top expenses 💸</div>
    <div style="display:grid;gap:8px;">
      ${exp.map(([l,v,e,p,fg,bg])=>`<div class="k-card k-soft rowcard" style="background:${bg};padding:12px 14px;"><div style="font-size:20px;">${e}</div><div style="flex:1;"><div style="font-family:var(--f-title);font-weight:700;font-size:13px;">${l}</div><div style="height:5px;background:rgba(255,255,255,.65);border-radius:99px;margin-top:5px;overflow:hidden;"><div style="width:${p}%;height:100%;background:${fg};border-radius:99px;"></div></div></div><div style="font-family:var(--f-title);font-weight:800;color:${fg};font-size:14px;">${v}</div></div>`).join('')}
    </div>
  </div></div>` + bottomnav('dashboard','landlord');
}});

// ── MORE MENU ──
reg('more', { group:'Landlord · বাড়িওয়ালা', gcolor:'#7BA084', en:'More menu', bn:'আরও', ph:0, ico:'more', render(){
  const items=[['user','প্রোফাইল','Profile','home'],['card','প্ল্যান ও বিলিং','Plan & billing','plan'],['doc','AI লিজ তৈরি','AI lease','lease'],['flag','সতর্কতা ও অভিযোগ','Warnings','warning'],['globe','ভাষা · বাংলা/EN','Language','more'],['users','ভূমিকা পরিবর্তন','Switch role','roleChooser'],['sparkle','Khatir সম্পর্কে','About Khatir','intro']];
  return statusbar() + topbar({title:'আরও · More', back:'home'}) + `
  <div class="scroll"><div class="pad">
    <div class="k-card rowcard" style="background:var(--sage-bg);border:0;">${avatar('ক','var(--sage-dk)')}<div style="flex:1;"><div style="font-family:var(--f-title);font-weight:800;font-size:16px;">করিম সাহেব</div><div style="font-size:11.5px;color:var(--muted-dk);">+88 01711-000111 · বাড়িওয়ালা</div></div><span class="k-chip">Free 1/2</span></div>
    <div class="k-card" style="padding:4px 0;margin-top:12px;">
      ${items.map((it,i)=>`<button class="fieldrow" style="width:100%;background:none;border:0;border-bottom:${i<items.length-1?'1px solid var(--line)':'0'};cursor:pointer;text-align:left;" onclick="go('${it[3]}')">${iconBadge(it[0],'var(--sage-bg)','#5C8067',18,38)}<div style="flex:1;"><div style="font-family:var(--f-title);font-weight:700;font-size:14px;">${it[1]}</div><div style="font-size:11px;color:var(--muted);">${it[2]}</div></div>${kicon('chevron',{s:16,c:'#8C8578'})}</button>`).join('')}
    </div>
    <button class="k-btn soft full" style="margin-top:14px;color:var(--rose-dk);background:var(--rose-bg);" onclick="go('splash')">${kicon('logout',{s:16,c:'#C9755F'})} লগআউট · Log out</button>
  </div></div>` + bottomnav('more','landlord');
}});

// ── P1: NID VERIFY ──
let vfState='idle';
reg('verify', { group:'Landlord · বাড়িওয়ালা', gcolor:'#7BA084', en:'NID verify', bn:'NID যাচাই', ph:1, ico:'shield', render(){
  let body;
  if(vfState==='idle'){
    if(IS_PRO){
      body=`<div class="pad" style="text-align:center;">
        <div style="font-size:74px;margin-top:10px;">✅</div>
        <div style="font-family:var(--f-hand);font-size:26px;color:var(--sage-dk);margin-top:2px;">Already verified</div>
        <div style="font-family:var(--f-title);font-weight:800;font-size:19px;margin-top:2px;">Karim Hossain</div>
        <div style="color:var(--muted);font-size:12.5px;margin-top:2px;">NID 1992 5566 7788</div>
        <div class="k-card" style="text-align:left;margin:18px 0;border:2px solid var(--sage);">
          <div style="display:flex;align-items:center;gap:10px;"><span class="k-chip solid">PRO</span><div style="font-family:var(--f-title);font-weight:800;font-size:14px;">পুনরায় যাচাই লাগবে না</div></div>
          <div style="font-size:12.5px;color:var(--muted-dk);line-height:1.6;margin-top:8px;">এই NID আগে Khatir-এ যাচাই হয়েছে (১২ জানু ২০২৫)। Pro গ্রাহক হিসেবে আপনি বিনামূল্যে পুনঃব্যবহার করতে পারেন।<br><span style="font-style:italic;color:var(--muted);">This NID was verified earlier — reuse it free as a Pro member.</span></div>
          <div style="margin-top:10px;padding:10px 12px;background:var(--sage-bg);border-radius:12px;display:flex;justify-content:space-between;align-items:center;"><span style="font-size:12px;color:var(--muted-dk);font-weight:600;">ফি · Fee</span><b style="font-family:var(--f-title);color:var(--sage-dk);font-size:16px;">৳০</b></div>
        </div>
        <button class="k-btn primary full lg" onclick="vfState='ok';repaint()">${kicon('check',{s:18,c:'#fff'})} যাচাই পুনঃব্যবহার করুন · Reuse verification</button>
        <button class="k-btn soft full" style="margin-top:10px;font-size:12px;" onclick="togglePro()">⟲ demo: Pro বন্ধ করে দেখুন</button>
      </div>`;
    } else {
      body=`<div class="pad" style="text-align:center;">
      <div style="font-size:74px;margin-top:10px;">🛡️</div>
      <div style="font-family:var(--f-hand);font-size:26px;color:var(--sage-dk);margin-top:2px;">Let's verify</div>
      <div style="font-family:var(--f-title);font-weight:800;font-size:19px;margin-top:2px;">Karim Hossain</div>
      <div style="color:var(--muted);font-size:12.5px;margin-top:2px;">NID 1992 5566 7788</div>
      <div class="k-card" style="text-align:left;margin:18px 0;">
        <div style="font-size:13px;line-height:1.6;">নির্বাচন কমিশনের <b style="color:var(--sage-dk);">Matched / Not Matched</b> সার্ভিস দিয়ে পরিচয় যাচাই হবে · EC verification with consent.</div>
        <div style="margin-top:12px;padding:10px 12px;background:var(--butter-bg);border-radius:12px;display:flex;align-items:center;gap:8px;"><div style="font-size:16px;">✓</div><span style="font-size:12px;color:var(--muted-dk);flex:1;">ভাড়াটিয়ার সম্মতি নেওয়া হয়েছে · Consent captured</span></div>
        <div style="margin-top:10px;padding:10px 12px;background:var(--sage-bg);border-radius:12px;display:flex;justify-content:space-between;align-items:center;"><span style="font-size:12px;color:var(--muted-dk);font-weight:600;">ফি · Fee</span><b style="font-family:var(--f-title);color:var(--sage-dk);font-size:16px;">৳৭৫</b></div>
      </div>
      <button class="k-btn primary full lg" onclick="vfState='loading';repaint();setTimeout(()=>{vfState='ok';repaint();},1100)">${kicon('shield',{s:18,c:'#fff'})} যাচাই করুন · Verify</button>
      <div class="k-card k-soft" style="background:var(--butter-bg);margin-top:14px;text-align:left;display:flex;gap:10px;align-items:center;">${kicon('lock',{s:18,c:'#C9755F'})}<div style="flex:1;"><div style="font-size:11.5px;color:var(--rose-dk);font-weight:700;">Pro: যাচাইকৃত NID ফ্রি পুনঃব্যবহার</div><div style="font-size:10.5px;color:var(--muted-dk);margin-top:1px;">Reuse an already-verified NID at ৳0 — Pro only</div></div><button class="k-btn rose sm" onclick="togglePro()">দেখুন</button></div>
    </div>`;
    }
  } else if(vfState==='loading'){
    body=`<div class="pad" style="text-align:center;padding-top:120px;"><div style="font-size:60px;">🛡️</div><div style="font-family:var(--f-hand);font-size:26px;color:var(--muted);margin-top:14px;">verifying…</div><div style="font-size:12px;color:var(--muted);margin-top:6px;">EC service · Matched/Not Matched</div></div>`;
  } else {
    body=`<div class="pad" style="text-align:center;">
      <div style="font-size:74px;margin-top:10px;">🎉</div>
      <div style="font-family:var(--f-hand);font-size:34px;color:var(--sage-dk);line-height:1;">Matched!</div>
      <div style="font-family:var(--f-title);font-weight:800;font-size:18px;margin-top:2px;">পরিচয় নিশ্চিত · Identity confirmed</div>
      <div class="k-card" style="text-align:left;margin-top:18px;">
        ${[['নাম · Name'],['জন্ম তারিখ · DOB'],['ফেস ম্যাচ · Face match']].map((r,i)=>`<div style="display:flex;justify-content:space-between;align-items:center;padding:10px 0;border-bottom:${i<2?'1px solid var(--line)':'0'};"><span style="color:var(--muted-dk);font-weight:600;">${r[0]}</span><span class="k-chip">${kicon('check',{s:12,c:'#5C8067'})} মিল</span></div>`).join('')}
      </div>
      <div style="font-family:var(--f-mono);font-size:9.5px;color:var(--muted);margin-top:10px;">Result stored · raw payload discarded</div>
      <button class="k-btn primary full lg" style="margin-top:18px;" onclick="vfState='idle';go('home')">সম্পন্ন · Done 🎉</button>
    </div>`;
  }
  return statusbar() + topbar({title:'NID যাচাই · Verify', back:'home'}) + `<div class="scroll">${body}</div>`;
}});

// ── P1: AI LEASE ──
reg('lease', { group:'Landlord · বাড়িওয়ালা', gcolor:'#7BA084', en:'AI lease', bn:'লিজ তৈরি', ph:1, ico:'doc', render(){
  return statusbar() + topbar({title:'AI লিজ · Lease', back:'more'}) + `
  <div class="scroll"><div class="pad">
    ${emojiHero('📜','Smart lease','DNCC-সম্মত চুক্তি')}
    <div class="k-card k-soft rowcard" style="background:var(--sage-bg);margin-top:8px;">${kicon('sparkle',{s:20,c:'#5C8067'})}<div style="font-size:12.5px;color:var(--sage-dk);font-weight:600;line-height:1.5;">AI বাংলা ও English-এ চুক্তি তৈরি করবে · Generated in both languages</div></div>
    <div class="k-card" style="margin-top:12px;">
      <div class="lab" style="font-size:11px;font-weight:700;color:var(--muted);text-transform:uppercase;">শর্তাবলি · Clauses</div>
      <div style="margin-top:8px;display:grid;gap:8px;">
        ${[['মাসিক ভাড়া · Rent','৳২৬,০০০',true],['অগ্রিম · Advance','৳৫২,০০০ (২ মাস)',true],['ভাড়া বৃদ্ধি · Hike','২ বছরে একবার',true],['নোটিশ · Notice','২ মাস',true]].map(r=>`<div style="display:flex;justify-content:space-between;align-items:center;padding:10px 12px;background:var(--cream);border-radius:12px;"><span style="font-size:13px;font-weight:600;">${r[0]}</span><b style="font-family:var(--f-title);">${r[1]}</b></div>`).join('')}
      </div>
      <div style="margin-top:10px;padding:10px 12px;background:var(--sage-bg);border-radius:12px;display:flex;gap:8px;align-items:center;">${kicon('check',{s:16,c:'#5C8067'})}<span style="font-size:12px;color:var(--sage-dk);font-weight:600;">DNCC 2025 নিয়ম মেনে চলছে · DNCC-compliant ✓</span></div>
    </div>
    <div style="display:grid;gap:10px;margin-top:16px;">
      <button class="k-btn primary full lg">${kicon('pencil',{s:18,c:'#fff'})} e-সাইন করুন · E-sign</button>
      <button class="k-btn soft full">${kicon('download',{s:16,c:'#5C8067'})} খসড়া দেখুন · Preview</button>
    </div>
  </div></div>`;
}});

// ── P1: WARNING ──
reg('warning', { group:'Landlord · বাড়িওয়ালা', gcolor:'#7BA084', en:'Warning / complaint', bn:'সতর্কতা', ph:1, ico:'flag', render(){
  const cats=['দেরিতে ভাড়া','শব্দ','ক্ষতি','অন্যান্য'];
  return statusbar() + topbar({title:'সতর্কতা · Warning', back:'more'}) + `
  <div class="scroll"><div class="pad">
    <div class="k-card k-soft rowcard" style="background:var(--rose-bg);">${kicon('lock',{s:20,c:'#C9755F'})}<div style="font-size:12px;color:var(--rose-dk);font-weight:600;line-height:1.5;"><b>একান্ত ব্যক্তিগত · Private.</b> শুধু আপনি ও এই ভাড়াটিয়া দেখবেন। কখনো পাবলিক নয়।<br><span style="font-style:italic;opacity:.85;">Only you &amp; this tenant — never public.</span></div></div>
    <div class="k-field" style="margin-top:12px;"><div class="lab">ধরন · Category</div><div style="display:flex;flex-wrap:wrap;gap:7px;margin-top:4px;">${cats.map((c,i)=>`<button style="padding:8px 13px;border-radius:99px;border:0;cursor:pointer;background:${i===0?'var(--rose)':'var(--rose-bg)'};color:${i===0?'#fff':'var(--rose-dk)'};font-size:12px;font-weight:700;font-family:var(--f-title);">${c}</button>`).join('')}</div></div>
    <div class="k-field" style="margin-top:10px;"><div class="lab">বিবরণ (তথ্যভিত্তিক) · Factual note</div><textarea class="k-input" style="font-family:var(--f-body);font-weight:400;font-size:14px;resize:none;" rows="3" placeholder="শুধু তথ্য লিখুন, মতামত নয়">মে মাসের ভাড়া ১২ দিন দেরিতে দেওয়া হয়েছে।</textarea></div>
    <div class="k-card k-soft rowcard" style="background:var(--butter-bg);margin-top:10px;">${kicon('alert',{s:18,c:'#C9755F'})}<div style="font-size:11.5px;color:var(--muted-dk);line-height:1.5;">ভাড়াটিয়া উত্তর দেওয়ার অধিকার পাবেন · Tenant gets right of reply. Audit-logged.</div></div>
    <button class="k-btn rose full lg" style="margin-top:14px;" onclick="go('unit')">${kicon('flag',{s:18,c:'#fff'})} সতর্কতা পাঠান · Issue warning</button>
  </div></div>`;
}});

// ── P1: PLAN & BILLING ──
reg('plan', { group:'Landlord · বাড়িওয়ালা', gcolor:'#7BA084', en:'Plan & billing', bn:'প্ল্যান', ph:1, ico:'card', render(){
  const tiers=[['Free','১–২ ভাড়াটিয়া','৳০','যাচাই ছাড়া সব ফিচার',false,true],['Per-tenant','৩–১০ ভাড়াটিয়া','৳৫০','/ভাড়াটিয়া/মাস · + verify',false,false],['Bundle 20','১১–২০ ভাড়াটিয়া','৳৫৯৯','/মাস · bulk verify',false,false],['Unlimited','সীমাহীন','৳৯৯৯','/মাস (বার্ষিক) · সব ফিচার',true,false]];
  return statusbar() + topbar({title:'প্ল্যান · Plan', back:'more'}) + `
  <div class="scroll"><div class="pad">
    <div class="k-card k-soft rowcard" style="background:var(--butter-bg);"><div style="font-size:28px;">🎁</div><div style="flex:1;"><div style="font-family:var(--f-title);font-weight:700;font-size:14px;">এখন ফ্রি · You're on Free</div><div style="font-size:11.5px;color:var(--muted-dk);">১/২ ভাড়াটিয়া ব্যবহৃত · 1 of 2 tenants</div></div></div>
    <div style="display:grid;gap:10px;margin-top:14px;">
      ${tiers.map(([n,t,p,d,best,cur])=>`<div class="k-card" style="${best?'border:2px solid var(--sage);':cur?'background:var(--sage-bg);':''}position:relative;">${best?`<div style="position:absolute;top:-9px;right:14px;background:var(--sage-dk);color:#fff;font-size:9.5px;font-weight:800;padding:3px 9px;border-radius:99px;font-family:var(--f-title);">⭐ BEST VALUE</div>`:''}<div style="display:flex;justify-content:space-between;align-items:flex-start;"><div><div style="font-family:var(--f-title);font-weight:800;font-size:16px;">${n} ${cur?'<span class="k-chip" style="font-size:9px;">এখন</span>':''}</div><div style="font-size:11px;color:var(--muted);margin-top:2px;">${t}</div></div><div style="text-align:right;"><div style="font-family:var(--f-title);font-weight:800;font-size:20px;color:var(--sage-dk);">${p}</div></div></div><div style="font-size:11.5px;color:var(--muted-dk);margin-top:8px;">${d}</div></div>`).join('')}
    </div>
    <button class="k-btn primary full lg" style="margin-top:14px;">${kicon('card',{s:18,c:'#fff'})} bKash / Nagad দিয়ে আপগ্রেড</button>
    <div style="text-align:center;font-size:10.5px;color:var(--muted);margin-top:10px;font-family:var(--f-mono);">Prices admin-configurable · illustrative</div>
  </div></div>`;
}});
