//This code copyright of Peter Sarkozy aka Beherith. Contact mysterme@gmail.com for licensing.
//License is CC-BY-ND 3.0

  uniform float inverseRX;
  uniform float inverseRY;
  uniform sampler2D tex0;
  uniform vec3 eyePos;
  uniform vec4 lightpos;
  #ifdef BAR_LIGHT
	uniform vec4 lightpos2;
  #endif
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
	#ifndef BAR_LIGHT
	//gl_FragColor=vec4(1,0,0,0.5);
	//return;
		float dist_light_here = length(lightpos.xyz - here4.xyz);
		float cosphi = max(0.0 , dot (herenormal4.xyz, lightpos.xyz - here4.xyz) / dist_light_here);
		//float attentuation =  max(0, ( 1.0 - (dist_light_here)/(lightpos.w)) ); // pretty good function, but its peak is too sharp, especially for lasers. https://www.desmos.com/calculator/vyc3ulbzj6
		//float attentuation =  max( 0,( 1.0 - (dist_light_here*dist_light_here)/(lightpos.w*lightpos.w)) );
		float attentuation =  max( 0,( lightparams.r - lightparams.g * (dist_light_here*dist_light_here)/(lightpos.w*lightpos.w) - lightparams.b*(dist_light_here)/(lightpos.w)) );
	#endif
	#ifdef BAR_LIGHT
	gl_FragColor=vec4(1,0,1,0.5);
	return;
		//def dist(x1,y1, x2,y2, x3,y3): # x3,y3 is the point
		/*distance( Point P,  Segment P0:P1 ) // http://geomalgorithms.com/a02-_lines.html
		{
			   v = P1 - P0
			   w = P - P0

			   if ( (c1 = w dot v) <= 0 )  // before P0
					   return d(P, P0)
			   if ( (c2 = v dot v) <= c1 ) // after P1
					   return d(P, P1)

			   b = c1 / c2
			   Pb = P0 + bv
			   return d(P, Pb)
		}
		*/

		vec3 v=lightpos2.xyz-lightpos.xyz;
		vec3 w=here4.xyz-lightpos.xyz;
		float c1=dot(v,w);
		float c2=dot(v,v);
		if (c1<=0.0){
			v=here4.xyz;
			w=lightpos.xyz;
		}else if (c2<c1){
			v=here4.xyz;
			w=lightpos2.xyz;
		}else{
			w=lightpos.xyz+(c1/c2)*v;
			v=here4.xyz;
		}
		float dist_light_here = length(v-w);
		float cosphi = max(0.0 , dot (herenormal4.xyz, w.xyz - here4.xyz) / dist_light_here);
		float attentuation =  max( 0,( lightparams.r - lightparams.g * (dist_light_here*dist_light_here)/(lightpos.w*lightpos.w) - lightparams.b*(dist_light_here)/(lightpos.w)) );
	#endif

	
	//lightparams info:
	// linear funcion is (1,0,1)
	//quadratic function is (1,1,0)
	// tits function (for lasers, to avoid hotspotting) (0.5, 2, -1.5)
	attentuation *=attentuation;
	
	//TODO:
	//add a specular highlight to the lighting with eyepos
	
	//gl_FragColor=vec4(normalize(herenormal4.xyz), cosphi*(lightpos.w/(dist_light_here*dist_light_here)));
	//if (attentuation > 0.001) gl_FragColor(1,0,0,1);
	//else gl_FragColor(0,1,0,1);
	// gl_FragColor=vec4(1,1,0,0.5);
	// return;
	gl_FragColor=vec4(lightcolor.rgb, cosphi*attentuation);
	return;
  }
  