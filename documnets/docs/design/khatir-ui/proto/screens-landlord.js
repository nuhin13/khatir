/* ═══ Khatir prototype — Landlord screens (Phase 0 core) ═══ */

// ── HOME ──
reg('home', { group:'Landlord · বাড়িওয়ালা', gcolor:'#7BA084', en:'Home dashboard', bn:'হোম', ph:0, ico:'home', render(){
  return statusbar() + topbar({brand:true, action: bellbtn()}) + `
  <div class="scroll"><div style="padding:2px 20px 14px;">
    <div style="font-family:var(--f-hand);font-size:25px;color:var(--sage-dk);line-height:1;">আসসালামু আলাইকুম,</div>
    <div style="display:flex;align-items:center;gap:8px;margin-top:3px;">
      <div style="font-family:var(--f-title);font-weight:800;font-size:23px;letter-spacing:-.5px;">করিম সাহেব</div><span style="font-size:18px;">👋</span>
    </div>
    <div style="color:var(--muted);font-size:12px;margin-top:3px;">আজ ১৫ মে · বৃহস্পতিবার · ২ বিল্ডিং · ১৪ ইউনিট</div>
  </div>

  <div style="padding:2px 20px 0;">
    <div class="hero-card" onclick="go('addTenant')" style="cursor:pointer;background:linear-gradient(135deg,var(--sage),var(--sage-dk));box-shadow:0 20px 40px -16px var(--sage-dk);border-radius:26px;">
      <span class="k-chip" style="background:rgba(255,255,255,.22);color:#fff;">⭐ সুপারিশ · FLAGSHIP</span>
      <div style="font-family:var(--f-title);font-weight:800;font-size:24px;line-height:1.15;letter-spacing:-.5px;margin-top:12px;">পুলিশ ফর্ম,<br>মাত্র ২ মিনিটে!</div>
      <div style="font-size:13px;opacity:.92;margin-top:7px;">Police form in 2 minutes — NID-এর ছবি তুলুন, বাকিটা আমরা করব ✨</div>
      <div style="margin-top:15px;display:inline-flex;align-items:center;gap:8px;background:rgba(255,255,255,.22);padding:9px 16px;border-radius:99px;font-size:13.5px;font-weight:700;font-family:var(--f-title);">শুরু করি · Start ${kicon('arrow',{s:16,c:'#fff'})}</div>
      <div style="position:absolute;right:-6px;top:-10px;opacity:.14;">${kicon('doc',{s:128,c:'#fff',sw:1.2})}</div>
    </div>
  </div>

  <div style="padding:14px 20px 0;">
    <div style="display:grid;grid-template-columns:1fr 1fr 1fr;gap:10px;">
      <div class="k-card statbox">${iconBadge('building','var(--sage-bg)','#5C8067',18,38)}<div class="n">২</div><div class="l">বিল্ডিং · Bldg</div></div>
      <div class="k-card statbox">${iconBadge('door','var(--sage-bg)','#5C8067',18,38)}<div class="n">১৪</div><div class="l">ইউনিট · Units</div></div>
      <div class="k-card statbox k-soft" style="background:var(--butter-bg);">${iconBadge('cash','rgba(255,255,255,.6)','#C9755F',18,38)}<div class="n" style="font-size:17px;color:var(--rose-dk);">৳৯৭K</div><div class="l" style="color:var(--muted-dk);">মাসিক · /mo</div></div>
    </div>
  </div>

  <div style="padding:12px 20px 0;">
    <div class="k-card">
      <div style="display:flex;justify-content:space-between;align-items:flex-start;">
        <div><div style="font-size:12px;color:var(--muted);font-weight:600;">এ মাসে আদায় · Collected this month</div>
        <div style="font-family:var(--f-title);font-weight:800;font-size:24px;letter-spacing:-.5px;margin-top:2px;">৳৭১,০০০ <span style="font-size:13px;color:var(--muted);font-weight:600;">/৯৩K</span></div></div>
        <span class="k-chip">৭৬% 🎯</span>
      </div>
      <div class="k-track" style="margin-top:8px;"><i style="width:76%"></i></div>
      <div style="margin-top:10px;padding:10px 12px;background:var(--rose-bg);border-radius:14px;display:flex;align-items:center;gap:10px;">
        ${iconBadge('clock','rgba(255,255,255,.7)','#C9755F',18,38)}
        <div style="flex:1;"><div style="font-size:12.5px;color:var(--rose-dk);font-weight:700;">১ টি ভাড়া বাকি · 1 rent overdue</div><div style="font-size:11px;color:var(--muted-dk);margin-top:1px;">৳২২,০০০ · Karim H. · 2C</div></div>
        <button class="k-btn rose sm" onclick="go('rentReq')">চান · Ask</button>
      </div>
    </div>
  </div>

  <div style="padding:14px 20px 0;">
    <div class="sectit">দ্রুত কাজ · Quick actions</div>
    <div style="display:grid;grid-template-columns:1fr 1fr;gap:10px;">
      ${[['addBuilding','building','বিল্ডিং যোগ','Add building','var(--sage-bg)','#5C8067'],
         ['rentReq','send','ভাড়া চান','Rent request','var(--rose-bg)','#C9755F'],
         ['addTenant','user','ভাড়াটিয়া যোগ','Add tenant','var(--butter-bg)','#C9755F'],
         ['dashboard','chart','ড্যাশবোর্ড','Dashboard','var(--sage-bg)','#5C8067']].map(([k,ic,bn,en,bg,fg])=>`
        <div class="k-card k-soft qa" style="background:${bg};" onclick="go('${k}')">
          ${iconBadge(ic,'rgba(255,255,255,.65)',fg,20,40)}
          <div class="qt" style="color:${fg};margin-top:8px;">${bn}</div>
          <div class="qe">${en}</div>
        </div>`).join('')}
    </div>
  </div>

  <div style="padding:12px 20px 0;">
    <div class="k-card rowcard" onclick="go('expenses')" style="cursor:pointer;">
      ${iconBadge('wrench','var(--butter-bg)','#C9755F',20,44)}
      <div style="flex:1;"><div style="font-family:var(--f-title);font-weight:700;font-size:14px;">মেরামত ও খরচ · Maintenance</div><div style="font-size:11.5px;color:var(--muted);margin-top:1px;">২ টি নতুন অনুরোধ অপেক্ষায় · 2 pending</div></div>
      <span class="k-chip rose">২ new</span>
    </div>
  </div>

  <div style="padding:12px 20px 22px;">
    <div class="k-card k-soft rowcard" style="background:var(--butter-bg);">
      <div style="font-size:30px;">🎁</div>
      <div style="flex:1;"><div style="font-family:var(--f-hand);font-size:22px;color:var(--rose-dk);line-height:.9;">Yay!</div><div style="font-family:var(--f-title);font-size:13px;font-weight:700;margin-top:2px;">২ ভাড়াটিয়া পর্যন্ত ফ্রি · First 2 free</div><div style="font-size:11px;color:var(--muted);margin-top:1px;">আপনি ১/২ ব্যবহার করেছেন</div></div>
      <button class="k-btn rose sm" onclick="go('plan')">প্ল্যান</button>
    </div>
  </div>
  </div>` + bottomnav('home','landlord');
}});

