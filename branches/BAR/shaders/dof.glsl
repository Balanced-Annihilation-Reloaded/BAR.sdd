uniform sampler2D tex0;
uniform sampler2D tex1;
uniform sampler2D tex2;

uniform float focus;
uniform float focusRange;
uniform float viewX;
uniform float viewY;
uniform float quality;
uniform float intensity;
uniform float focusCurveExp;
uniform float focusRangeMultiplier;
uniform float focusPtX;
uniform float focusPtY;

void main(void)
{
	vec2 texCoord = vec2(gl_TextureMatrix[0] * gl_TexCoord[0]);
	gl_FragColor = vec4(0.0,0.0,0.0,1.0);

	float focus = texture2D(tex2, vec2(focusPtX,focusPtY)).z;

	int k,l;
	float zValue = texture2D(tex2, texCoord).z;
	float dmix = clamp(abs(focus-zValue)*focusRange*focusRangeMultiplier ,0.0,1.0);

	if(dmix > 0.05 || focus>zValue)
	{
		zValue = 0;
		for(k = -1; k <= 1; k++){
			for(l = -1; l <= 1; l++){
				zValue += texture2D(tex2, texCoord + vec2(0.005*k,0.005*l)).z/9.;
			}
		}
		dmix = clamp(abs(focus-zValue)*focusRange*focusRangeMultiplier ,0.0,1.0);
	}
	if(focusCurveExp>1.){
		dmix = (exp(focusCurveExp*dmix)-1.)/exp(focusCurveExp);
	}


	float halfSizeKernel = quality; // quality
	float dy = (8./halfSizeKernel)*dmix/viewY*intensity;
	float dx = (8./halfSizeKernel)*dmix/viewX*intensity;
	float i,j;
	float sumKernel = 0;
	for(j = -halfSizeKernel; j <= halfSizeKernel; j++)
		for(i = -halfSizeKernel; i <= halfSizeKernel; i++){
			sumKernel += (halfSizeKernel+1-abs(i)+halfSizeKernel+1-abs(j))/2.;
		}
	for(j = -halfSizeKernel; j <= halfSizeKernel; j++)
		for(i = -halfSizeKernel; i <= halfSizeKernel; i++){
			gl_FragColor.rgb+= (halfSizeKernel+1-abs(i)+halfSizeKernel+1-abs(j))/(2*sumKernel)*texture2D(tex0, texCoord + vec2(j*dy,i*dx)).rgb;
		}
	//gl_FragColor.rgb = vec3(dmix,dmix,dmix);
}
