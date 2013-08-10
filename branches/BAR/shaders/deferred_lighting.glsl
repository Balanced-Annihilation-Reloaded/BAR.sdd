//This code copyright of Peter Sarkozy aka Beherith. Contact mysterme@gmail.com for licensing.
//It may NOT be distributed outside of the Balanced Annihilation Reloaded game

  uniform float inverseRX;
  uniform float inverseRY;
  uniform sampler2D tex0;
  uniform vec3 eyePos;
  uniform vec4 lightpos;
  uniform vec4 lightcolor;
  uniform vec4 lightparams;
  uniform mat4 viewProjectionInv;
  // uniform mat4 viewProjection;

  void main(void)
  {
    //http://stackoverflow.com/questions/5281261/generating-a-normal-map-from-a-height-map
	vec2 up2	= gl_TexCoord[0].st + vec2(0 , inverseRY);
	vec4 up4	= vec4(vec3(up2.xy, texture2D( tex0,up2 ).x) * 2.0 - 1.0 ,1.0);
	up4 = viewProjectionInv * up4;
	up4.xyz = up4.xyz / up4.w;
	
	vec2 right2	= gl_TexCoord[0].st + vec2(inverseRY , 0);
	vec4 right4	= vec4(vec3(right2.xy, texture2D( tex0,right2 ).x) * 2.0 - 1.0 ,1.0);
	right4 = viewProjectionInv * right4;
	right4.xyz = right4.xyz / right4.w;
	
	vec4 here4	= vec4(vec3(gl_TexCoord[0].st, texture2D( tex0,gl_TexCoord[0].st ).x) * 2.0 - 1.0 ,1.0);
	here4 = viewProjectionInv * here4;
	here4.xyz = here4.xyz / here4.w;
	
	vec4 herenormal4;
	herenormal4.xyz = -1.0*normalize(cross( up4.xyz - here4.xyz, right4.xyz - here4.xyz));
	float dist_light_here = length(lightpos.xyz - here4.xyz);
	float cosphi = max(0.0 , dot (herenormal4.xyz, lightpos.xyz - here4.xyz) / dist_light_here);
	//float attentuation =  max(0, ( 1.0 - (dist_light_here)/(lightpos.w)) ); // pretty good function, but its peak is too sharp, especially for lasers. https://www.desmos.com/calculator/vyc3ulbzj6
	//float attentuation =  max( 0,( 1.0 - (dist_light_here*dist_light_here)/(lightpos.w*lightpos.w)) );
	float attentuation =  max( 0,( lightparams.r - lightparams.g * (dist_light_here*dist_light_here)/(lightpos.w*lightpos.w) - lightparams.b*(dist_light_here)/(lightpos.w)) );
	
	//lightparams info:
	// linear funcion is (1,0,1)
	//quadratic function is (1,1,0)
	// tits function (for lasers, to avoid hotspotting) (0.5, 2, -1.5)
	attentuation *=attentuation;
	
	//gl_FragColor=vec4(normalize(herenormal4.xyz), cosphi*(lightpos.w/(dist_light_here*dist_light_here)));
	//if (attentuation > 0.001) gl_FragColor(1,0,0,1);
	//else gl_FragColor(0,1,0,1);
	gl_FragColor=vec4(lightcolor.rgb, cosphi*attentuation);
	return;
  }
  