// ── ADD BUILDING (4-step wizard: name+area → address+map → units → review) ──
let bStep = 1, bArea = 'Mirpur', bPin = false, bMapOpen = false;
let bAddr = '';
const GEOCODED = 'House 12, Road 4, Block C, Mirpur 10, Dhaka 1216';
const AREAS = ['Uttara','Mirpur','Mohammadpur','Dhanmondi','Banasree','Gulshan','Banani','Bashundhara','Old Dhaka','অন্য'];
// units builder state
let uFloors = 3, uPer = 2, uScheme = 'letter';
let uRemoved = {}, uCustom = [];
const U_POOL = ['2001','2002','3001','11A','8B','GA'];
function unitLabels(){
  const out = [];
  for (let f=1; f<=uFloors; f++) for (let p=0; p<uPer; p++){
    out.push(uScheme==='number' ? String(f*100+(p+1)) : (f+String.fromCharCode(65+p)));
  }
  uCustom.forEach(c=>out.push(c));
  return out.filter(l=>!uRemoved[l]);
}
function uAddCustom(){ uCustom.push(U_POOL[uCustom.length % U_POOL.length]); repaint(); }
function pickOnMap(){ bPin=true; bAddr=GEOCODED; bMapOpen=true; repaint(); }
function resetWizard(){ bStep=1; bPin=false; bMapOpen=false; bAddr=''; uRemoved={}; uCustom=[]; }
reg('addBuilding', { group:'Landlord · বাড়িওয়ালা', gcolor:'#7BA084', en:'Add building', bn:'বিল্ডিং যোগ', ph:0, ico:'building', render(){
  const titles=['নতুন বিল্ডিং · New building','ঠিকানা · Address','ফ্ল্যাট/ইউনিট · Units','সংক্ষিপ্ত · Review'];
  const backBtn = bStep>1 ? `<button class="iconbtn" onclick="bStep--;repaint()">${kicon('back',{s:20})}</button>` : `<button class="iconbtn" onclick="resetWizard();go('home')">${kicon('back',{s:20})}</button>`;
  const tb = statusbar() + `<div class="topbar">${backBtn}<div class="ttl">${titles[bStep-1]}</div></div>`;
  const prog = `<div style="padding:4px 22px 14px;"><div style="display:flex;gap:6px;align-items:center;">
    ${[1,2,3,4].map(s=>`<div style="flex:${s===bStep?2:1};height:6px;border-radius:3px;background:${s<=bStep?'var(--sage)':'var(--line)'};transition:all .3s;"></div>`).join('')}
  </div><div style="font-size:11px;color:var(--muted);margin-top:6px;font-weight:600;">ধাপ ${bStep}/৪ · Step ${bStep} of 4</div></div>`;

  const mapView = `<div class="k-card" style="padding:0;overflow:hidden;margin-top:12px;">
    <div style="background:var(--ink);color:#fff;padding:8px 12px;display:flex;align-items:center;gap:8px;font-size:11.5px;">${kicon('map',{s:15,c:'#fff'})}<span style="flex:1;font-weight:600;">Google Maps · ট্যাপ করে ঠিকানা নিন</span>${kicon('search',{s:14,c:'#fff'})}</div>
    <div onclick="pickOnMap()" style="height:210px;position:relative;cursor:pointer;background:linear-gradient(135deg,#eef0e8,#dde2d4);">
      <div style="position:absolute;left:0;right:0;top:30%;height:15px;background:#fff;opacity:.65;"></div>
      <div style="position:absolute;left:0;right:0;top:64%;height:12px;background:#fff;opacity:.65;"></div>
      <div style="position:absolute;top:0;bottom:0;left:28%;width:14px;background:#fff;opacity:.65;"></div>
      <div style="position:absolute;top:0;bottom:0;left:72%;width:11px;background:#fff;opacity:.65;"></div>
      <div style="position:absolute;left:32%;top:8%;width:58px;height:30px;background:#c9d2bf;border-radius:3px;opacity:.7;"></div>
      <div style="position:absolute;left:9%;top:42%;width:48px;height:34px;background:#c9d2bf;border-radius:3px;opacity:.7;"></div>
      <div style="position:absolute;left:76%;top:74%;width:44px;height:28px;background:#c9d2bf;border-radius:3px;opacity:.7;"></div>
      ${bPin
        ? `<div style="position:absolute;left:49%;top:44%;transform:translate(-50%,-100%);filter:drop-shadow(0 4px 8px rgba(0,0,0,.3));"><svg width="40" height="50" viewBox="0 0 44 56"><path d="M22 0a18 18 0 0 0-18 18c0 13 18 36 18 36s18-23 18-36A18 18 0 0 0 22 0Z" fill="#E89B8B"/><circle cx="22" cy="18" r="7" fill="#fff"/></svg></div>`
        : `<div style="position:absolute;inset:0;display:grid;place-items:center;"><div style="background:#fff;padding:10px 16px;border-radius:99px;font-size:12.5px;font-weight:700;color:var(--sage-dk);box-shadow:var(--sh-md);font-family:var(--f-title);">✋ ট্যাপ করুন · Tap to drop pin</div></div>`}
      <div style="position:absolute;bottom:6px;right:8px;font-size:9px;color:rgba(0,0,0,.4);font-weight:600;">© Google</div>
    </div>
  </div>`;

  let body='';
  if(bStep===1){
    body=`<div class="pad" style="padding-top:0;">
      ${emojiHero('🏢','Name your building','বিল্ডিংয়ের নাম দিন')}
      <div class="k-field" style="margin-top:16px;"><div class="lab">বিল্ডিংয়ের নাম ★ · Building name</div><input class="k-input" placeholder="যেমন: করিম মঞ্জিল, House 12" value="করিম মঞ্জিল"></div>
      <div class="k-field" style="margin-top:10px;"><div class="lab">এলাকা ★ · Area</div>
        <div style="display:flex;flex-wrap:wrap;gap:7px;margin-top:4px;">
          ${AREAS.map(a=>`<button onclick="bArea='${a}';repaint()" style="padding:8px 14px;border-radius:99px;border:0;cursor:pointer;background:${a===bArea?'var(--sage)':'var(--sage-bg)'};color:${a===bArea?'#fff':'var(--sage-dk)'};font-size:12.5px;font-weight:700;font-family:var(--f-title);">${a}</button>`).join('')}
        </div>
      </div>
      <button class="k-btn primary full lg" style="margin-top:18px;" onclick="bStep=2;repaint()">পরবর্তী · Next ${kicon('arrow',{s:16,c:'#fff'})}</button>
    </div>`;
  } else if(bStep===2){
    body=`<div class="pad" style="padding-top:0;">
      ${emojiHero('📍','Where is it?','ঠিকানা — ম্যাপ থেকে নিন')}
      <button class="k-btn ${bPin?'soft':'primary'} full" style="margin-top:8px;" onclick="bMapOpen=!bMapOpen;repaint()">${kicon('map',{s:18,c:bPin?'#5C8067':'#fff'})} Google Map থেকে বেছে নিন · Pick on map</button>
      ${bMapOpen ? mapView : ''}
      ${bPin ? `<div class="k-card k-soft rowcard" style="background:var(--sage-bg);margin-top:12px;">${kicon('pin',{s:18,c:'#5C8067'})}<div style="flex:1;"><div style="font-size:12.5px;color:var(--sage-dk);font-weight:700;">✓ ম্যাপ থেকে ঠিকানা নেওয়া হয়েছে · Address filled from map</div><div style="font-size:11px;color:var(--muted-dk);font-family:var(--f-mono);margin-top:1px;">23.8103°N, 90.4125°E</div></div><button onclick="bPin=false;repaint()" style="background:none;border:0;color:var(--muted);font-size:12px;font-weight:600;cursor:pointer;">রিসেট</button></div>` : ''}
      <div class="k-field" style="margin-top:12px;"><div class="lab">সম্পূর্ণ ঠিকানা ★ · Full address ${bPin?'<span style="color:var(--sage-dk);">(auto)</span>':''}</div>
        <textarea class="k-input" style="font-family:var(--f-body);font-weight:400;font-size:14px;line-height:1.5;resize:none;" rows="3" placeholder="ম্যাপ থেকে নিন অথবা হাতে লিখুন">${bAddr}</textarea></div>
      <div class="k-card k-soft rowcard" style="background:var(--butter-bg);margin-top:10px;">${kicon('doc',{s:18,c:'#C9755F'})}<div style="font-size:11.5px;color:var(--muted-dk);font-weight:600;line-height:1.5;"><b>এলাকা · Area:</b> ${bArea} · DMP ফর্মে এই ঠিকানা বসবে</div></div>
      <button class="k-btn primary full lg" style="margin-top:16px;" onclick="bStep=3;repaint()">পরবর্তী — ইউনিট · Units ${kicon('arrow',{s:16,c:'#fff'})}</button>
    </div>`;
  } else if(bStep===3){
    const labels = unitLabels();
    const stepCtl = (lab, en, varn, val) => `<div class="k-field" style="margin-bottom:10px;display:flex;align-items:center;gap:12px;"><div style="flex:1;"><div style="font-family:var(--f-title);font-weight:700;font-size:14px;">${lab}</div><div style="font-size:11px;color:var(--muted);">${en}</div></div><div style="display:flex;align-items:center;gap:0;background:var(--sage-bg);border-radius:99px;padding:4px;"><button onclick="${varn}=Math.max(1,${varn}-1);repaint()" style="width:32px;height:32px;border:0;border-radius:99px;background:#fff;font-size:18px;font-weight:800;color:var(--sage-dk);cursor:pointer;">−</button><div style="width:38px;text-align:center;font-family:var(--f-title);font-weight:800;font-size:18px;">${val}</div><button onclick="${varn}=Math.min(20,${varn}+1);repaint()" style="width:32px;height:32px;border:0;border-radius:99px;background:#fff;font-size:18px;font-weight:800;color:var(--sage-dk);cursor:pointer;">+</button></div></div>`;
    body=`<div class="pad" style="padding-top:0;">
      ${emojiHero('🚪','How many flats?','কয়টি ফ্ল্যাট, কোন ফ্লোরে')}
      ${stepCtl('মোট ফ্লোর · Floors','কয়টি তলা', 'uFloors', uFloors)}
      ${stepCtl('প্রতি ফ্লোরে ফ্ল্যাট · Flats / floor','প্রতি তলায় কয়টি', 'uPer', uPer)}
      <div class="k-field" style="margin-bottom:10px;"><div class="lab">নম্বরিং ধরন · Numbering scheme</div>
        <div style="display:flex;gap:8px;margin-top:6px;">
          <button onclick="uScheme='letter';repaint()" style="flex:1;padding:10px;border-radius:12px;border:2px solid ${uScheme==='letter'?'var(--sage)':'var(--line)'};background:${uScheme==='letter'?'var(--sage-bg)':'#fff'};cursor:pointer;font-family:var(--f-title);font-weight:700;font-size:13px;">1A · 1B<div style="font-size:10px;color:var(--muted);font-weight:600;">ফ্লোর + অক্ষর</div></button>
          <button onclick="uScheme='number';repaint()" style="flex:1;padding:10px;border-radius:12px;border:2px solid ${uScheme==='number'?'var(--sage)':'var(--line)'};background:${uScheme==='number'?'var(--sage-bg)':'#fff'};cursor:pointer;font-family:var(--f-title);font-weight:700;font-size:13px;">101 · 102<div style="font-size:10px;color:var(--muted);font-weight:600;">ফ্লোর × ১০০</div></button>
        </div>
      </div>
      <div class="k-card">
        <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:10px;"><div style="font-family:var(--f-title);font-weight:800;font-size:13px;">ইউনিট তালিকা · ${labels.length} units</div><button onclick="uAddCustom()" style="background:var(--rose-bg);color:var(--rose-dk);border:0;border-radius:99px;padding:6px 12px;font-size:11.5px;font-weight:700;font-family:var(--f-title);cursor:pointer;">+ কাস্টম (যেমন 2001, 8B)</button></div>
        <div style="display:flex;flex-wrap:wrap;gap:8px;">
          ${labels.map(l=>`<div style="display:inline-flex;align-items:center;gap:6px;background:var(--sage-bg);color:var(--sage-dk);border-radius:10px;padding:8px 10px;font-family:var(--f-title);font-weight:700;font-size:13px;">${l}<button onclick="uRemoved['${l}']=true;repaint()" style="background:none;border:0;cursor:pointer;color:var(--muted);display:grid;place-items:center;padding:0;">${kicon('x',{s:12,c:'#8C8578',sw:2.4})}</button></div>`).join('')}
          ${labels.length===0?`<div style="font-size:12px;color:var(--muted);padding:8px;">ফ্লোর ও ফ্ল্যাট বাড়ান, অথবা কাস্টম যোগ করুন</div>`:''}
        </div>
        <div style="margin-top:10px;padding-top:10px;border-top:1px dashed var(--line);font-size:11px;color:var(--muted);">প্রতিটি ইউনিটে পরে ভাড়া ও ভাড়াটিয়া যোগ করবেন · Add rent &amp; tenant per unit later</div>
      </div>
      <button class="k-btn primary full lg" style="margin-top:16px;" onclick="bStep=4;repaint()">পরবর্তী — দেখুন · Review ${kicon('arrow',{s:16,c:'#fff'})}</button>
    </div>`;
  } else {
    const labels = unitLabels();
    body=`<div class="pad" style="padding-top:0;">
      ${emojiHero('✅','Looks good?','সব ঠিক আছে?')}
      <div class="k-card" style="margin-top:8px;">
        ${[['বিল্ডিং · Building','করিম মঞ্জিল'],['এলাকা · Area',bArea],['ঠিকানা · Address', (bAddr||'—').split('\n')[0]],['ম্যাপ পিন · Pin', bPin?'✓ সংরক্ষিত':'—'],['মোট ইউনিট · Units', labels.length+' টি ('+uFloors+' ফ্লোর × '+uPer+')']].map((r,i)=>`<div style="display:flex;padding:9px 0;font-size:13px;border-bottom:${i<4?'1px dotted var(--line)':'0'};"><div style="width:120px;color:var(--muted);font-weight:600;">${r[0]}</div><div style="font-weight:700;font-family:var(--f-title);flex:1;">${r[1]}</div></div>`).join('')}
        <div style="display:flex;flex-wrap:wrap;gap:6px;margin-top:10px;padding-top:10px;border-top:1px solid var(--line);">${labels.map(l=>`<span style="background:var(--sage-bg);color:var(--sage-dk);border-radius:8px;padding:4px 9px;font-family:var(--f-title);font-weight:700;font-size:12px;">${l}</span>`).join('')}</div>
      </div>
      <button class="k-btn primary full lg" style="margin-top:16px;" onclick="resetWizard();go('portfolio')">${kicon('check',{s:18,c:'#fff'})} বিল্ডিং সেভ করুন · Save building</button>
    </div>`;
  }
  return tb + prog + `<div class="scroll">${body}</div>`;
}});

