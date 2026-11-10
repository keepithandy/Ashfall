// Reproducible, original Ashfall decorative geometry generator. Node.js >=18.
// Run in the repo root: node assets/decorative_world/source/generate_props.cjs
// Generates the twelve supplementary non-interactive glTF 2.0 binary models.
const fs = require('node:fs');
const path = require('node:path');
const generateAll = function generateAll() {
 const MAT={
  weathered_metal:[.28,.30,.285,1,.79,.55],oxidized:[.32,.125,.075,1,.94,.35],dark_oxidized:[.14,.074,.058,1,.97,.29],
  faded_paint:[.37,.42,.355,1,.85,.25],chipped_paint:[.59,.57,.48,1,.9,.12],dirt:[.20,.175,.135,1,1,.01],
  black:[.07,.075,.075,1,.93,.04],charcoal:[.13,.135,.13,1,.91,.08],galvanized:[.40,.43,.42,1,.76,.70],
  porcelain:[.53,.51,.44,1,.78,.03],clay:[.39,.23,.145,1,.95,.02],stone:[.34,.34,.32,1,1,.0],
  concrete:[.40,.4,.36,1,.96,.01],moss:[.18,.25,.14,1,1,.0],dead_leaves:[.31,.25,.14,1,.97,.0],
  wood:[.32,.23,.145,1,.95,.0],old_wood:[.20,.16,.105,1,.97,.01],rotten_wood:[.125,.116,.083,1,1,.01],
  cloth:[.45,.43,.35,1,1,0],faded_red:[.38,.19,.16,1,.98,0],paper:[.65,.61,.49,1,.96,0],
  faded_blue:[.21,.285,.32,1,.94,.06],glass:[.24,.27,.26,.30,.23,0],bolt:[.19,.20,.19,1,.64,.8],
  cable:[.065,.07,.065,1,.94,.1],sienna:[.4,.27,.15,1,.91,.1],red_fabric:[.44,.23,.19,1,.97,0],
  pale_green:[.28,.33,.20,1,.9,.02],soot:[.09,.09,.087,1,1,.06]
 };
 function sub(a,b){return[a[0]-b[0],a[1]-b[1],a[2]-b[2]]}
 function add(a,b){return[a[0]+b[0],a[1]+b[1],a[2]+b[2]]}
 function mul(a,t){return[a[0]*t,a[1]*t,a[2]*t]}
 function cross(a,b){return[a[1]*b[2]-a[2]*b[1],a[2]*b[0]-a[0]*b[2],a[0]*b[1]-a[1]*b[0]]}
 function norm(a){let m=Math.hypot(...a)||1;return a.map(v=>v/m)}
 class Mesh{
  constructor(seed=42){this.parts={};this.seed=seed;this.faces=0}
  rnd(){this.seed=(Math.imul(this.seed,1664525)+1013904223)>>>0;return this.seed/4294967296}
  tri(a,b,c,k){const normal=norm(cross(sub(b,a),sub(c,a)));const p=this.parts[k]||(this.parts[k]={p:[],n:[]});for(const q of [a,b,c]){p.p.push(...q);p.n.push(...normal)}this.faces++}
  quad(a,b,c,d,k){this.tri(a,b,c,k);this.tri(a,c,d,k)}
  box(c,s,k,rotation=0){const pts=[];for(let i=0;i<8;i++){let x=(i&1?s[0]:-s[0])/2,y=(i&2?s[1]:-s[1])/2,z=(i&4?s[2]:-s[2])/2;pts.push([c[0]+x*Math.cos(rotation)-z*Math.sin(rotation),c[1]+y,c[2]+x*Math.sin(rotation)+z*Math.cos(rotation)])}
   // winding preserved for a box in right-handed glTF
   for(const face of [[0,2,3,1],[4,5,7,6],[0,4,6,2],[1,3,7,5],[0,1,5,4],[2,6,7,3]])this.quad(...face.map(i=>pts[i]),k)
  }
  rod(a,b,r,k,N=10){const d=norm(sub(b,a)),t=norm(cross(d,Math.abs(d[1])>.95?[1,0,0]:[0,1,0])),u=norm(cross(d,t)),ra=[],rb=[];
   for(let i=0;i<N;i++){let v=add(mul(t,r*Math.cos(i*2*Math.PI/N)),mul(u,r*Math.sin(i*2*Math.PI/N)));ra.push(add(a,v));rb.push(add(b,v))}
   for(let i=0;i<N;i++){let j=(i+1)%N;this.quad(ra[i],rb[i],rb[j],ra[j],k);this.tri(a,ra[j],ra[i],k);this.tri(b,rb[i],rb[j],k)}
  }
  pipe(a,b,ra,rb,k,N=18){let d=norm(sub(b,a)),t=norm(cross(d,Math.abs(d[1])>.95?[1,0,0]:[0,1,0])),u=norm(cross(d,t));
   const ring=(p,r,i)=>add(p,add(mul(t,r*Math.cos(i*2*Math.PI/N)),mul(u,r*Math.sin(i*2*Math.PI/N))));
   for(let i=0;i<N;i++){let j=(i+1)%N;this.quad(ring(a,ra,i),ring(b,ra,i),ring(b,ra,j),ring(a,ra,j),k);this.quad(ring(a,rb,j),ring(b,rb,j),ring(b,rb,i),ring(a,rb,i),k);this.quad(ring(a,ra,j),ring(a,ra,i),ring(a,rb,i),ring(a,rb,j),k);this.quad(ring(b,ra,i),ring(b,ra,j),ring(b,rb,j),ring(b,rb,i),k)}
  }
  sphere(c,r,k,segments=10,rings=6){for(let i=0;i<rings;i++)for(let j=0;j<segments;j++){let p=(u,v)=>{let lat=-Math.PI/2+Math.PI*u/rings,lon=2*Math.PI*v/segments;return[c[0]+r*Math.cos(lat)*Math.cos(lon),c[1]+r*Math.sin(lat),c[2]+r*Math.cos(lat)*Math.sin(lon)]};this.quad(p(i,j),p(i,j+1),p(i+1,j+1),p(i+1,j),k)}}
  cylinder(c,r,he,k,N=16){this.rod([c[0],c[1]-he/2,c[2]],[c[0],c[1]+he/2,c[2]],r,k,N)}
  torus(c,R,r,k,N=24,M=7){let p=(i,j)=>{let t=i*Math.PI*2/N,u=j*Math.PI*2/M;return[c[0]+(R+r*Math.cos(u))*Math.cos(t),c[1]+r*Math.sin(u),c[2]+(R+r*Math.cos(u))*Math.sin(t)]};
   for(let i=0;i<N;i++)for(let j=0;j<M;j++)this.quad(p(i,j),p(i+1,j),p(i+1,j+1),p(i,j+1),k)
  }
  ribbon(path,width,k){for(let i=0;i<path.length-1;i++){let a=path[i],b=path[i+1];this.quad([a[0]-width/2,a[1],a[2]],[a[0]+width/2,a[1],a[2]],[b[0]+width/2,b[1],b[2]],[b[0]-width/2,b[1],b[2]],k)}}
  line(path,r,k){for(let i=0;i<path.length-1;i++)this.rod(path[i],path[i+1],r,k,7)}
  // Translucent sheet in the vertical X/Y plane with organically broken edges.
  shard(v,k="glass"){for(let i=1;i<v.length-1;i++)this.tri(v[0],v[i],v[i+1],k)}
  grime(c,s,num){for(let i=0;i<num;i++){let x=c[0]+(this.rnd()-.5)*s[0],z=c[2]+(this.rnd()-.5)*s[2];this.box([x,c[1]+.004,z],[.015+.035*this.rnd(),.003,.02+.05*this.rnd()],this.rnd()>.50?"dark_oxidized":"oxidized")}}
  toGLB(){
   let names=Object.keys(this.parts);let mats=names.map(k=>{let q=MAT[k];return{name:k,pbrMetallicRoughness:{baseColorFactor:q.slice(0,4),roughnessFactor:q[4],metallicFactor:q[5]},alphaMode:q[3]<1?"BLEND":"OPAQUE",doubleSided:true}}),views=[],acc=[],prims=[],binparts=[],off=0;
   const flts=(xs)=>{let a=new Uint8Array(xs.length*4),d=new DataView(a.buffer);for(let i=0;i<xs.length;i++)d.setFloat32(i*4,xs[i],true);return a};
   function push(bytes){let pad=(4-off%4)%4;if(pad){binparts.push(new Uint8Array(pad));off+=pad}let idx=views.length;views.push({buffer:0,byteOffset:off,byteLength:bytes.length,target:34962});binparts.push(bytes);off+=bytes.length;return idx}
   for(let id=0;id<names.length;id++){let p=this.parts[names[id]],N=p.p.length/3;let pp=push(flts(p.p)),nn=push(flts(p.n));let mins=[Infinity,Infinity,Infinity],maxs=[-Infinity,-Infinity,-Infinity];for(let i=0;i<p.p.length;i++) {let d=i%3;mins[d]=Math.min(mins[d],p.p[i]);maxs[d]=Math.max(maxs[d],p.p[i])}
    let pa=acc.length;acc.push({bufferView:pp,componentType:5126,count:N,type:"VEC3",min:mins,max:maxs});let na=acc.length;acc.push({bufferView:nn,componentType:5126,count:N,type:"VEC3"});prims.push({attributes:{POSITION:pa,NORMAL:na},mode:4,material:id})}
   let padding=(4-off%4)%4,bin=new Uint8Array(off+padding),at=0;for(let part of binparts){bin.set(part,at);at+=part.length}
   const doc={asset:{version:"2.0",generator:"Ashfall decorative-world mesh source"},scenes:[{nodes:[0]}],scene:0,nodes:[{name:"AshfallDecorativeProp",mesh:0}],meshes:[{primitives:prims}],materials:mats,buffers:[{byteLength:bin.length}],bufferViews:views,accessors:acc};
   const json=JSON.stringify(doc);let jb=new Uint8Array(json.length);for(let i=0;i<json.length;i++)jb[i]=json.charCodeAt(i);
   let jp=(4-jb.length%4)%4,length=12+8+jb.length+jp+8+bin.length,out=new Uint8Array(length),dv=new DataView(out.buffer);dv.setUint32(0,0x46546c67,true);dv.setUint32(4,2,true);dv.setUint32(8,length,true);dv.setUint32(12,jb.length+jp,true);dv.setUint32(16,0x4e4f534a,true);out.set(jb,20);out.fill(32,20+jb.length,20+jb.length+jp);let ba=20+jb.length+jp;dv.setUint32(ba,bin.length,true);dv.setUint32(ba+4,0x004e4942,true);out.set(bin,ba+8);
   if(dv.getUint32(8,true)!==out.length||prims.some(p=>!p.attributes))throw Error("bad glTF envelope");return out
  }
 }
 const props={};
 function mailbox(){
  let m=new Mesh(111);m.rod([-.16,0,.10],[.10,1.12,.09],.055,"oxidized",11);m.box([-.02,.10,.11],[.26,.16,.25],"stone");m.box([.12,1.26,0],[.42,.22,.66],"faded_paint");
  for(let j=0;j<12;j++){let a=j*Math.PI/12,b=(j+1)*Math.PI/12;let p=t=>[.12+.215*Math.cos(t),1.365+.215*Math.sin(t)];let q=p(a),r=p(b);m.quad([q[0],q[1],-.33],[r[0],r[1],-.33],[r[0],r[1],.33],[q[0],q[1],.33],j%4===0?"oxidized":"faded_paint")}
  m.box([.12,1.28,-.341],[.38,.18,.025],"dark_oxidized");m.box([.12,1.3,-.355],[.31,.105,.008],"chipped_paint");
  m.box([.34,1.49,-.13],[.024,.13,.18],"oxidized");m.box([.34,1.56,-.20],[.13,.15,.012],"faded_red");for(let x of [-.03,.18])for(let z of [-.18,.24])m.rod([x,1.14,z],[x,1.158,z],.017,"bolt",8);
  for(let i=0;i<22;i++){let x=-.07+m.rnd()*.39,z=-.3+m.rnd()*.6;m.box([x,1.372,z],[.018+m.rnd()*.035,.008,.03+m.rnd()*.08],i%3?"oxidized":"dark_oxidized")};return m
 }
 function chair(){
  let m=new Mesh(211);for(let x of [-.50,.50])for(let z of [-.38,.31]){let fall=(x<0&&z>0)?-.055:0;m.rod([x+fall,.04,z],[x,.68,z],.045,"old_wood",9);m.rod([x,.11,z],[x,.15,z],.055,"rotten_wood",9)}
  for(let z=-.36;z<=.39;z+=.17){m.box([0,.68,z],[1.15,.07,.145],m.rnd()>.35?"old_wood":"wood",.02*(m.rnd()-.5))}
  for(let x of [-.47,.47])m.rod([x,.65,.34],[x+.065,1.58,.59],.047,"wood");
  for(let y of [.92,1.14,1.37]){m.box([0,y,.48+(y-.92)*.29],[.97,.13,.045],y===1.14?"rotten_wood":"old_wood");for(let x of [-.3,.31])m.rod([x,y-.07,.49+(y-.92)*.29],[x,y-.04,.49+(y-.92)*.29],.015,"oxidized")}
  for(let x of [-.50,.5]){m.rod([x,.69,-.32],[x,.95,-.28],.043,"old_wood");m.box([x,1.0,-.13],[.075,.055,.47],x===-.5?"rotten_wood":"wood")}
  for(let i=0;i<30;i++){let x=(m.rnd()-.5)*1.05,z=(m.rnd()-.5)*.65;m.box([x,.72,z],[.03,.005,.005+.06*m.rnd()],"rotten_wood")};return m
 }
 function pots(){
  let m=new Mesh(311);
  const pot=(x,z,r,h,off)=>{
   let N=18;const ring=(y,R,j)=>[x+R*Math.cos(j*2*Math.PI/N),y,z+R*Math.sin(j*2*Math.PI/N)];
   for(let i=0;i<N;i++){let j=(i+1)%N;m.quad(ring(off,.68*r,i),ring(off,.68*r,j),ring(off+h,r,j),ring(off+h,r,i),i%9===0?"oxidized":"clay");m.quad(ring(off+h,r,i),ring(off+h,r,j),ring(off+h,r*.79,j),ring(off+h,r*.79,i),"porcelain")}
   m.torus([x,off+h,z],r*.93,r*.085,"clay",20,6);m.cylinder([x,off+h-.05,z],r*.8,.055,"dirt",18);
   for(let b=0;b<5;b++){let xx=x+(m.rnd()-.5)*r,zz=z+(m.rnd()-.5)*r;let top=[xx,off+h+.06,zz],end=[xx+(m.rnd()-.5)*.40,off+h+.3+m.rnd()*.36,zz+(m.rnd()-.5)*.30];m.rod(top,end,.006,"old_wood",5);if(m.rnd()>.5)m.rod(end,[end[0]+.12,end[1]-.14,end[2]+.03],.004,"dead_leaves",5)}
   m.line([[x-r*.35,off+h*.16,z+r*.6],[x-r*.16,off+h*.38,z+r*.76],[x-r*.31,off+h*.65,z+r*.75]],.006,"dark_oxidized")
  };
  pot(-.4,-.2,.27,.43,.0);pot(.38,.05,.38,.58,.0);pot(.02,.46,.19,.27,.0);
  for(let i=0;i<8;i++){let x=(m.rnd()-.5)*1.1,z=(m.rnd()-.5)*.95;m.box([x,.02,z],[.06,.025,.03],"clay",m.rnd()*.6)}return m
 }
 function laundry(){
  let m=new Mesh(411);
  for(let x of [-2.05,2.05]){m.rod([x,0,0],[x+(x>0?.05:-.08),2.12,0],.048,"old_wood",10);m.rod([x-.12,.04,0],[x+.15,.05,0],.08,"rotten_wood",8)}
  let line=[];for(let i=0;i<=20;i++){let x=-2.0+i*.2;line.push([x,2.03-.27*(1-(x/2)*(x/2)),0])}m.line(line,.009,"cable");
  const rag=(cx,w,h,k,phase)=>{let i=Math.round((cx+2)*5),y=line[i][1]-.015,z=.025;
   const cols=6,rows=4;
   const p=(u,v)=>{let xx=cx+(u/cols-.5)*w,yy=y-v/rows*h+Math.sin(u*.9+phase)*.018+Math.sin(v*.9+phase)*.012,zz=z+.055*Math.sin(u*1.6+v*.9+phase);return[xx,yy,zz]};
   for(let a=0;a<cols;a++)for(let b=0;b<rows;b++){if(a===0&&b===rows-1&&phase===1)continue;if(a===cols-1&&b===rows-1&&phase===3)continue;m.quad(p(a,b),p(a+1,b),p(a+1,b+1),p(a,b+1),k)}
   for(let x of [cx-w*.34,cx+w*.31]){m.box([x,y+.025,0],[.022,.055,.027],"old_wood")}};
  rag(-1.3,.75,.75,"cloth",1);rag(-.15,.68,.96,"faded_blue",2);rag(.98,.98,.49,"faded_red",3);
  m.line([[-1.8,1.83,.04],[-1.72,1.66,.13],[-1.67,1.55,.12]],.004,"black");
  return m
 }
 function duct(){
  let m=new Mesh(511);const along=[[-1.45,.9,0],[-.85,.90,.03],[-.25,.93,.05],[.46,.75,.02],[1.02,.62,-.10],[1.46,.50,-.15]],H=.54,W=.68;
  for(let i=0;i<along.length-1;i++){let a=along[i],b=along[i+1],w=W*(i>=3?.84:1),h=H*(i>=4?.72:1);let corners=(p,ww,hh)=>[[p[0],p[1]-hh/2,p[2]-ww/2],[p[0],p[1]+hh/2,p[2]-ww/2],[p[0],p[1]+hh/2,p[2]+ww/2],[p[0],p[1]-hh/2,p[2]+ww/2]];
   let v=corners(a,w,h),u=corners(b,w,h);for(let j=0;j<4;j++)m.quad(v[j],u[j],u[(j+1)%4],v[(j+1)%4],(j+i)%5===0?"oxidized":"galvanized")}
  for(let i of [0,2,4]){let a=along[i];m.box([a[0],a[1],a[2]-.35],[.055,.65,.035],"weathered_metal");m.box([a[0],a[1],a[2]+.35],[.055,.65,.035],"oxidized");m.box([a[0],a[1]+.29,a[2]],[.055,.034,.76],"weathered_metal")}
  for(let i=0;i<24;i++){let x=-1.3+m.rnd()*2.7,y=.79+m.rnd()*.1,z=.33*(m.rnd()>.5?1:-1);m.box([x,y,z],[.035,.02,.025],i%3?"dark_oxidized":"oxidized")}
  m.rod([1.5,.5,-.10],[1.57,.31,-.17],.08,"oxidized",8);
  m.box([-.8,.63,.05],[.4,.02,.51],"dark_oxidized");return m
 }
 function cableTray(){
  let m=new Mesh(611);
  for(let z of [-.52,.52]){let path=[];for(let i=0;i<13;i++){let x=-1.55+i*.265,delta=.10*Math.sin(i*.48)+(i>8?-.07*(i-8):0);path.push([x,1.0+delta,z+(i>7?.027*(i-7):0)])}m.line(path,.038,"weathered_metal")}
  for(let i=0;i<14;i++){let x=-1.5+i*.23,y=1.02+.11*Math.sin(i*.45);m.rod([x,y,-.52],[x,y,.52],.018,i%4===0?"oxidized":"weathered_metal",7)}
  for(let i=0;i<6;i++){let x=-1.4+i*.56;m.rod([x,1.05,-.52],[x,1.28,-.52],.026,"oxidized");m.rod([x,1.05,.52],[x,1.28,.52],.026,"weathered_metal")}
  for(let i=0;i<4;i++){let z=-.34+i*.22;let path=[];for(let j=0;j<=11;j++){let x=-1.55+j*.28;path.push([x,1.08+.032*i-.04*Math.sin(j*.7+i)+ (j>8?-.17:0),z+.035*Math.sin(j*.55+i)])}m.line(path,.012,i%2?"black":"cable")}
  for(let x of [-1.3,1.15]){m.rod([x,1.0,0],[x,.22,0],.055,"old_wood",8);m.box([x,.16,0],[.20,.08,.17],"concrete")}
  return m
 }
 function scrap(){
  let m=new Mesh(711);
  for(let layer=0;layer<8;layer++){let z=(layer-3.5)*.13;let y=.1+layer*.053,wa=1.65-.035*layer,wz=.77;const strips=8,depth=3;
   let vertex=(i,j)=>{let x=-wa/2+i*wa/strips,zz=z-wz/2+j*wz/depth,yy=y+.03*Math.sin(i*1.8+layer*.75)+.02*Math.sin(j*2.1+layer);return[x,yy,zz]};
   for(let i=0;i<strips;i++)for(let j=0;j<depth;j++){m.quad(vertex(i,j),vertex(i+1,j),vertex(i+1,j+1),vertex(i,j+1),layer%3===0?"oxidized":layer%4===0?"faded_paint":"galvanized")}
   for(let j=0;j<4;j++)m.rod(vertex(0,j),vertex(8,j),.009,layer%2?"oxidized":"dark_oxidized",5);
   for(let i=0;i<12;i++){let x=-.77+m.rnd()*1.52,zz=z+(m.rnd()-.5)*.6;m.box([x,y+.039,zz],[.015+.085*m.rnd(),.004,.015+.06*m.rnd()],i%5?"oxidized":"dark_oxidized")}
  }
  for(let x of [-.71,.65])m.rod([x,0,-.7],[x,.3,-.7],.03,"old_wood");
  return m
 }
 function windowFrame(){
  let m=new Mesh(811);
  for(let x of [-1.21,1.21]){m.box([x,1.18,.0],[.16,2.35,.15],"oxidized");m.box([x,1.18,-.02],[.08,2.21,.1],"weathered_metal")}
  for(let y of [.07,1.12,2.29])m.box([0,y,0],[2.51,.13,.15],y===1.12?"weathered_metal":"oxidized");
  for(let x of [-.01])m.box([x,1.16,0],[.092,2.24,.11],"weathered_metal");
  m.shard([[-1.12,.16,.002],[-.11,.16,.002],[-.14,.77,.002],[-.52,.92,.002],[-.7,.66,.002],[-1.12,.73,.002]],"glass");
  m.shard([[.1,.19,0],[1.1,.19,0],[1.1,1.05,0],[.89,.83,0],[.58,.94,0],[.25,.44,0]],"glass");
  m.shard([[-1.11,1.2,.001],[-.13,1.2,.001],[-.13,2.2,.001],[-.85,2.15,.001],[-.94,1.72,.001],[-1.11,1.57,.001]],"glass");
  m.shard([[.08,1.26,0],[1.1,1.26,0],[1.1,2.2,0],[.89,2.2,0],[.68,1.88,0],[.47,2.1,0]],"glass");
  for(let x of [-1.14,0,1.14])for(let y of [.07,1.11,2.28]){m.sphere([x,y,-.085],.027,"bolt",7,4)}
  for(let i=0;i<30;i++){let x=(m.rnd()-.5)*2.2,y=.17+m.rnd()*2.0;if(m.rnd()>.55)m.box([x,y,-.08],[.028,.015,.01],"oxidized")}
  return m
 }
 function picnic(){
  let m=new Mesh(911);
  const board=(cx,cy,cz,s)=>{m.box([cx,cy,cz],s,m.rnd()>.32?"old_wood":"rotten_wood");m.rod([cx-s[0]*.43,cy+s[1]*.51,cz+s[2]*.10],[cx+s[0]*.45,cy+s[1]*.51,cz+s[2]*.1],.005,"wood",5)};
  for(let z of [-.24,0,.24])board(0,.86,z,[2.45,.08,.21]);
  for(let z of [-.86,.86])for(let x of [-.38,.38])board(x,.45,z,[1.18,.075,.21]);
  for(let x of [-.85,.85])for(let z of [-.2,.2]){m.rod([x-.12,.06,z*3],[x,.8,z],.043,"old_wood");m.rod([x+.1,.06,z*3],[x,.8,z],.043,"old_wood")}
  for(let z of [-.8,.8])for(let x of [-.82,.82])m.rod([x,.08,z],[x,.52,z],.04,"rotten_wood");
  for(let x of [-.79,.79])m.rod([x,.46,-.9],[x,.48,.9],.05,"wood");
  m.box([1.11,.89,.23],[.17,.025,.08],"rotten_wood");
  for(let i=0;i<60;i++){let x=(m.rnd()-.5)*2.35,z=(m.rnd()-.5)*.60;m.box([x,.903,z],[.008+.035*m.rnd(),.004,.008+.08*m.rnd()],"rotten_wood")}
  return m
 }
 function footbridge(){
  let m=new Mesh(1011);
  for(let z of [-.69,.69])m.rod([-1.86,.22,z],[1.88,.17,z],.075,"rotten_wood",8);
  for(let i=0;i<14;i++){if(i===5||i===10)continue;let x=-1.7+i*.255,y=.23+.023*Math.sin(i*.58);
    m.box([x,y,0],[.226,.062,1.46],i%5===0?"rotten_wood":"old_wood",.009*Math.sin(i));
    for(let z of [-.53,.53])m.rod([x,y+.032,z],[x,y+.041,z],.011,"oxidized",6)}
  for(let x of [-1.55,-.12,1.47]){m.rod([x,.16,-.75],[x,1.09,-.75],.051,"old_wood");m.rod([x,.16,.75],[x,x===-.12?.37:.92,.75],.046,"rotten_wood")}
  m.rod([-1.55,1.07,-.75],[-.11,1.01,-.75],.038,"old_wood");
  m.rod([.18,.72,-.75],[1.47,.98,-.75],.032,"rotten_wood");
  for(let i=0;i<16;i++){let x=-1.70+m.rnd()*3.4,z=-.58+m.rnd()*1.2;m.sphere([x,.26,z],.025+m.rnd()*.038,i%2?"moss":"dead_leaves",7,4)}
  m.box([-.18,.22,.58],[.25,.056,.24],"rotten_wood",.21);return m
 }
 function memorial(){
  let m=new Mesh(1111);
  m.box([0,.17,0],[.76,.30,.42],"stone");
  m.rod([0,.11,0],[0,1.57,0],.051,"old_wood",8);
  m.box([0,1.13,0],[.78,.115,.08],"old_wood",.05);
  m.box([0,.72,-.07],[.5,.29,.025],"chipped_paint");
  m.box([0,.72,-.085],[.43,.22,.012],"paper");
  for(let i=0;i<3;i++)m.box([-.14,.73+i*.048,-.095],[.20,.007,.004],"charcoal");
  for(let j=0;j<7;j++){let x=(m.rnd()-.5)*.98,z=(m.rnd()-.5)*.52;m.sphere([x,.07,z],.06+m.rnd()*.055,"stone",7,5)}
  let origins=[[-.36,.22,-.25],[-.27,.18,-.23],[.19,.22,-.3],[.4,.14,-.22]];
  for(let i=0;i<origins.length;i++){let a=origins[i],b=[a[0]+(m.rnd()-.5)*.35,.39+m.rnd()*.25,a[2]-.05];m.rod(a,b,.008,"old_wood",6);m.sphere(b,.043,i%2?"faded_red":"dead_leaves",8,5)}
  for(let x of [-.24,.33]){m.cylinder([x,.13,-.4],.045,.17,"porcelain",9);m.cylinder([x,.23,-.4],.018,.028,"charcoal",7)}
  m.ribbon([[.03,1.14,-.07],[.15,1.02,-.10],[.11,.79,-.1]],.043,"red_fabric");return m
 }
 function culvert(){
  let m=new Mesh(1211),R=.89,r=.64,C=1.03,L=2.12,N=28,M=10;
  let ring=(j,k,R0,z)=>[R0*Math.cos(j*2*Math.PI/N),C+R0*Math.sin(j*2*Math.PI/N),z];
  for(let i=0;i<M;i++){let z=-L/2+i*L/M,zz=-L/2+(i+1)*L/M;for(let j=0;j<N;j++){let jj=(j+1)%N,offset=.023*Math.sin(i*.72+j*.71),r0=R+offset,rr=R+.02*Math.sin(i*.72+j*.71+1);
   m.quad(ring(j,i,r0,z),ring(jj,i,r0,z),ring(jj,i,rr,zz),ring(j,i,rr,zz),(i+j)%17===0?"moss":i%8===0?"oxidized":"concrete");
   m.quad(ring(j,i,r,z),ring(j,i,r,zz),ring(jj,i,r,zz),ring(jj,i,r,z),"dark_oxidized")}
  }
  for(let j=0;j<N;j++){let jj=(j+1)%N;for(let z of [-L/2,L/2])m.quad(ring(j,0,r,z),ring(jj,0,r,z),ring(jj,0,R,z),ring(j,0,R,z),(j+3)%11===0?"moss":"concrete")}
  for(let i=0;i<8;i++){let t=.4+i*.28,th=2.0+.2*Math.sin(i),x=.92*Math.cos(th),y=C+.92*Math.sin(th),z=-.88+i*.21;m.sphere([x,y,z],.05+i%3*.016,i%3?"concrete":"moss",7,5)}
  m.line([[.88,1.0,-1.065],[.85,1.23,-.95],[.76,1.41,-.72],[.72,1.57,-.55],[.58,1.72,-.37]],.012,"soot");
  for(let i=0;i<7;i++){let x=(m.rnd()-.5)*1.6,z=1.07+m.rnd()*.25;m.sphere([x,.06,z],.07+m.rnd()*.08,i%3?"stone":"moss",7,4)}
  return m
 }
 props.rusted_mailbox=mailbox();
 props.sagging_porch_chair=chair();
 props.cracked_plant_pots=pots();
 props.torn_clothesline=laundry();
 props.crushed_ventilation_duct=duct();
 props.collapsed_cable_tray=cableTray();
 props.corroded_sheet_metal_stack=scrap();
 props.broken_factory_window=windowFrame();
 props.rotting_picnic_table=picnic();
 props.damaged_footbridge_fragment=footbridge();
 props.roadside_memorial=memorial();
 props.broken_drainage_culvert=culvert();
 return props;
};
const models = generateAll();
const root = path.resolve(__dirname, '..', 'models');
fs.mkdirSync(root, {recursive:true});
for (const [name, model] of Object.entries(models)) {
 const bytes = model.toGLB();
 fs.writeFileSync(path.join(root, name + '.glb'), Buffer.from(bytes));
 console.log(name, bytes.length, 'bytes', model.faces, 'triangles');
}
