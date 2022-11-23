#ifndef POI_PASS
    #define POI_PASS
    #include "UnityCG.cginc"
    #include "Lighting.cginc"
    #include "UnityPBSLighting.cginc"
    #include "AutoLight.cginc"
    #ifdef POI_META_PASS
        #include "UnityMetaPass.cginc"
    #endif
    #include "CGI_PoiMacros.cginc"
    #include "CGI_PoiDefines.cginc"
    #include "CGI_Poicludes.cginc"
    #include "CGI_PoiHelpers.cginc"
    #include "CGI_PoiVertexManipulations.cginc"
    #include "CGI_PoiSpawnInVert.cginc"
    #include "CGI_PoiV2F.cginc"
    #include "CGI_PoiVert.cginc"
    #ifdef TESSELATION
        #include "CGI_PoiTessellation.cginc"
    #endif
    #include "CGI_PoiDithering.cginc"
    #ifdef _PARALLAXMAP
        #include "CGI_PoiParallax.cginc"
    #endif
    #ifdef VIGNETTE
        #include "CGI_PoiRGBMask.cginc"
    #endif
    #include "CGI_PoiData.cginc"
    #include "CGI_PoiSpawnInFrag.cginc"
    #ifdef WIREFRAME
        #include "CGI_PoiWireframe.cginc"
    #endif
    #ifdef FUR
        #include "CGI_PoiFur.cginc"
        #include "CGI_PoiGeomFur.cginc"
    #endif
    #ifdef VIGNETTE_MASKED
        #include "CGI_PoiLighting.cginc"
    #endif
    #include "CGI_PoiMainTex.cginc"
    #ifdef _METALLICGLOSSMAP
        #include "CGI_PoiMetal.cginc"
    #endif
    #include "CGI_PoiBlending.cginc"
    #include "CGI_PoiGrab.cginc"
    #ifdef _SUNDISK_SIMPLE
        #include "CGI_PoiGlitter.cginc"
    #endif
    #ifdef _EMISSION
        #include "CGI_PoiEmission.cginc"
    #endif
    #include "CGI_PoiAlphaToCoverage.cginc"
    #include "CGI_PoiFrag.cginc"
#endif
