const state={turn:1,money:1000,stability:54,support:48,army:42,region:"ragmanov"};
const $=id=>document.getElementById(id);
const clamp=n=>Math.max(0,Math.min(100,n));
// Percentage bands: low < 35, high >= 70. Treasury: low < 160, high >= 1000.
function getAdvisorRecommendations(current){
 const {money,stability,support,army}=current;
 const funds=money.toLocaleString("en-US");
 const economy=[];
 if(money<160){
  economy.push(`الخزانة منخفضة (${funds} مليون وحدة). احتفظ باحتياطي وتجنب الإنفاق الكبير.`);
  economy.push(money<60 ? "أنه الدور لتحصيل الدخل؛ لا توجد قرارات متاحة حاليًا." : "وازن بين القرارات المتاحة وتكلفتها قبل الإنفاق.");
 }else if(money>=1000){
  economy.push(`الخزانة قوية (${funds} مليون وحدة). يمكنك تمويل تنشيط الاقتصاد مع الاحتفاظ باحتياطي.`);
 }else{
  economy.push(`الخزانة متوسطة (${funds} مليون وحدة). نفّذ الإنفاق تدريجيًا واحتفظ باحتياطي للدور التالي.`);
 }
 if(support<35){
  economy.push(`التأييد منخفض (${support}%). `+(money>=60 ? "أوصي بمبادرة دبلوماسية لرفع التأييد والاستقرار بتكلفة 60." : "أجّل المبادرة الدبلوماسية حتى يتوفر 60 في الخزانة."));
 }else if(support>=70){
  economy.push(`التأييد مرتفع (${support}%). حافظ على الثقة الشعبية ولا تستنزف الخزانة.`);
 }else{
  economy.push(`التأييد متوسط (${support}%). عزّز الثقة بتحسين الاستقرار والتواصل الدبلوماسي.`);
 }
 const security=[];
 if(stability<35){
  security.push(`الاستقرار منخفض (${stability}%). `+(money>=80 ? "أعطِ الأولوية للإصلاحات الإدارية بتكلفة 80 قبل تحديث الجيش." : money>=60 ? "ابدأ بمبادرة دبلوماسية بتكلفة 60 لتحسين الاستقرار." : "انتظر دخل الدور لتمويل تحسين الاستقرار."));
 }else if(stability>=70){
  security.push(`الاستقرار مرتفع (${stability}%). حافظ على المؤسسات وتجنب الإنفاق الذي يضعفها.`);
 }else{
  security.push(`الاستقرار متوسط (${stability}%). واصل تحسين المؤسسات وراقب أثر القرارات عليه.`);
 }
 if(army<35){
  security.push(`جاهزية الجيش منخفضة (${army}%). `+(money<160 ? "أجّل التحديث حتى يتوفر 160 في الخزانة." : stability<35 ? "أجّل التحديث إلى ما بعد تحسين الاستقرار؛ التحديث يخفضه بنقطتين." : "أوصي بتحديث الجيش بتكلفة 160؛ سيرفع الجاهزية 12 نقطة ويخفض الاستقرار بنقطتين."));
 }else if(army>=70){
  security.push(`جاهزية الجيش مرتفعة (${army}%). لا حاجة ملحّة للتحديث؛ وجّه الموارد لأولويات الدولة الأخرى.`);
 }else{
  security.push(`جاهزية الجيش متوسطة (${army}%). راقبها ووازن تكلفة التحديث مع احتياجات الدولة.`);
 }
 return {economy:economy.join(" "),security:security.join(" ")};
}
function renderAdvisors(){
 const advice=getAdvisorRecommendations(state);
 $("economy-advice").textContent=advice.economy;
 $("security-advice").textContent=advice.security;
}
function render(){ renderAdvisors(); $("turn").textContent=state.turn; $("money").textContent=state.money.toLocaleString("en-US"); ["stability","support","army"].forEach(k=>{ $(k).textContent=state[k]+"%"; $(k+"-bar").style.width=state[k]+"%";}); document.querySelectorAll("[data-action]").forEach(b=>b.disabled=state.money<({economy:100,army:160,reform:80,diplomacy:60}[b.dataset.action]));}
function log(text){const li=document.createElement("li");li.textContent=text;$("log").prepend(li);while($("log").children.length>8)$("log").lastElementChild.remove();}
const actions={
 economy(){state.money-=100;state.support=clamp(state.support+3);state.stability=clamp(state.stability+2);log("أُطلقت خطة لتنشيط الاقتصاد.");return "بدأت الخطة الاقتصادية. قد تظهر نتائجها في الأدوار التالية."},
 army(){state.money-=160;state.army=clamp(state.army+12);state.stability=clamp(state.stability-2);log("أُقرّت ميزانية تحديث الجيش.");return "ارتفعت جاهزية الجيش، لكن الإنفاق ضغط على الاستقرار."},
 reform(){state.money-=80;state.stability=clamp(state.stability+8);state.support=clamp(state.support+2);log("بدأت إصلاحات إدارية في مؤسسات الدولة.");return "الإصلاحات الإدارية حسّنت الاستقرار والتأييد."},
 diplomacy(){state.money-=60;state.stability=clamp(state.stability+4);state.support=clamp(state.support+4);log("أعلنت الرئاسة مبادرة دبلوماسية مع الجمهوريات المجاورة.");return "المبادرة فتحت باب الحوار ورفعت التأييد."}
};
document.querySelectorAll("[data-action]").forEach(b=>b.addEventListener("click",()=>{const result=actions[b.dataset.action]();$("message").textContent=result;render();}));
$("next-turn").addEventListener("click",()=>{state.turn++;state.money+=120;if(state.stability<35){state.support=clamp(state.support-3);log("احتجاجات جديدة بسبب تراجع الاستقرار.");}else{state.money+=Math.round(state.stability/5);log("بدأ دور جديد: دخل دوري وصل إلى الخزانة.");}if(state.turn%3===0){state.stability=clamp(state.stability-1);log("الخلافات بين الجمهوريات تزيد الضغط على الحكومة.");}$("message").textContent="انتهى الدور. راجع تقرير الدولة واختر أوامرك الجديدة.";render();});
const regions={ragmanov:["رغمنوف","أكبر الجمهوريات ومركز الثقل السياسي."],north:["الجمهورية الشمالية","منطقة ذات أهمية استراتيجية وعلاقات متوترة مع المركز."],south:["الجمهورية الجنوبية","منطقة زراعية وتجارية تحتاج إلى دعم البنية التحتية."]};
document.querySelectorAll("[data-region]").forEach(el=>el.addEventListener("click",()=>{document.querySelectorAll("[data-region]").forEach(x=>x.classList.remove("selected"));el.classList.add("selected");const r=regions[el.dataset.region];$("region-info").innerHTML="";const title=document.createElement("strong"),desc=document.createElement("span");title.textContent=r[0];desc.textContent=r[1];$("region-info").append(title,desc);}));
render();