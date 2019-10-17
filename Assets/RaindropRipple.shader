Shader "Unlit/RaindropRipple"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
		_BumpTex ("Normal Map", 2D) = "bump" {}

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

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
			sampler2D _BumpTex;
			uint _Columns;
			uint _Rows;
			float _Frame;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

			fixed4 textureSheet(sampler2D tex, float2 uv, float dx, float dy, int frame)
			{
				return tex2D(tex, float2(
										(uv.x * dx) + fmod(frame, _Columns) * dx,
										1.0 - ((uv.y * dy) + (frame / _Columns) * dy)
										));
			}

            fixed4 frag (v2f i) : SV_Target
            {
				int frames = _Columns * _Rows;
				float frame = fmod(_Time.y / _Frame, frames);
				int curFrame = floor(frame);
				float dx = 1.0 / _Columns;
				float dy = 1.0 / _Rows;

                fixed4 col = textureSheet(_MainTex, i.uv, dx, dy, curFrame);
                return col;
            }
            ENDCG
        }
    }
}
