shader_type spatial;
render_mode diffuse_burley;

varying vec3 rock_position;
varying vec3 rock_normal;

float hash3(vec3 p){
 p=fract(p*0.1031); p+=dot(p,p.yzx+33.33);
 return fract((p.x+p.y)*p.z);
}
float noise3(vec3 p){
 vec3 i=floor(p), f=fract(p); f=f*f*(3.0-2.0*f);
 return mix(mix(mix(hash3(i),hash3(i+vec3(1,0,0)),f.x),
 mix(hash3(i+vec3(0,1,0)),hash3(i+vec3(1,1,0)),f.x),f.y),
 mix(mix(hash3(i+vec3(0,0,1)),hash3(i+vec3(1,0,1)),f.x),
 mix(hash3(i+vec3(0,1,1)),hash3(i+vec3(1,1,1)),f.x),f.y),f.z);
}
float fbm(vec3 p){
 float value=0.0; float amplitude=0.5;
 for(int i=0;i<4;i++){value+=noise3(p)*amplitude; p=p*2.07+vec3(7.1,3.4,1.9); amplitude*=0.5;}
 return value;
}
float moss_coverage(vec3 p,vec3 n){
 float islands=fbm(p*5.5+vec3(4.6,0,7.1));
 float slope=smoothstep(-0.15,0.7,n.y);
 float base=smoothstep(0.08,0.3,p.y);
 return smoothstep(0.53,0.69,islands+slope*0.22)*base;
}
void vertex(){
 rock_position=VERTEX;
 rock_normal=NORMAL;
 VERTEX+=NORMAL*moss_coverage(VERTEX,NORMAL)*0.008;
}
void fragment(){
 vec3 p=rock_position;
 vec3 n=normalize(rock_normal);
 float broad=fbm(p*8.0);
 float grit=noise3(p*320.0);
 float minerals=noise3(p*135.0+vec3(3.5));
 float fissure=smoothstep(0.025,0.15,abs(fbm(p*9.0)-0.42));
 vec3 granite=mix(vec3(0.075,0.082,0.083),vec3(0.24,0.255,0.25),broad);
 granite+=smoothstep(0.74,0.93,minerals)*0.14;
 granite-=smoothstep(0.64,0.86,grit)*0.045;
 granite*=mix(0.8,1.0,fissure);
 float moss=moss_coverage(p,n);
 float fibres=fbm(p*110.0);
 vec3 moss_color=mix(vec3(0.018,0.038,0.01),vec3(0.08,0.145,0.025),fibres);
 moss_color*=mix(0.7,1.1,noise3(p*28.0));
 float damp=mix(0.6,1.0,smoothstep(0.02,0.25,p.y));
 ALBEDO=mix(granite,moss_color,moss)*damp;
 ROUGHNESS=mix(0.8,0.98,moss);
 SPECULAR=0.22;
 // Derivative-based surface relief works continuously across UV seams.
 float height=mix(grit*0.0013+fissure*0.001,fibres*0.006,moss);
 vec3 dx=dFdx(VERTEX),dy=dFdy(VERTEX);
 vec3 r1=cross(dy,NORMAL),r2=cross(NORMAL,dx);
 float det=dot(dx,r1);
 vec3 gradient=sign(det)*(dFdx(height)*r1+dFdy(height)*r2);
 NORMAL=normalize(abs(det)*NORMAL-gradient);
}
