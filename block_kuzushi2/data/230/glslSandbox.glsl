#ifdef GL_ES
precision mediump float;
#endif

uniform float time;
uniform vec2 resolution;



float hash(float n)
{
	return fract(n*4.6);
}

float noise( in vec3 x )
{
    vec3 p = floor(x);
    vec3 f = fract(x);

    f = f*f*(3.0-2.0*f);
    float n = p.x + p.y*57.0 + 113.0*p.z;
	
	
	
    return mix(mix(mix( hash(n+  0.0), hash(n+  1.0),f.x),
                   mix( hash(n+ 57.0), hash(n+ 58.0),f.x),f.y),
               mix(mix( hash(n+113.0), hash(n+114.0),f.x),
                   mix( hash(n+170.0), hash(n+171.0),f.x),f.y),f.z);
}

vec4 map(in vec3 p)
{
	float d = 0.2 - p.y;
	vec3 q = p - vec3(1.0, 0.1, 0.0)*time;
	float f;
	f = 0.5 * noise(q); q*=2.0;
	f += 0.25 * noise(q); q *= 2.0;
	f += 0.125 * noise(q); q *= 2.0;
	f += 0.0625 * noise(q);
	d += 3.0*f;
	d = clamp(d,0.0, 1.0);
	vec4 res = vec4(d);
	res.xyz = mix(1.15*vec3(1.0, 1.0, 0.8), vec3(0.7,0.7,0.7), res.x);
	return res;
}


vec3 sundir = vec3(-1.0,0.5,1.0);

vec4 raymarch(in vec3 ro, in vec3 rd)
{
	vec4 sum = vec4(0,0,0,0);
	float t = 0.0;
	for (int i=35; i < 64; i++)
	{
		//if (sum.a > 0.99) continue;
		vec3 pos = ro + t*rd;
		vec4 col = map(pos);
		# if 1 
		float dif = clamp((col.w - map(pos+0.3*sundir).w)/0.6, 0.0, 1.0);
		vec3 lin = vec3(0.65,0.68,0.7)*1.35 + 0.45*vec3(0.7, 0.5, 0.3)*dif;
		col.xyz *= lin;
		#endif
		
		col.a *= 0.35;
		col.rgb *= col.a;
		
		sum = sum + col*(1.0 - sum.a);
		
		
		#if 0
		t += 0.1;
		#else
		t += max(0.1, 0.025*t);
		#endif
		
	}
	
	
	sum.xyz /= (0.001 + sum.w);
	return clamp(sum, 0.0, 1.0);
	
}

void main( void ) {
	
	vec2 q = gl_FragCoord.xy / resolution.xy;
	vec2 p = -1.0 + 2.0*q;
	p.x *= resolution.x / resolution.y;
	vec2 mo = -1.0 + 2.0 / resolution.xy;
	
	//camera
	
	vec3 ro = 4.0*normalize(vec3(2.0, 1.0, 2.0));
	vec3 ta = vec3(0.0, 1.0, 2.2);
	vec3 ww = normalize(ta - ro);
	vec3 uu = normalize(cross(vec3(0.0,1.0,0.0), ww));
	vec3 vv = normalize(cross(ww,uu));
				
	vec3 rd = normalize(p.x*uu + p.y*vv + 0.5*ww);
	
	vec4 res = raymarch(ro, rd);
	
	float sun = clamp(dot(sundir, rd), 0.0, 0.0);			
				
	vec3 col = vec3(0.5, 0.71, 0.75) - rd.y*0.2*vec3(1.0,2.5,0.0)+0.15*0.5;
	
	col += 0.2*vec3(0.5,0.71,0.75)*pow(sun,8.0);
	col *= 0.95;
	col = mix(col, res.xyz, res.w);
	
	
	col += 0.1*vec3(1.0, 0.4, 0.2)*pow(sun, 3.0);
	
	gl_FragColor = vec4( col ,1.0);
}