// ── PORTFOLIO ──
reg('portfolio', { group:'Landlord · বাড়িওয়ালা', gcolor:'#7BA084', en:'Portfolio', bn:'পোর্টফোলিও', ph:0, ico:'grid', render(){
  const blds=[
    {n:'করিম মঞ্জিল', en:'Karim Manzil', area:'Mirpur 10', u:8, occ:7, mrr:'৫৭K', floors:4, units:['1A','1B','2A','2B','3A','3B','4A','4B']},
    {n:'রহিম ভিলা', en:'Rahim Villa', area:'Uttara 7', u:6, occ:4, mrr:'৪০K', floors:3, units:['101','102','201','202','301','302']},
  ];
  return statusbar() + topbar({title:'পোর্টফোলিও · Portfolio', back:'home', action:`<button class="iconbtn" onclick="go('addBuilding')">${kicon('plus',{s:20})}</button>`}) + `
  <div class="scroll"><div class="pad">
    <div style="display:flex;gap:10px;margin-bottom:14px;">
      <div class="k-card statbox" style="flex:1;">${iconBadge('building','var(--sage-bg)','#5C8067',18,38)}<div class="n">২</div><div class="l">বিল্ডিং · Buildings</div></div>
      <div class="k-card statbox" style="flex:1;">${iconBadge('door','var(--sage-bg)','#5C8067',18,38)}<div class="n">১১/১৪</div><div class="l">ভাড়া হয়েছে · Occupied</div></div>
    </div>
    ${blds.map(b=>`
      <div class="k-card" style="margin-bottom:12px;cursor:pointer;" onclick="go('unit')">
        <div class="rowcard">
          ${iconBadge('building','var(--sage-bg)','#5C8067',22,48)}
          <div style="flex:1;"><div style="font-family:var(--f-title);font-weight:800;font-size:16px;">${b.n}</div><div style="font-size:11.5px;color:var(--muted);margin-top:1px;">${b.en} · ${b.area} · ${b.floors} ফ্লোর</div></div>
          ${kicon('chevron',{s:18,c:'#8C8578'})}
        </div>
        <div style="display:flex;flex-wrap:wrap;gap:5px;margin-top:11px;">
          ${b.units.map((u,i)=>`<span style="background:${i<b.occ?'var(--sage-bg)':'var(--rose-bg)'};color:${i<b.occ?'var(--sage-dk)':'var(--rose-dk)'};border-radius:7px;padding:3px 8px;font-family:var(--f-title);font-weight:700;font-size:11px;">${u}</span>`).join('')}
        </div>
        <div style="display:flex;gap:8px;margin-top:12px;padding-top:12px;border-top:1px solid var(--line);">
          <div style="flex:1;text-align:center;"><div style="font-family:var(--f-title);font-weight:800;font-size:17px;">${b.u}</div><div style="font-size:10px;color:var(--muted);">ইউনিট</div></div>
          <div style="flex:1;text-align:center;"><div style="font-family:var(--f-title);font-weight:800;font-size:17px;color:var(--sage-dk);">${b.occ}</div><div style="font-size:10px;color:var(--muted);">ভাড়া হয়েছে</div></div>
          <div style="flex:1;text-align:center;"><div style="font-family:var(--f-title);font-weight:800;font-size:17px;color:var(--rose-dk);">৳${b.mrr}</div><div style="font-size:10px;color:var(--muted);">মাসিক</div></div>
        </div>
      </div>`).join('')}
    <button class="k-btn soft full" onclick="go('addBuilding')">${kicon('plus',{s:18,c:'#5C8067'})} নতুন বিল্ডিং · Add building</button>
  </div></div>` + bottomnav('home','landlord');
}});

