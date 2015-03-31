Shader "Custom/Mandelbrot" {
Properties {
}
SubShader {
Pass{
	CGPROGRAM
	#include "UnityCG.cginc"
	#pragma target 4.0
	#pragma vertex vert_img
	#pragma fragment mandelbrot	
	#define black float4(0,0,0,1)
	#define green float4(0,1,0,1)	
	#define white float4(1,1,1,1)
	#define blue  float4(0,0,0.7,1)		
	#define red float4(1,0,0,1)	
	#define orange float4(1, 0.64, 0,1)
	#define yellow  float4(1,1,0,1)	

	sampler2D _MainTex;

	float	_ZoomLevel;
	float2	_ScreenRes;
	float2	_Center;
	float2	_ViewSize;
	int		_NumIterations;
	int		_Exponent;

	float2 
	complex_mult(float2 c1, float2 c2)
	{
		return float2(c1.x * c2.x - c1.y * c2.y, c1.x * c2.y + c1.y * c2.x);
	}

	float2 
	recurse_complex_mult(float2 cin, int n)
	{
		int ii;
		float2 cout = cin;

		for(ii = 0; ii < n; ii++)
		{
			cout = complex_mult(cout, cin);
		}

		return cout;
	}

	bool
	check_convergence(float2 c, out float divergeIter)
	{
		int ii;
		float2 fz = 0;
		const float delta = 2;	
		bool converges = true;
		divergeIter = 0;

		for(ii = 0; ii < _NumIterations; ii++)
		{			
			// equation used is: f(z) = z^2 + c
			fz = recurse_complex_mult(fz, _Exponent) + c;

			if (dot(fz,fz) > 4) {
				divergeIter = ii;
				converges = false;
				break;
			}
		}

		return converges;
	}


	float4
	get_divergence_color(float divergeIter)
	{
		if (divergeIter < _NumIterations/float(5))
			return blue; // diverges very quickly
		//else 
		//	return float4(float3(1,1,1) * divergeIter/(float)_NumIterations, 1);

		else if (divergeIter < _NumIterations/float(4))
			return yellow; 
		else if (divergeIter < _NumIterations/float(3))
			return orange;
		else
			return red;
				
	}

	float4 
	mandelbrot(v2f_img i) : COLOR
	{
		// get pixel coordinate in [-1, 1] normalized space
		float2 pixelNormPos = (2 * i.pos.xy) / _ScreenRes  -  1;
		
		// get position of current pixel in the complex plane
		float2  complexPlanePos = _Center + ( pixelNormPos * _ViewSize * 0.5);

		float divergeIter;
		bool converges = check_convergence(complexPlanePos, divergeIter);

		if (converges)
			return black;
		else
			return get_divergence_color(divergeIter);

	}
	ENDCG
} // Pass

} // Subshader
	FallBack "Diffuse"
}
