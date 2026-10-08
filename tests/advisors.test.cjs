const {test}=require('node:test');
const assert=require('node:assert/strict');
const fs=require('node:fs');
const vm=require('node:vm');
function load(){
 const elements=new Map();
 function element(id){
  if(!elements.has(id))elements.set(id,{textContent:'',style:{},children:[],listeners:{},addEventListener(type,fn){this.listeners[type]=fn},prepend(li){this.children.unshift(li)}});
  return elements.get(id);
 }
 const buttons=['economy','army','reform','diplomacy'].map(action=>Object.assign(element(action),{dataset:{action}}));
 const document={getElementById:element,createElement:()=>({textContent:''}),querySelectorAll:selector=>selector==='[data-action]'?buttons:[]};
 const context=vm.createContext({document});
 vm.runInContext(fs.readFileSync('game.js','utf8'),context);
 return {context,element,run:code=>vm.runInContext(code,context)};
}
const baseline={money:500,stability:50,support:50,army:50};
for(const [key,label,low,high] of [['money','الخزانة',159,1000],['stability','الاستقرار',34,70],['support','التأييد',34,70],['army','جاهزية الجيش',34,70]]){
 for(const [value,band] of [[low,'منخفض'],[key==='money'?160:35,'متوسط'],[key==='money'?999:69,'متوسط'],[high,'مرتفع']]){
  test(`${key} ${value}: ${band}`,()=>{
   const app=load();const advice=app.run(`getAdvisorRecommendations(${JSON.stringify({...baseline,[key]:value})})`);
   const text=key==='money'||key==='support'?advice.economy:advice.security;
   const expected=key==='money'?{منخفض:'منخفضة',متوسط:'متوسطة',مرتفع:'قوية'}[band]:key==='army'?band+'ة':band;
   assert.ok(text.includes(`${label} ${expected}`),text);
  });
 }
}
test('conflicting crises prioritize stability and unaffordable actions are deferred',()=>{
 const app=load();
 for(const money of [0,59,60,79,80,159,160]){
  const advice=app.run(`getAdvisorRecommendations({money:${money},stability:0,support:0,army:0})`);
  assert.match(advice.security,money<160?/أجّل التحديث حتى يتوفر 160/:/أجّل التحديث إلى ما بعد تحسين الاستقرار/);
  assert.match(advice.economy,money<60?/لا توجد قرارات متاحة/:/أوصي بمبادرة دبلوماسية/);
 }
});
test('all-low and all-high states, including percentage extremes',()=>{
 const app=load();
 for(const value of [0,100]){
  const state={money:value===0?0:5000,stability:value,support:value,army:value};
  const before=JSON.stringify(state);
  const advice=app.run(`getAdvisorRecommendations(${before})`);
  assert.ok(advice.economy&&advice.security);
  assert.ok(!/undefined|NaN/.test(advice.economy+advice.security));
  assert.equal(JSON.stringify(state),before);
 }
});
test('initial render and every decision update both advisor paragraphs',()=>{
 for(const action of ['economy','army','reform','diplomacy']){
  const app=load();
  app.run('Object.assign(state,{money:1000,stability:34,support:34,army:34});render()');
  const before=app.element('security-advice').textContent;
  app.element(action).listeners.click();
  const expected=app.run('getAdvisorRecommendations(state)');
  assert.equal(app.element('economy-advice').textContent,expected.economy);
  assert.equal(app.element('security-advice').textContent,expected.security);
  assert.notEqual(app.element('security-advice').textContent,before);
 }
});
test('ending a turn updates recommendations with income, unrest and periodic instability',()=>{
 const app=load();
 assert.ok(app.element('economy-advice').textContent.includes('1,000'));
 app.run('Object.assign(state,{turn:2,money:50,stability:34,support:35,army:70});render()');
 app.element('next-turn').listeners.click();
 assert.equal(app.run('state.turn'),3);
 assert.equal(app.run('state.money'),170);
 assert.equal(app.run('state.support'),32);
 assert.equal(app.run('state.stability'),33);
 const expected=app.run('getAdvisorRecommendations(state)');
 assert.equal(app.element('economy-advice').textContent,expected.economy);
 assert.equal(app.element('security-advice').textContent,expected.security);
});