// ── UNIT DETAIL ──
reg('unit', { group:'Landlord · বাড়িওয়ালা', gcolor:'#7BA084', en:'Unit detail', bn:'ইউনিট', ph:0, ico:'door', render(){
  return statusbar() + topbar({title:'ইউনিট 2C · Unit 2C', back:'portfolio', action:`<button class="iconbtn">${kicon('pencil',{s:18})}</button>`}) + `
  <div class="scroll"><div class="pad">
    <div class="k-card" style="background:linear-gradient(135deg,var(--sage),var(--sage-dk));color:#fff;border:0;">
      <span class="k-chip" style="background:rgba(255,255,255,.22);color:#fff;">ভাড়া হয়েছে · Occupied</span>
      <div style="font-family:var(--f-title);font-weight:800;font-size:28px;margin-top:10px;">৳২২,০০০<span style="font-size:14px;opacity:.8;font-weight:600;">/মাস</span></div>
      <div style="font-size:12.5px;opacity:.9;margin-top:4px;">করিম মঞ্জিল · Mirpur 10 · ২ বেড, ১ বাথ</div>
    </div>
    <div class="k-card rowcard" style="margin-top:12px;cursor:pointer;" onclick="go('dmp')">
      ${avatar('K','var(--rose)')}
      <div style="flex:1;"><div style="font-family:var(--f-title);font-weight:700;font-size:15px;">Karim Hossain</div><div style="font-size:11.5px;color:var(--muted);margin-top:1px;">NID যাচাইকৃত · Verified · since Jan 2025</div></div>
      <span class="k-chip solid">${kicon('shield',{s:13,c:'#fff'})}</span>
    </div>
    <div style="display:grid;grid-template-columns:1fr 1fr;gap:10px;margin-top:12px;">
      ${[['DMP ফর্ম','DMP form','doc','dmp'],['ভাড়া চান','Rent request','send','rentReq'],['NID যাচাই','Verify','shield','verify'],['সতর্কতা','Warning','flag','warning']].map(([bn,en,ic,k])=>`
        <div class="k-card k-soft qa" style="background:var(--sage-bg);" onclick="go('${k}')">${iconBadge(ic,'rgba(255,255,255,.6)','#5C8067',18,38)}<div class="qt" style="margin-top:7px;font-size:13.5px;">${bn}</div><div class="qe">${en}</div></div>`).join('')}
    </div>
  </div></div>`;
}});
