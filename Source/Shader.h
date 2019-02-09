#pragma once

#ifdef __METAL_VERSION__
#define NS_ENUM(_type, _name) enum _name : _type _name; enum _name : _type
#define NSInteger metal::int32_t
#else
#import <Foundation/Foundation.h>
#endif

#include <simd/simd.h>

enum {
    EQU_MANDELBULB, EQU_APOLLONIAN, EQU_APOLLONIAN2, EQU_KLEINIAN, EQU_MANDELBOX,
    EQU_QUATJULIA, EQU_MONSTER, EQU_KALI_TOWER, EQU_POLY_MENGER, EQU_GOLD,
    EQU_SPIDER, EQU_KLEINIAN2, EQU_KIFS, EQU_IFS_TETRA, EQU_IFS_OCTA,
    EQU_IFS_DODEC, EQU_IFS_MENGER, EQU_SIERPINSKI, EQU_HALF_TETRA, EQU_FULL_TETRA,
    EQU_CUBIC, EQU_HALF_OCTA, EQU_FULL_OCTA, EQU_KALEIDO, EQU_POLYCHORA,
    EQU_QUADRAY, EQU_FRAGM, EQU_QUATJULIA2, EQU_MBROT, EQU_KALIBOX,
    EQU_SPUDS, EQU_MPOLY, EQU_MHELIX, EQU_FLOWER, EQU_JUNGLE, EQU_PRISONER,
    EQU_MAX
};

struct Control {
    int xSize,ySize;
    int equation;

    vector_float3 camera;
    vector_float3 viewVector,topVector,sideVector;
    vector_float3 light,nlight;
    float contrast;
    float specular;

    float cx,cy,cz,cw;
    float dx,dy,dz,dw;
    float ex,ey,ez,ew;

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
    float sph1,sph2,sph3;
    float box1,box2;
    float scaleFactor;
    vector_float3 julia;
    bool juliaboxMode;
    
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
};
