#ifndef POI_DEFINES
    #define POI_DEFINES
    #define DielectricSpec float4(0.04, 0.04, 0.04, 1.0 - 0.04)
    #ifdef VIGNETTE_MASKED // Lighting
        #ifndef POI_VAR_DOTNL
            #define POI_VAR_DOTNL
        #endif
    #endif
#endif
