const state={turn:1,money:1000,stability:54,support:48,army:42,region:"ragmanov"};
const $=id=>document.getElementById(id);
const clamp=n=>Math.max(0,Math.min(100,n));
function render(){ $("turn").textContent=state.turn; $("money").textContent=state.money.toLocaleString("en-US"); ["stability","support","army"].forEach(k=>{ $(k).textContent=state[k]+"%"; $(k+"-bar").style.width=state[k]+"%";}); document.querySelectorAll("[data-action]").forEach(b=>b.disabled=state.money<({economy:100,army:160,reform:80,diplomacy:60}[b.dataset.action]));}
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