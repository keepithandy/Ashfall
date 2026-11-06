shader_type spatial;
varying vec3 local_position;
float hash(vec3 p){p=fract(p*0.1031);p+=dot(p,p.yzx+33.33);return fract((p.x+p.y)*p.z);}
float noise(vec3 p){vec3 i=floor(p),f=fract(p);f=f*f*(3.0-2.0*f);
return mix(mix(mix(hash(i),hash(i+vec3(1,0,0)),f.x),mix(hash(i+vec3(0,1,0)),hash(i+vec3(1,1,0)),f.x),f.y),mix(mix(hash(i+vec3(0,0,1)),hash(i+vec3(1,0,1)),f.x),mix(hash(i+vec3(0,1,1)),hash(i+vec3(1,1,1)),f.x),f.y),f.z);}
void vertex(){local_position=VERTEX;}
void fragment(){
vec3 p=local_position;
float fine=noise(p*350.0);
float scuff=noise(p*48.0);
float dirt=noise(p*22.0)*(1.0-smoothstep(0.02,0.33,p.y));
vec3 charcoal=mix(vec3(0.012,0.014,0.016),vec3(0.04,0.043,0.045),scuff);
ALBEDO=charcoal+vec3(0.055,0.043,0.026)*dirt;
ROUGHNESS=0.8+fine*0.16;
SPECULAR=0.28;
float height=fine*0.00025+scuff*0.0004;
vec3 dx=dFdx(VERTEX),dy=dFdy(VERTEX),r1=cross(dy,NORMAL),r2=cross(NORMAL,dx);
float det=dot(dx,r1);
NORMAL=normalize(abs(det)*NORMAL-sign(det)*(dFdx(height)*r1+dFdy(height)*r2));
}
