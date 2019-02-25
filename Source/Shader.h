#pragma once

#ifdef __METAL_VERSION__
#define NS_ENUM(_type, _name) enum _name : _type _name; enum _name : _type
#define NSInteger metal::int32_t
#else
#import <Foundation/Foundation.h>
#endif

#include <simd/simd.h>

enum {
    EQU_01_MANDELBULB, EQU_02_APOLLONIAN, EQU_03_APOLLONIAN2, EQU_04_KLEINIAN, EQU_05_MANDELBOX,
    EQU_06_QUATJULIA, EQU_07_MONSTER, EQU_08_KALI_TOWER, EQU_09_POLY_MENGER, EQU_10_GOLD,
    EQU_11_SPIDER, EQU_12_KLEINIAN2, EQU_13_KIFS, EQU_14_IFS_TETRA, EQU_15_IFS_OCTA,
    EQU_16_IFS_DODEC, EQU_17_IFS_MENGER, EQU_18_SIERPINSKI, EQU_19_HALF_TETRA, EQU_20_FULL_TETRA,
    EQU_21_CUBIC, EQU_22_HALF_OCTA, EQU_23_FULL_OCTA, EQU_24_KALEIDO, EQU_25_POLYCHORA,
    EQU_26_QUADRAY, EQU_27_FRAGM, EQU_28_QUATJULIA2, EQU_29_MBROT, EQU_30_KALIBOX,
    EQU_31_SPUDS, EQU_32_MPOLY, EQU_33_MHELIX, EQU_34_FLOWER, EQU_35_JUNGLE,
    EQU_36_PRISONER, EQU_37_SPIRALBOX, EQU_38_ALEK_BULB, EQU_39_SURFBOX, EQU_40_TWISTBOX,
    EQU_41_KALI_RONTGEN, EQU_42_VERTEBRAE, EQU_43_DARKSURF, EQU_44_BUFFALO, EQU_45_TEMPLE,
    EQU_46_KALI3,EQU_MAX };

struct Control {
    int version;
    int xSize,ySize;
    int equation;
    int skip;
    
    bool txtOnOff;
    vector_float2 txtSize;
    vector_float3 txtCenter;

    vector_float3 camera;
    vector_float3 viewVector,topVector,sideVector;
    vector_float3 light,nlight;
    float contrast;
    float specular;

    float cx,cy,cz,cw;
    float dx,dy,dz,dw;
    float ex,ey,ez,ew;
    float fx,fy,fz,fw;

    // apollonians
    float multiplier;
    float foam;
    float foam2;
    float bend;
    
    // mandelbulb
    float power;
    
    // kleinian
    int Final_Iterations;
    int Box_Iterations;
    int maxSteps;
    
    float fFinal_Iterations;
    float fBox_Iterations;
    float fMaxSteps;
    bool showBalls;
    bool doInversion;
    bool fourGen;
    
    float Clamp_y;
    float Clamp_DF;
    float box_size_z;
    float box_size_x;
    
    float KleinR;
    float KleinI;
    vector_float3 InvCenter;
    float InvCx,InvCy,InvCz;
    float DeltaAngle;
    float InvRadius;
    
    // mandelbox
    vector_float3 julia;
    bool juliaboxMode;
    float juliaX,juliaY,juliaZ;

    // quaternion julia, monster
    matrix_float4x4 mm;
    
    // menger
    vector_float2 csD,csD2;
    
    // kleinian2
    vector_float4 mins,maxs;
    
    // dodecahedron
    vector_float3 n1,n2,n3;
    float angle1,angle2;
    
    // polychora
    float cVR,sVR,cSR,sSR,cRA,sRA;
    vector_float4 nd,p;
    
    // fragM
    int msIterations,mbIterations;
    float fmsIterations,fmbIterations;
    bool AlternateVersion;
    float msScale;
    vector_float3 msOffset;
    float sc,sr;
    float absScalem1,AbsScaleRaisedTo1mIters;
    float mbMinRad2,mbScale;
    float bright;
    
    // menger poly
    bool polygonate,polyhedronate,TotallyTubular,Sphere,HoleSphere,unSphere,gravity;
    
    // Buffalo
    bool preabsx,preabsy,preabsz,absx,absy,absz,UseDeltaDE;
};
