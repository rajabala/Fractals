Shader "Custom/Mandelbulb" {
Properties {
}
SubShader {
Pass{
	Blend One OneMinusSrcAlpha, One One
	BlendOp Add
	CGPROGRAM
	#include "UnityCG.cginc"
	#pragma target 4.0
	#pragma vertex vert_img
	#pragma fragment frag
		
	#define black float4(0,0,0,1)
	#define green float4(0,1,0,1)	
	#define white float4(1,1,1,1)
	#define blue  float4(0,0,0.7,1)		
	#define red float4(1,0,0,1)	
	#define orange float4(1, 0.64, 0,1)
	#define yellow  float4(1,1,0,1)	
	#define seethrough float4(0,0,0,0)

	sampler2D _MainTex;

	// built-in Unity shader variables (http://docs.unity3d.com/462/Documentation/Manual/SL-BuiltinValues.html)
	// these don't need to be declared. listing what's used in the shader for readability
	//float		_WorldSpaceCameraPos;
	//float4	_ScreenParams;

	// shader variables set by Unity if declared
	float4x4	_CameraToWorld;

	// uniforms set in script
	//float4x4	_CameraToWorldMatrix;
	float3		_LightDir;
	float		_Exponent;
	int			_NumIterations;
	int			_NumRayMarchSteps;
	float		_Fov;

	/********* math stuff ******************/
	inline float2 
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


	// theta -- angle vector makes with the XY plane
	// psi -- angle the projected vector on the XY plane makes with the X axis
	// note: this might not be the usual convention
	inline void 
	cartesian_to_polar(float3 p, out float r, out float theta, out float psi)
	{
		r = length(p);
		float r1 = p.x*p.x + p.y*p.y;
		theta = atan(p.z / r1); // angle vector makes with the XY plane
		psi	= atan(p.y / p.x); // angle of xy-projected vector with X axis
	}


	// theta -- angle vector makes with the XY plane
	// psi -- angle the projected vector on the XY plane makes with the X axis
	// note: this might not be the usual convention	
	inline void
	polar_to_cartesian(float r, float theta, float psi, out float3 p)
	{
		p.x = r * cos(theta) * cos(psi);
		p.y = r * cos(theta) * sin(psi);
		p.z = r * sin(theta);
	}


	// [-1,1] to [0,1]
	float
	norm_to_unorm(float i)
	{
		return (i + 1) * 0.5;
	}

	

	/*************************************** distance estimators ******************************/
	// distance to the surface of a sphere
	float
	de_sphere_surface(float3 p, float3 c, float r)
	{
		return abs(length(p - c) - r);
	}


	// instancing can be done really cheap. the function below creates infinite spheres on the XY plane
	float
	de_sphere_instances(float3 p)
	{
		p.xy = fmod( (p.xy), 1.0 ) - 0.5;
		return length(p) - 0.2;
	}

	// distance estimator for the mandelbulb	
	float
	de_mandelbulb(float3 c)
	{		
		// i believe that similar to the mandelbrot, the mandelbulb is enclosed in a sphere of radius 2 (hence the delta) 
		const float delta = 2;	
		
		bool converges = true; // unused
		float divergenceIter = 0; // unused
		float3 p = c;
		float dr = 2.0, r = 1.0;

		int ii;
		for(ii = 0; ii < _NumIterations; ii++)
		{			
			// equation used: f(p) = p^_Exponent + c starting with p = 0			

			// get polar coordinates of p
			float theta, psi;
			cartesian_to_polar(p, r, theta, psi);

			// rate of change of points in the set
			dr = _Exponent * pow(r, _Exponent - 1) *dr + 1.0;

			// find p ^ _Exponent
			r = pow(r,_Exponent);
			theta *= _Exponent;
			psi *= _Exponent;

			// convert to cartesian coordinates
			polar_to_cartesian(r, theta, psi, p);
			
			// add c
			p += c;

			// check for divergence
			if (length(p) > delta) {
				divergenceIter = ii;
				converges = false;
				break;
			}
		}

		return log(r) * r / dr; // Greens formula
	}

	// iterate through scene objects to find min distance from a point to the scene
	float 
	de_scene(float3 p)
	{
		//float ds1 = de_sphere_surface(p, float3(6,0,0), 0.9);
		//return ds1;
		
		float ds2 = de_mandelbulb(p);		
		return ds2;//min(ds1, ds2);
	}


	// Raymarch scene given an origin and direction using sphere tracing
	// Each step, we move by the closest distance to any object in the scene from the current ray point.
	// We stop when we're really close to an object (or) if we've exceeded the number of steps
	// Returns a greyscale color based on number of steps marched (white --> less, black --> more)
	float4
	raymarch(float3 rayo, float3 rayd) 
	{			
		const float minimumDistance = 0.0001;
		float3 p = rayo;
		bool hit = false;		
		float distanceStepped = 0.0;
		int steps;

		for(steps = 0; steps < _NumRayMarchSteps; steps++)
		{			
			float d = de_scene(p);
			distanceStepped += d;

			if (d < minimumDistance) {
				hit = true;
				break;
			}

			p += d * rayd;
		}			

		float greyscale = 1 - (steps/(float)_NumRayMarchSteps);
		return float4(greyscale, greyscale, greyscale, 1);			
	}

	// Find ray direction through the current pixel in camera space (LHS, camera looks down +Z)
	float3
	get_eye_ray_through_pixel(float2 svpos)
	{
		//// Get the ray direction for the current pixel in LHS (coz Unity uses LHS for all its game objects)		
		// get pixel coordinate in [-1, 1] normalized space
		float2 pixelNormPos = -1 + (2 * svpos.xy) / _ScreenParams;
		
		// account for aspect ratio
		pixelNormPos.x *= _ScreenParams.x / _ScreenParams.y;
		
		// DX has its origin at the top left, meaning Y goes downwards. Switch to Y upwards.
		pixelNormPos.y *= -1; 

		// get zNear in normalized coordinates using the vertical field of view
		// the camera looks down +Z, so it needs to be +ive
		float zNearNorm = rcp( tan(_Fov/2) ); // tan(fov/2) = 1 / zn_norm

		return normalize(float3(pixelNormPos, zNearNorm)); // LHS
	}


	float4 
	frag(v2f_img i) : COLOR
	{
		float3 csRay = get_eye_ray_through_pixel(i.pos);		
		//return float4(csRay, 1); // visualize if ray direction was calculated correctly
		
		// The _CameraToWorld matrix we use below is not set in the C# script. 
		// It's one of the built-in variables set by Unity.
		
		// if you choose to pass the camera to world matrix, do NOT use camera.cameraToWorldMatrix
		// that one uses RHS (file:///C:/Program%20Files/Unity/Editor/Data/Documentation/en/ScriptReference/Camera-cameraToWorldMatrix.html)
		// Use camera.transform.localToWorldMatrix instead.		
		float3 wsRay = mul(_CameraToWorld, float4(csRay, 0)); // column-major matrix, so post mult

		return raymarch(_WorldSpaceCameraPos, wsRay);		
	}
	ENDCG
} // Pass

} // Subshader
	FallBack "Diffuse"
}
