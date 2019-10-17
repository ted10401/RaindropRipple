// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

Shader "Unlit/RaindropRipple"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
		_BumpTex ("Normal Map", 2D) = "bump" {}
		_Specular ("Specular", Range(1.0, 500.0)) = 250.0
        _Gloss ("Gloss", Range(0.0, 1.0)) = 0.2

		_Columns ("Columns", Int) = 5
		_Rows ("Rows", Int) = 3
		_Frame ("Per Frame Length", Float) = 0.5
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "AutoLight.cginc"

            struct a2v
            {
                float4 vertex : POSITION;
                float2 texcoord : TEXCOORD0;
				fixed3 normal : NORMAL;
				fixed4 tangent : TANGENT;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
				float2 texcoord : TEXCOORD0;
				float2 texcoord_bump : TEXCOORD1;
				fixed3 lightDir: TEXCOORD2;
				fixed4 TtoW0 : TEXCOORD3;
  				fixed4 TtoW1 : TEXCOORD4;
  				fixed4 TtoW2 : TEXCOORD5;
				LIGHTING_COORDS(6, 7)
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
			sampler2D _BumpTex;
			float4 _BumpTex_ST;
			float _Specular;
			float _Gloss;
			uint _Columns;
			uint _Rows;
			float _Frame;

            v2f vert (a2v v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.texcoord = TRANSFORM_TEX(v.texcoord, _MainTex);
				o.texcoord_bump = TRANSFORM_TEX(v.texcoord, _BumpTex);

				TANGENT_SPACE_ROTATION;
				o.lightDir = mul(rotation, ObjSpaceLightDir(v.vertex));
				
				float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
			  	fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);
			  	fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
			  	fixed3 worldBinormal = cross(worldNormal, worldTangent) * v.tangent.w;

			  	o.TtoW0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);
			  	o.TtoW1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);
			  	o.TtoW2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);
  
				float3x3 WtoT = mul(rotation, (float3x3)unity_WorldToObject);
				o.TtoW0 = float4(WtoT[0].xyz, worldPos.x);
				o.TtoW1 = float4(WtoT[1].xyz, worldPos.y);
				o.TtoW2 = float4(WtoT[2].xyz, worldPos.z);
  				TRANSFER_VERTEX_TO_FRAGMENT(o);

                return o;
            }

			fixed4 textureSheet(sampler2D tex, float2 texcoord, float dx, float dy, int frame)
			{
				return tex2D(tex, float2(
										(texcoord.x * dx) + fmod(frame, _Columns) * dx,
										1.0 - ((texcoord.y * dy) + (frame / _Columns) * dy)
										));
			}

            fixed4 frag (v2f i) : SV_Target
            {
				fixed4 mainColor = tex2D(_MainTex, i.texcoord);

				int frames = _Columns * _Rows;
				float frame = fmod(_Time.y / _Frame, frames);
				int curFrame = floor(frame);
				float dx = 1.0 / _Columns;
				float dy = 1.0 / _Rows;
                fixed3 norm = UnpackNormal(textureSheet(_BumpTex, i.texcoord_bump, dx, dy, curFrame));
				float3 worldPos = float3(i.TtoW0.w, i.TtoW1.w, i.TtoW2.w);
				fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));
				fixed3 lightDir = normalize(UnityWorldSpaceLightDir(worldPos));
				// Case 1
				half3 worldNormal = normalize(half3(dot(i.TtoW0.xyz, norm), dot(i.TtoW1.xyz, norm), dot(i.TtoW2.xyz, norm)));
				// Case 2
				worldNormal = normalize(mul(norm, float3x3(i.TtoW0.xyz, i.TtoW1.xyz, i.TtoW2.xyz)));

				fixed atten = LIGHT_ATTENUATION(i);
				
				fixed3 ambi = UNITY_LIGHTMODEL_AMBIENT.xyz;
				
				fixed3 diff = _LightColor0.rgb * saturate (dot (normalize(worldNormal),  normalize(lightDir)));
								
				fixed3 lightRefl = reflect(-lightDir, worldNormal);
				fixed3 spec = _LightColor0.rgb * pow(saturate(dot(normalize(lightRefl), normalize(worldViewDir))), _Specular) * _Gloss;
				
				fixed3 worldView = fixed3(i.TtoW0.w, i.TtoW1.w, i.TtoW2.w);
				fixed3 worldRefl = reflect (-worldViewDir, worldNormal);
				
				fixed4 fragColor;
				fragColor.rgb = float3((ambi + (diff + spec) * atten) * mainColor);
				fragColor.a = 1.0;
				return fragColor;
            }
            ENDCG
        }
    }
}
