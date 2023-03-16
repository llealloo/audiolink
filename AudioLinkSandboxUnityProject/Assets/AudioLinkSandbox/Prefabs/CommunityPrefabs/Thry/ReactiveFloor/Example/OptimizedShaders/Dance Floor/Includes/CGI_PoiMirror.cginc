#ifndef POI_MIRROR
    #define POI_MIRROR
    float _Mirror;
    float _EnableMirrorTexture;
    POI_TEXTURE_NOSAMPLER(_MirrorTexture);
    void applyMirrorRenderVert(inout float4 vertex)
    {
        
        if (float(0) != 0)
        {
            bool inMirror = IsInMirror();
            if(float(0) == 1 && inMirror)
            {
                return;
            }
            if(float(0) == 1 && !inMirror)
            {
                vertex = -1;
                return;
            }
            if(float(0) == 2 && inMirror)
            {
                vertex = -1;
                return;
            }
            if(float(0) == 2 && !inMirror)
            {
                return;
            }
        }
    }
    void applyMirrorRenderFrag()
    {
        
        if(float(0) != 0)
        {
            bool inMirror = IsInMirror();
            if(float(0) == 1 && inMirror)
            {
                return;
            }
            if(float(0) == 1 && !inMirror)
            {
                clip(-1);
                return;
            }
            if(float(0) == 2 && inMirror)
            {
                clip(-1);
                return;
            }
            if(float(0) == 2 && !inMirror)
            {
                return;
            }
        }
    }
    #if(defined(FORWARD_BASE_PASS) || defined(FORWARD_ADD_PASS))
        void applyMirrorTexture(inout float4 mainTexture)
        {
            
            if(float(0))
            {
                if(IsInMirror())
                {
                    mainTexture = POI2D_SAMPLER_PAN(_MirrorTexture, _MainTex, poiMesh.uv[float(0)], float4(0,0,0,0));
                }
            }
        }
    #endif
#endif
