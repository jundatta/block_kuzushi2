precision highp float;

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;

float t;

  vec3 hash33(vec3 p){ 
    float n = sin(dot(p, vec3(7, 157, 113)));    
    return fract(vec3(2097152, 262144, 32768)*n); 
  }

  mat2 rot2( float a ){ vec2 v = sin(vec2(1.570796, 0) + a);	return mat2(v, -v.y, v.x); }

  // otaviogood's noise from https://www.shadertoy.com/view/ld2SzK
  const float nudge = 0.739513;	// size of perpendicular vector
  float normalizer = 1.0 / sqrt(1.0 + nudge*nudge);	// pythagorean theorem on that perpendicular to maintain scale
  float SpiralNoiseC(vec3 p)
  {
      float n = 0.0;	// noise amount
      float iter = 1.0;
      for (int i = 0; i < 8; i++)
      {
          // add sin and cos scaled inverse with the frequency
          n += -abs(sin(p.y*iter) + cos(p.x*iter)) / iter;	// abs for a ridged look
          // rotate by adding perpendicular and scaling down
          p.xy += vec2(p.y, -p.x) * nudge;
          p.xy *= normalizer;
          // rotate on other axis
          p.xz += vec2(p.z, -p.x) * nudge;
          p.xz *= normalizer;
          // increase the frequency
          iter *= 1.733733;
      }
      return n;
  }
  
  // Simple rotation quaternion with an axis input
  mat4 rotationMatrix(vec3 axis, float angle)
  {
      axis = normalize(axis);
      float s = sin(angle);
      float c = cos(angle);
      float oc = 1.0 - c;

      return mat4(oc * axis.x * axis.x + c,           oc * axis.x * axis.y - axis.z * s,  oc * axis.z * axis.x + axis.y * s,  0.0,
                  oc * axis.x * axis.y + axis.z * s,  oc * axis.y * axis.y + c,           oc * axis.y * axis.z - axis.x * s,  0.0,
                  oc * axis.z * axis.x - axis.y * s,  oc * axis.y * axis.z + axis.x * s,  oc * axis.z * axis.z + c,           0.0,
                  0.0,                                0.0,                                0.0,                                1.0);
  }
  
  float world(vec3 p, vec3 lookAt) {
    
    p = (vec4(p, 1.) * rotationMatrix(vec3(.1, 0., 0.), time * .1)).xyz;
    
    float l = length(p);
    vec3 spherical = vec3((l - t * .5) * 8., atan(p.y, p.x), acos(p.z / l) * 2.);
    spherical.yz = sin(spherical.yz);
    l = length(lookAt - p);
    
    vec3 _p = spherical * vec3(1., 8., 8.);
    float _sp = 0.;
    // Layering some spiral noises
    _sp = _sp - SpiralNoiseC(_p.xyz) + SpiralNoiseC(_p.zxy*0.5+100.0)*5.0;
    _sp *= .2;
    _sp -= .2;
    
    l = l * .1;
    l = clamp(l, 0., 1.);
    
    return abs(_sp) * l;
    
    
  }

  void main() {
      t = time;
      
      // Setting up our screen coordinates.
      vec2 aspect = vec2(resolution.x/resolution.y, 1.0); //
      vec2 uv = (2.0*gl_FragCoord.xy/resolution.xy - 1.0)*aspect;
    // vec3 rd = normalize(vec3(gl_FragCoord.xy - u_resolution.xy*.5, u_resolution.y*.5)); 
    
    float modtime = t * 2.;
    vec3 movement = vec3(0.);
    
      // The sin in here is to make it look like a walk.
      vec3 lookAt = vec3(0, 0., 0);  // This is the point you look towards, or at, if you prefer.
      vec3 camera_position = vec3(cos(t) * 8., 0, sin(t) * 4.); // This is the point you look from, or camera you look at the scene through. Whichever way you wish to look at it.
    camera_position = vec3(cos(mouse.x) * 8., sin(mouse.y) * 8., 0);
      
      vec3 forward = normalize(lookAt-camera_position); // Forward vector.
      vec3 right = normalize(vec3(forward.z, 0., -forward.x )); // Right vector... or is it left? Either way, so long as the correct-facing up-vector is produced.
      vec3 up = normalize(cross(forward,right)); // Cross product the two vectors above to get the up vector.

      // FOV - Field of view.
      float FOV = .8;

      // ro - Ray origin.
      vec3 ro = camera_position; 
      // rd - Ray direction.
      vec3 rd = normalize(forward + FOV*uv.x*right + FOV*uv.y*up);
      // rd += hash33(rd)*.002;
      rd.xy = rot2( movement.x * .04 )*rd.xy;

    // Camera
    // vec3 ro = vec3(sin(modtime)*3., 0, u_time*2.);

    vec3 lp = lookAt;

    float local_density = 0.;
    float density = 0.;
    float weighting = 0.;

    float dist = 1.;
    float travelled = 0.;

    const float distanceThreshold = .3;


    // Initializing the scene color to black, and declaring the surface position vector.
    vec3 col = vec3(0);
    vec3 sp;

    vec3 sn = normalize(-rd); // surface normal
    
    // vec3 lookVec = camera_position - lookAt;
    // float l = length(forward.xz)*.5;
    // l = clamp(l, 0., 1.);

    // Raymarching loop.
    for (int i=0; i<64; i++) {

      if((density>1.) || travelled>80.) {
        travelled = 20.;
        break;
      }
      
      float l = 1. / length(lookAt - sp);
      l = clamp(l * l * 2., 0., 1.);

      sp = ro + rd*travelled; // Ray position.
      dist = world(sp, lookAt); // Closest distance to the surface... particle.
      
      if(dist < .1) dist = .15;
      

      local_density = (distanceThreshold - dist)*step(dist, distanceThreshold);
      weighting = (1. - density)*local_density;

      density += (weighting*(1.-distanceThreshold)*1./dist*.1);

      vec3 ld = lp-sp; // Direction vector from the surface to the light position.
      float lDist = max(length(ld), .001); // Distance from the surface to the light.
      ld/=lDist; // Normalizing the directional light vector.

      // Using the light distance to perform some falloff.
      float atten = 1./(1. + lDist*.125 + lDist*lDist*.55);

      col += weighting*atten*1.25 ;
      
      col = mix(
        vec3(0., 0., 0.),
        mix(
          mix(
            vec3(0., 0., 1.),
            vec3(-0.2),
            clamp(weighting*2., 0., 1.)
          ),
          mix(
            vec3(10., 7., -1.),
            vec3(5.),
            clamp(atten * .8, 0., 1.)
          ),
          clamp(atten * .5, 0., 1.)
        ),
        clamp(atten * 3., 0., 1.)
      );
      
      // col += vec3(mix(
      //   vec3(weighting),
      //   vec3(1., 2., 0.),
      //   l * l
      // ));

      travelled += max(dist*.2, .02);
    }
    
    vec3 sunDir = normalize(lp-ro);
    float sunF = 1. - dot(rd,sunDir);

    // gl_FragColor = vec4(sin(col), 1.0);
    gl_FragColor = vec4(col, 1.0);
    // gl_FragColor = vec4(density);
  }
