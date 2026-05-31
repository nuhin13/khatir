/* ═══ Khatir — Home dashboard visual-direction explorations (canvas only) ═══
   Three takes on the same screen so the user can choose a direction.        */

// Direction A — "Warm" = the production home (emoji hero, soft cards). Reuses SCREENS.home.

// Direction B — "Clean" : line-icon hero, no emoji, tighter rhythm, more data-forward.
function homeClean(){
  return statusbar() + topbar({brand:true, action:bellbtn()}) + `
  <div class="scroll"><div style="padding:2px 20px 14px;">
    <div style="font-family:var(--f-title);font-weight:800;font-size:22px;letter-spacing:-.5px;">করিম সাহেব</div>
    <div style="color:var(--muted);font-size:12px;margin-top:2px;">২ বিল্ডিং · ১৪ ইউনিট · ১৫ মে</div>
  </div>
  <div style="padding:0 20px;">
    <div class="k-card" onclick="go('addTenant')" style="cursor:pointer;border:1.5px solid var(--sage);display:flex;align-items:center;gap:14px;">
      ${iconBadge('doc','var(--sage)','#fff',24,52)}
      <div style="flex:1;"><div style="font-family:var(--f-title);font-weight:800;font-size:16px;">DMP ফর্ম তৈরি করুন</div><div style="font-size:11.5px;color:var(--muted);margin-top:2px;">Police form · 2 minutes</div></div>
      ${kicon('arrow',{s:20,c:'#5C8067'})}
    </div>
  </div>
  <div style="padding:14px 20px 0;">
    <div class="k-card">
      <div style="display:flex;justify-content:space-between;align-items:center;"><span style="font-size:12px;color:var(--muted);font-weight:600;">এ মাসে আদায় · Collected</span><span class="k-chip">৭৬%</span></div>
      <div style="font-family:var(--f-title);font-weight:800;font-size:26px;margin-top:4px;letter-spacing:-.5px;">৳৭১,০০০ <span style="font-size:13px;color:var(--muted);">/৯৩K</span></div>
      <div class="k-track" style="margin-top:8px;"><i style="width:76%"></i></div>
      <div style="display:flex;gap:8px;margin-top:12px;padding-top:12px;border-top:1px solid var(--line);">
        ${[['৳৯৭K','মাসিক ভাড়া'],['১১/১৪','অকুপায়েড'],['১','বাকি']].map(s=>`<div style="flex:1;"><div style="font-family:var(--f-title);font-weight:800;font-size:16px;">${s[0]}</div><div style="font-size:10px;color:var(--muted);font-weight:600;">${s[1]}</div></div>`).join('')}
      </div>
    </div>
  </div>
  <div style="padding:14px 20px 0;">
    <div class="sectit">দ্রুত কাজ · Quick actions</div>
    <div class="k-card" style="padding:6px 0;">
      ${[['addBuilding','building','বিল্ডিং যোগ','Add building'],['rentReq','send','ভাড়া চান','Rent request'],['expenses','wrench','মেরামত ও খরচ','Maintenance'],['dashboard','chart','ড্যাশবোর্ড','Dashboard']].map((q,i)=>`<button class="fieldrow" style="width:100%;border:0;background:none;border-bottom:${i<3?'1px solid var(--line)':'0'};cursor:pointer;text-align:left;" onclick="go('${q[0]}')">${iconBadge(q[1],'var(--sage-bg)','#5C8067',18,38)}<div style="flex:1;"><div style="font-family:var(--f-title);font-weight:700;font-size:14px;">${q[2]}</div><div style="font-size:11px;color:var(--muted);">${q[3]}</div></div>${kicon('chevron',{s:16,c:'#8C8578'})}</button>`).join('')}
    </div>
  </div>
  <div style="padding:14px 20px 22px;">
    <div class="k-card rowcard" style="border:1px solid var(--rose);"><div style="width:8px;height:38px;background:var(--rose);border-radius:99px;"></div><div style="flex:1;"><div style="font-family:var(--f-title);font-weight:700;font-size:13.5px;">Karim H. · 2C — ৳২২,০০০ বাকি</div><div style="font-size:11px;color:var(--muted);">৩ দিন overdue</div></div><button class="k-btn rose sm" onclick="go('rentReq')">চান</button></div>
  </div>
  </div>` + bottomnav('home','landlord');
}

// Direction C — "Editorial" : oversized type, butter accent band, generous whitespace.
function homeEditorial(){
  return statusbar() + `
  <div style="padding:18px 22px 6px;display:flex;justify-content:space-between;align-items:center;">
    <div style="font-family:var(--f-hand);font-size:24px;color:var(--sage-dk);">নমস্কার, করিম</div>
    ${bellbtn()}
  </div>
  <div class="scroll"><div style="padding:6px 22px 0;">
    <div style="font-family:var(--f-title);font-weight:800;font-size:13px;color:var(--muted);letter-spacing:.04em;text-transform:uppercase;">এ মাসে আদায়</div>
    <div style="font-family:var(--f-title);font-weight:800;font-size:46px;letter-spacing:-2px;line-height:1;margin-top:6px;">৳৭১,০০০</div>
    <div style="display:flex;align-items:center;gap:8px;margin-top:8px;"><div class="k-track" style="flex:1;"><i style="width:76%"></i></div><span style="font-family:var(--f-title);font-weight:800;color:var(--sage-dk);">৭৬%</span></div>
  </div>
  <div style="padding:18px 22px 0;">
    <div onclick="go('addTenant')" style="cursor:pointer;background:var(--butter-bg);border-radius:22px;padding:20px;position:relative;overflow:hidden;">
      <div style="font-family:var(--f-title);font-weight:800;font-size:22px;line-height:1.1;letter-spacing:-.5px;max-width:220px;">পুলিশ ফর্ম, ২ মিনিটে</div>
      <div style="font-size:12.5px;color:var(--muted-dk);margin-top:8px;">Snap the NID — the form fills itself.</div>
      <div style="margin-top:14px;display:inline-flex;align-items:center;gap:8px;background:var(--ink);color:#fff;padding:9px 16px;border-radius:99px;font-family:var(--f-title);font-weight:700;font-size:13px;">শুরু করি ${kicon('arrow',{s:15,c:'#fff'})}</div>
      <div style="position:absolute;right:14px;bottom:14px;opacity:.5;">${kicon('doc',{s:60,c:'#D9B45F',sw:1.4})}</div>
    </div>
  </div>
  <div style="padding:16px 22px 0;display:grid;grid-template-columns:1fr 1fr;gap:1px;background:var(--line);border-radius:18px;overflow:hidden;">
    ${[['বিল্ডিং','২','building'],['ইউনিট','১৪','door'],['ভাড়াটিয়া','১২','user'],['বাকি','১','clock']].map(s=>`<div style="background:var(--card);padding:16px 14px;"><div style="display:flex;align-items:center;gap:7px;color:var(--muted);">${kicon(s[2],{s:15,c:'#8C8578'})}<span style="font-size:11px;font-weight:700;">${s[0]}</span></div><div style="font-family:var(--f-title);font-weight:800;font-size:24px;margin-top:6px;">${s[1]}</div></div>`).join('')}
  </div>
  <div style="padding:18px 22px 22px;">
    <div style="display:flex;gap:10px;">
      <button class="k-btn dark" style="flex:1;" onclick="go('rentReq')">${kicon('send',{s:16,c:'#fff'})} ভাড়া চান</button>
      <button class="k-btn soft" style="flex:1;" onclick="go('expenses')">${kicon('wrench',{s:16,c:'#5C8067'})} খরচ</button>
    </div>
  </div>
  </div>` + bottomnav('home','landlord');
}
