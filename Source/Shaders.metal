// http://blog.hvidtfeldts.net/index.php/2011/06/distance-estimated-3d-fractals-part-i/
// https://github.com/portsmouth/snelly (under fractals: apollonian_pt.html)
// also visit: http://paulbourke.net/fractals/apollony/
// apollonian: https://www.shadertoy.com/view/4ds3zn
// apollonian2: https://www.shadertoy.com/view/llKXzh
// mandelbulb: https://github.com/jtauber/mandelbulb/blob/master/mandel8.py
// tes1.frag:  http://www.fractalforums.com/3d-fractal-generation/an-escape-tim-algorithm-for-kleinian-group-limit-sets/45/
// monster: https://www.shadertoy.com/view/4sX3R2
// tower: https://www.shadertoy.com/view/MtBGDG
// polyHedral Menger based on : https://www.shadertoy.com/view/MsGcWc
// knighty's kleinian : https://www.shadertoy.com/view/lstyR4
// EvilRyu's KIFS : https://www.shadertoy.com/view/MdlSRM
// IFS Tetrahedron : https://github.com/3Dickulus/FragM/blob/master/Fragmentarium-Source/Examples/Kaleidoscopic%20IFS/Tetrahedron.frag
// IFS Octohedron : https://github.com/3Dickulus/FragM/blob/master/Fragmentarium-Source/Examples/Kaleidoscopic%20IFS/Octahedron.frag
// IFS Dodecahedron : https://github.com/3Dickulus/FragM/blob/master/Fragmentarium-Source/Examples/Kaleidoscopic%20IFS/Dodecahedron.frag
// IFS Menger : https://github.com/3Dickulus/FragM/blob/master/Fragmentarium-Source/Examples/Kaleidoscopic%20IFS/NewMenger.frag
// IFS fractals : http://www.fractalforums.com/sierpinski-gasket/kaleidoscopic-(escape-time-ifs)/?PHPSESSID=95c58fd40b61747add7ef16564ccc048
// polychora : https://github.com/Syntopia/Fragmentarium/blob/master/Fragmentarium-Source/Examples/Knighty%20Collection/polychora-special.frag
// quadray :https://github.com/Syntopia/Fragmentarium/tree/master/Fragmentarium-Source/Examples/Knighty%20Collection/Quadray
// fragm : https://github.com/3Dickulus/FragM/blob/master/Fragmentarium-Source/Examples/Experimental/MMM.frag
// quat julia 2 : https://github.com/3Dickulus/FragM/blob/master/Fragmentarium-Source/Examples/Experimental/Stereographic4DJulia.frag
// quat mandelbrot : https://github.com/3Dickulus/FragM/blob/master/Fragmentarium-Source/Examples/Experimental/QuaternionMandelbrot4D.frag
// spudsville : https://github.com/3Dickulus/FragM/blob/master/Fragmentarium-Source/Examples/Experimental/Spudsville2.frag
// menger polyhedra : https://github.com/3Dickulus/FragM/blob/master/Fragmentarium-Source/Examples/Benesi/MengersmoothPolyhedra.frag

#include <metal_stdlib>
#include "Shader.h"

using namespace metal;

constant int MAX_MARCHING_STEPS = 255;
constant float MIN_DIST = 0.00002;
constant float MAX_DIST = 30;
constant float PI = 3.1415926;
constant float PI2 = (PI * 2);

float  mod(float  x, float y) { return x - y * floor(x/y); }
float2 mod(float2 x, float y) { return x - y * floor(x/y); }
float3 mod(float3 x, float y) { return x - y * floor(x/y); }

float3 rotatePosition(float3 pos, int axis, float angle) {
    float ss = sin(angle);
    float cc = cos(angle);
    float qt;
    
    switch(axis) {
        case 0 :    // XY
            qt = pos.x;
            pos.x = pos.x * cc - pos.y * ss;
            pos.y =    qt * ss + pos.y * cc;
            break;
        case 1 :    // XZ
            qt = pos.x;
            pos.x = pos.x * cc - pos.z * ss;
            pos.z =    qt * ss + pos.z * cc;
            break;
        case 2 :    // YZ
            qt = pos.y;
            pos.y = pos.y * cc - pos.z * ss;
            pos.z =    qt * ss + pos.z * cc;
            break;
    }
    return pos;
}

//MARK: -
float DE_APOLLONIAN(float3 pos,device Control &control) {
    float k,t = control.foam2 + 0.25 * cos(control.bend * PI * control.multiplier * (pos.z - pos.x));
    float scale = 1;
    
    for(int i=0; i< control.maxSteps; ++i) {
        pos = -1.0 + 2.0 * fract(0.5 * pos + 0.5);
        k = t / dot(pos,pos);
        pos *= k * control.foam;
        scale *= k * control.foam;
    }
    
    return 1.5 * (0.25 * abs(pos.y) / scale);
}

//MARK: -
float DE_APOLLONIAN2(float3 pos,device Control &control) {
    float t = control.foam2 + 0.25 * cos(control.bend * PI * control.multiplier * (pos.z - pos.x));
    float scale = 1;
    
    for(int i=0; i< control.maxSteps; ++i) {
        pos = -1.0 + 2.0 * fract(0.5 * pos + 0.5);
        pos -= sign(pos) * control.foam / 20;
        
        float k = t / dot(pos,pos);
        pos *= k;
        scale *= k;
    }
    
    float d1 = sqrt( min( min( dot(pos.xy,pos.xy), dot(pos.yz,pos.yz) ), dot(pos.zx,pos.zx) ) ) - 0.02;
    float dmi = min(d1,abs(pos.y));
    return 0.5 * dmi / scale;
}

// spider: https://www.shadertoy.com/view/XtKcDm

//MARK: -
float DE_MANDELBULB(float3 pos,device Control &control) {
    float dr = 1;
    float r,theta,phi,pwr,ss;

    for(int i=0; i < control.maxSteps; ++i) {
        r = length(pos);
        if(r > 2) break;

        theta = atan2(sqrt(pos.x * pos.x + pos.y * pos.y), pos.z);
        phi = atan2(pos.y,pos.x);
        pwr = pow(r,control.power);
        ss = sin(theta * control.power);

        pos.x += pwr * ss * cos(phi * control.power);
        pos.y += pwr * ss * sin(phi * control.power);
        pos.z += pwr * cos(theta * control.power);

        dr = (pow(r, control.power - 1.0) * control.power * dr ) + 1.0;
    }

    return 0.5 * log(r) * r/dr;
}

//MARK: -

float dot2(float3 z) { return dot(z,z);}

float3 wrap(float3 x, float3 a, float3 s) {
    x -= s;
    return (x-a*floor(x/a)) + s;
}

float2 wrap(float2 x, float2 a, float2 s){
    x -= s;
    return (x-a*floor(x/a)) + s;
}

void TransA(thread float3 &z, thread float &DF, float a, float b) {
    float iR = 1. / dot2(z);
    z *= -iR;
    z.x = -b - z.x;
    z.y =  a + z.y;
    DF *= iR;
}

float JosKleinian(float3 z,device Control &control) {
    float3 lz=z+float3(1.), llz=z+float3(-1.);
    float DE=1e10;
    float DF = 1.0;
    float a = control.KleinR, b = control.KleinI;
    float f = sign(b) ;
    for (int i = 0; i < control.Box_Iterations; i++) {
        z.x=z.x+b/a*z.y;
        if (control.fourGen)
            z = wrap(z, float3(2. * control.box_size_x, a, 2. * control.box_size_z), float3(-control.box_size_x, 0., -control.box_size_z));
        else
            z.xz = wrap(z.xz, float2(2. * control.box_size_x, 2. * control.box_size_z), float2(-control.box_size_x, -control.box_size_z));
        z.x=z.x-b/a*z.y;
        
        //If above the separation line, rotate by 180∞ about (-b/2, a/2)
        if  (z.y >= a * (0.5 +  f * 0.25 * sign(z.x + b * 0.5)* (1. - exp( - 3.2 * abs(z.x + b * 0.5)))))
            z = float3(-b, a, 0.) - z;//
        //z.xy = float2(-b, a) - z.xy;//
        
        //Apply transformation a
        TransA(z, DF, a, b);
        
        //If the iterated points enters a 2-cycle , bail out.
        if(dot2(z-llz) < 1e-12) {
            break;
        }
        
        //Store previous iterates
        llz=lz; lz=z;
    }
    
    //WIP: Push the iterated point left or right depending on the sign of KleinI
    for (int i=0;i<control.Final_Iterations;i++){
        float y = control.showBalls ? min(z.y, a-z.y) : z.y;
        DE=min(DE,min(y,control.Clamp_y)/max(DF,control.Clamp_DF));
        TransA(z, DF, a, b);
    }
    
    float y = control.showBalls ? min(z.y, a-z.y) : z.y;
    DE=min(DE,min(y,control.Clamp_y)/max(DF,control.Clamp_DF));
    
    return DE;
}

float DE_KLEINIAN(float3 pos,device Control &control) {
    if(control.doInversion) {
        pos = pos - control.InvCenter;
        float r = length(pos);
        float r2 = r*r;
        pos = (control.InvRadius * control.InvRadius / r2 ) * pos + control.InvCenter;
        
        float an = atan2(pos.y,pos.x) + control.DeltaAngle;
        float ra = sqrt(pos.y * pos.y + pos.x * pos.x);
        pos.x = cos(an)*ra;
        pos.y = sin(an)*ra;
        float de = JosKleinian(pos,control);
        de = r2 * de / (control.InvRadius * control.InvRadius + r * de);
        return de;
    }
    
    return JosKleinian(pos,control);
}

//MARK: -
float DE_MANDELBOX(float3 pos,device Control &control) {
    float asf = abs(control.scaleFactor);
    float constant1 = abs(control.scaleFactor - 1.0);
    float constant2 = pow(asf, float(1 - control.maxSteps));
    
    // For the Juliabox, c is a constant. For the Mandelbox, c is variable.
    float3 c = control.juliaboxMode ? control.julia : pos;
    float mag,dr = 1.5;
    
    for(int i = 0; i < control.maxSteps; ++i) {
        // Box fold
        pos = clamp(pos, -control.box1, control.box1) * control.box2 - pos;
        
        // Sphere fold.
        mag = dot(pos,pos);
        if(mag < control.sph1) {
            pos *= control.sph3;
            dr *= control.sph3;
        }
        else if(mag < control.sph2) {
            pos /= mag;
            dr /= mag;
        }
        
        pos = pos * control.scaleFactor + c;
        dr = dr * asf + 1.0;
    }
    
    return (length(pos) - constant1) / dr - constant2;
}

//MARK: -
float DE_QUATJULIA(float3 pos,device Control &control) {
    float4 c = 0.5 * float4(control.cx, control.cy, control.cz, control.cw);
    float4 nz;
    float md2 = 1.0;
    float4 z = float4(pos,0);
    float mz2 = dot(z,z);
    
    for(int i=0;i < control.maxSteps; ++i) {
        md2 *= 4.0 * mz2;
        nz.x = z.x * z.x - dot(z.yzw,z.yzw);
        nz.yzw = 2.0 * z.x * z.yzw;
        z = nz+c;
        
        mz2 = dot(z,z);
        if(mz2 > 12.0) break;
    }
    
    return 0.3 * sqrt(mz2/md2) * log(mz2);
}
    
//MARK: -
float4x4 rotationMat(float3 xyz )
{
    float3 si = sin(xyz);
    float3 co = cos(xyz);
    
    return float4x4( co.y*co.z, co.y*si.z, -si.y, 0.0,
                    si.x*si.y*co.z-co.x*si.z, si.x*si.y*si.z+co.x*co.z, si.x*co.y,  0.0,
                    co.x*si.y*co.z+si.x*si.z, co.x*si.y*si.z-si.x*co.z, co.x*co.y,  0.0,
                    0.0,                      0.0,                      0.0,        1.0 );
}

float DE_MONSTER(float3 pos,device Control &control) {
    float k = 1.0;
    float m = 1e10;
    float r,s = control.cw;
    float time1 = control.cx;
    
    if(control.mm[0][0] > 98) {     // Swift marked this before shader call. result will be shared by other threads
        control.mm = rotationMat( float3(control.cz,0.1,control.cy) +
                                  0.15*sin(0.1*float3(0.40,0.30,0.61)*time1) +
                                  0.15*sin(0.1*float3(0.11,0.53,0.48)*time1));
        control.mm[0].xyz *= s;
        control.mm[1].xyz *= s;
        control.mm[2].xyz *= s;
        control.mm[3].xyz = float3( 0.15, 0.05, -0.07 ) + 0.05*sin(float3(0.0,1.0,2.0) + 0.2*float3(0.31,0.24,0.42)*time1);
    }
    
    for( int i=0; i < control.maxSteps; i++ ) {
        m = min( m, dot(pos,pos) /(k*k) );
        pos = (control.mm * float4((abs(pos)),1.0)).xyz;
        
        r = dot(pos,pos);
        if(r > 1) break;
        
        k *= control.cw;
    }
    
    float d = (length(pos)-0.5)/k;
    return d * 0.25;
}

//MARK: -
float smin(float a, float b, float k ) {
    float h = clamp( 0.5+0.5*(b-a)/k, 0.0, 1.0 );
    return mix( b, a, h ) - k*h*(1.0-h);
}

float4 rotateXZ(float4 pos, float angle) {
    float ss = sin(angle);
    float cc = cos(angle);
    float qt = pos.x;
    pos.x = pos.x * cc - pos.z * ss;
    pos.z =    qt * ss + pos.z * cc;
    return pos;
}

float DE_KALI_TOWER(float3 pos,device Control &control) {
    float aa = smoothstep(0.,1.,clamp(cos(control.cy - pos.y * 0.4)*1.5,0.,1.)) * PI;
    float4 p = float4(pos,1);
    
    p.y -= control.cy * 0.25;
    p.y = abs(3.-fract((p.y - control.cy) / 2));
    
    for (int i=0; i < control.maxSteps; i++) {
        p.xyz = abs(p.xyz) - float3(.0,control.cx,.0);
        p = p * 2./clamp(dot(p.xyz,p.xyz),.3,1.) - float4(0.5,1.5,0.5,0.);
        
        p = rotateXZ(p,aa * control.cz);
    }

    float fl = pos.y-3.7 - length(sin(pos.xz * 60))*.01;
    float fr = max(abs(p.z/p.w)-.01,length(p.zx)/p.w-.002);
    float bl = max(abs(p.x/p.w)-.01,length(p.zy)/p.w-.0005);
    fr = smin(bl,fr,.02);
    fr *= 0.9;
    fl -= (length(p.xz)*.005+length(sin(pos * 3. + control.cy * 5.)) * control.cw);
    fl *=.9;

    return abs(smin(fl,fr,.7));
}

//MARK: -
float2 Rot2D(float2 q, float a) {
    float2 cs = sin(a + float2 (0.5 * PI, 0));
    return float2(dot(q, float2(cs.x, -cs.y)), dot(q.yx, cs));
}

float2 Rot2Cs(float2 q, float2 cs) {
    return float2(dot(q, float2(cs.x, - cs.y)), dot(q.yx, cs));
}

float PrBoxDf(float3 p, float3 b) {
    float3 d = abs(p) - b;
    return min( max(d.x, max(d.y, d.z)), 0.) + length(max(d, 0));
}

float3 DodecSym(float3 p,device Control &control) {
    float a, w;
    w = 2. * PI / control.cx;
    p.xz = Rot2Cs(float2(p.x, abs(p.z)), float2(control.csD.x, -control.csD.y));
    p.xy = Rot2D(p.xy, -0.25 * w);
    p.x = -abs(p.x);
    
    for(int k = 0; k < 3; ++k) {
        if(dot(p.yz, control.csD) > 0.) p.zy = Rot2Cs(p.zy, control.csD2) * float2 (1., -1.);
        p.xy = Rot2D (p.xy, - w);
    }
    
    if(dot(p.yz, control.csD) > 0.) p.zy = Rot2Cs(p.zy, control.csD2) * float2(1., -1.);
    a = mod(atan2(p.x, p.y) + 0.5 * w, w) - 0.5 * w;
    a *= control.cw;
    
    p.yx = float2(cos(a), sin(a)) * length(p.xy);
    p.xz = -float2(abs(p.x), p.z);
    return p;
}

float DE_POLY_MENGER(float3 p,device Control &control) {
    float nIt = 9.69;
    float sclFac = control.cy;
    float3 b = (sclFac - 1) * float3(0.8, 1., 0.5) * (1. + 0.03 * sin (float3(1.23, 1., 1.43)));
    p = DodecSym(p,control);
    p.z += 0.6 * (1. + b.z);
    p.xy /= 1. - control.cz * p.z;

    for (float n = 0.; n < nIt; n ++) {
        p = abs (p);
        p.xy = (p.x > p.y) ? p.xy : p.yx;
        p.xz = (p.x > p.z) ? p.xz : p.zx;
        p.yz = (p.y > p.z) ? p.yz : p.zy;
        p = sclFac * p - b;
        p.z += b.z * step (p.z, -0.5 * b.z);
    }

    return 0.8 * PrBoxDf (p, float3 (1.)) / pow (sclFac, nIt);
}

//MARK: -
float DE_GOLD(float3 p,device Control &control) {
    p.xz = mod(p.xz + 1.0, 2.0) - 1.0;
    float4 q = float4(p, 1);
    for(int i = 0; i < 15; i++) {
        q.xyz = abs(q.xyz) - float3(control.cx,control.cy,control.cz);
        q = 2.0*q/clamp(dot(q.xyz, q.xyz), 0.4, 1.0) - float4(1.0, 0.0, 0.6, 0.0);
    }
    
    return length(q.xyz)/q.w;
}

//MARK: -
float smax(float a, float b, float s) { // iq smin
    float h = clamp( 0.5 + 0.5*(a-b)/s, 0.0, 1.0 );
    return mix(b, a, h) + h*(1.0-h)*s;
}

float DE_SPIDER(float3 p,device Control &control) {
    float q = sin(p.z * control.cx) * control.cy * 10 + 0.6;
    float t = length(p.xy);
    float s = 1.0;
    
    for(int i = 0; i < 2; ++i) {
        float m = dot(p,p);
        p = abs(fract(p/m)-0.5);
        p = rotatePosition(p,0,q);
        s *= m;
    }
    
    float d = (length(p.xz) - control.cz) * s;
    return smax(d,-t, 0.3);
}

//MARK: -
float DE_KLEINIAN2(float3 pos,device Control &control) {
    float k, scale = 1;

    for(int i=0; i < 7; ++i) {
        pos = 2 * clamp(pos, control.mins.xyz, control.maxs.xyz) - pos;
        k = max(control.mins.w / dot(pos,pos), control.power);
        pos *= k;
        scale *= k;
    }

    float rxy = length(pos.xy);
    return .7 * max(rxy - control.maxs.w, rxy * pos.z / length(pos)) / scale;
}

//MARK: -
float DE_KIFS(float3 pos,device Control &control) {
    float4 z = float4(pos,1.0);
    float3 offset = float3(control.cx,1.1,0.5);
    float scale = control.cy;
    float q;
    
    for(int n = 0; n < control.maxSteps; ++n) {
        z = abs(z);
        if (z.x<z.y)z.xy = z.yx;
        if (z.x<z.z)z.xz = z.zx;
        if (z.y<z.z)z.yz = z.zy;
        z = z*scale;
        z.xyz -= offset * (scale - 1); // control.cz);
        
        q = offset.z * (scale - control.cz);
        if(z.z < -0.5 * q)
            z.z += q;
    }
    
    return(length(max(abs(z.xyz)-float3(1.0),0.0))-0.05)/z.w;
}

//MARK: -
float DE_IFS_TETRA(float3 pos,device Control &control) {
    int n = 0;
    while(n < 25) {
        pos = rotatePosition(pos,0,control.angle1);
        
        if(pos.x +pos.y < 0.0) pos.xy = -pos.yx;
        if(pos.x +pos.z < 0.0) pos.xz = -pos.zx;
        if(pos.y +pos.z < 0.0) pos.zy = -pos.yz;
        
        pos = pos * control.cx - float3(1,1,1) * (control.cx - 1.0);
        pos = rotatePosition(pos,1,control.angle2);
        
        n++;
    }
    
    return 0.55 * length(pos) * pow(control.cx, -float(n));
}

//MARK: -
float DE_IFS_OCTA(float3 pos,device Control &control) {
    int n = 0;
    while(n < 18) { 
        pos = rotatePosition(pos,0,control.angle1);
        
        if(pos.x+pos.y < 0.0) pos.xy = -pos.yx;
        if(pos.x+pos.z < 0.0) pos.xz = -pos.zx;
        if(pos.x-pos.y < 0.0) pos.xy = pos.yx;
        if(pos.x-pos.z < 0.0) pos.xz = pos.zx;
        
        pos = pos * control.cx - float3(1,0,0) * (control.cx - 1.0);
        pos = rotatePosition(pos,1,control.angle2);

        n++;
    }
    
    return 0.55 * length(pos) * pow(control.cx, -float(n));
}

//MARK: -
float DE_IFS_DODEC(float3 pos,device Control &control) {
    int n = 0;
    while(n < 30) {
        pos = rotatePosition(pos,0,control.angle1);
        
        pos -= 2.0 * min(0.0, dot(pos, control.n1)) * control.n1;
        pos -= 2.0 * min(0.0, dot(pos, control.n2)) * control.n2;
        pos -= 2.0 * min(0.0, dot(pos, control.n3)) * control.n3;
        pos -= 2.0 * min(0.0, dot(pos, control.n1)) * control.n1;
        pos -= 2.0 * min(0.0, dot(pos, control.n2)) * control.n2;
        pos -= 2.0 * min(0.0, dot(pos, control.n3)) * control.n3;
        pos -= 2.0 * min(0.0, dot(pos, control.n1)) * control.n1;
        pos -= 2.0 * min(0.0, dot(pos, control.n2)) * control.n2;
        pos -= 2.0 * min(0.0, dot(pos, control.n3)) * control.n3;
        
        pos = pos * control.cx - (control.cx - 1.0);
        pos = rotatePosition(pos,1,control.angle2);

        if(dot(pos, pos) > 12) break;
        n++;
    }
    
    return 0.35 * length(pos) * pow(control.cx,float(-n-1));
}

//MARK: -
float DE_IFS_MENGER(float3 pos,device Control &control) {
    pos = pos * 0.5 + float3(0.5);
    float3 pp = abs(pos-0.5)-0.5;
    float k = 1.0;
    float d1 = max(pp.x,max(pp.y,pp.z));
    float d = d1;
    
    for(int i = 0; i < control.maxSteps; ++i) {
        float3 posa = mod(3.0 * pos * k, 3.0);
        k *= control.cx;
        
        pp = 0.5-abs(posa-1.5) + float3(control.cy);
        pp = rotatePosition(pp,0,control.angle1);
        d1 = min(max(pp.x,pp.z),min(max(pp.x,pp.y),max(pp.y,pp.z)))/k;
        d = max(d,d1);
    }
    
    return d;
}

//MARK: -
float DE_SIERPINSKI_T(float3 pos,device Control &control) {
    int i;

    for(i=0;i < control.maxSteps; ++i) {
        pos = rotatePosition(pos,0,control.angle1);

        if(pos.x + pos.y < 0.0) pos.xy = -pos.yx;
        if(pos.x + pos.z < 0.0) pos.xz = -pos.zx;
        if(pos.y + pos.z < 0.0) pos.zy = -pos.yz;

        pos = rotatePosition(pos,1,control.angle2);
        pos = pos * control.cx - control.n1 * (control.cx - 1.0);
        if(length(pos) > 4) break;
    }
    
    return (length(pos) - 2) * pow(control.cx, -float(i));
}

//MARK: -
float DE_HALF_TETRA(float3 pos,device Control &control) {
    int i;
    
    for(i=0;i < control.maxSteps; ++i) {
        pos = rotatePosition(pos,0,control.angle1);
        
        if(pos.x - pos.y < 0.0) pos.xy = pos.yx;
        if(pos.x - pos.z < 0.0) pos.xz = pos.zx;
        if(pos.y - pos.z < 0.0) pos.zy = pos.yz;
        
        pos = rotatePosition(pos,2,control.angle2);
        pos = pos * control.cx - control.n1 * (control.cx - 1.0);
        if(length(pos) > 4) break;
    }
    
    return (length(pos) - 2) * pow(control.cx, -float(i));
}

//MARK: -
float DE_FULL_TETRA(float3 pos,device Control &control) {
    int i;
    
    for(i=0;i < control.maxSteps; ++i) {
        pos = rotatePosition(pos,0,control.angle1);
        
        if(pos.x - pos.y < 0.0) pos.xy =  pos.yx;
        if(pos.x - pos.z < 0.0) pos.xz =  pos.zx;
        if(pos.y - pos.z < 0.0) pos.zy =  pos.yz;
        if(pos.x + pos.y < 0.0) pos.xy = -pos.yx;
        if(pos.x + pos.z < 0.0) pos.xz = -pos.zx;
        if(pos.y + pos.z < 0.0) pos.zy = -pos.yz;
        
        pos = rotatePosition(pos,2,control.angle2);
        pos = pos * control.cx - control.n1 * (control.cx - 1.0);
        if(length(pos) > 4) break;
    }
    
    return (length(pos) - 2) * pow(control.cx, -float(i));
}

//MARK: -
float DE_CUBIC(float3 pos,device Control &control) {
    int i;
    
    for(i=0;i < control.maxSteps; ++i) {
        pos = rotatePosition(pos,0,control.angle1);

        pos = abs(pos);

        pos = rotatePosition(pos,1,control.angle2);
        pos = pos * control.cx - control.n1 * (control.cx - 1.0);
        if(length(pos) > 4) break;
    }
    
    return (length(pos) - 2) * pow(control.cx, -float(i));
}

//MARK: -
float DE_HALF_OCTA(float3 pos,device Control &control) {
    int i;
    
    for(i=0;i < control.maxSteps; ++i) {
        pos = rotatePosition(pos,0,control.angle1);
        
        if(pos.x - pos.y < 0.0) pos.xy =  pos.yx;
        if(pos.x + pos.y < 0.0) pos.xy = -pos.yx;
        if(pos.x - pos.z < 0.0) pos.xz =  pos.zx;
        if(pos.x + pos.z < 0.0) pos.zy = -pos.yz;

        pos = rotatePosition(pos,1,control.angle2);
        pos = pos * control.cx - control.n1 * (control.cx - 1.0);
        if(length(pos) > 4) break;
    }
    
    return (length(pos) - 2) * pow(control.cx, -float(i));
}

//MARK: -
float DE_FULL_OCTA(float3 pos,device Control &control) {
    int i;
    
    for(i=0;i < control.maxSteps; ++i) {
        pos = rotatePosition(pos,0,control.angle1);
        
        pos = abs(pos);
        if(pos.x - pos.y < 0.0) pos.xy =  pos.yx;
        if(pos.x - pos.z < 0.0) pos.xz =  pos.zx;
        if(pos.y - pos.z < 0.0) pos.zy =  pos.yz;
        
        pos = rotatePosition(pos,1,control.angle2);
        pos = pos * control.cx - control.n1 * (control.cx - 1.0);
        if(length(pos) > 4) break;
    }
    
    return (length(pos) - 2) * pow(control.cx, -float(i));
}

//MARK: -
float DE_KALEIDO(float3 pos,device Control &control) {
    int i;
    
    for(i=0;i < control.maxSteps; ++i) {
        pos = rotatePosition(pos,0,control.angle1);
        
        pos = abs(pos);
        if(pos.x - pos.y < 0.0) pos.xy = pos.yx;
        if(pos.x - pos.z < 0.0) pos.xz = pos.zx;
        if(pos.y - pos.z < 0.0) pos.zy = pos.yz;
        
        pos -= 0.5 * control.cz * (control.cx - 1) / control.cx;
        pos = -abs(-pos);
        pos += 0.5 * control.cz * (control.cx - 1) / control.cx;
        
        pos = rotatePosition(pos,1,control.angle2);
        pos = pos * control.cx - control.n1 * (control.cx - 1.0);
        if(length(pos) > 4) break;
    }
    
    return (length(pos) - 2) * pow(control.cx, -float(i));
}

//MARK: -
float4 Rotate(float4 p,device Control &control) {
    //this is a rotation on the plane defined by RotVector and w axis
    //We do not need more because the remaining 3 rotation are in our 3D space
    //That would be redundant.
    //This rotation is equivalent to translation inside the hypersphere when the camera is at 0,0,0
    float4 p1=p;
    float3 rv = normalize(control.sideVector);
    float vp=dot(rv,p.xyz);
    p1.xyz += rv * (vp * (control.cRA-1.) - p.w * control.sRA);
    p1.w += vp * control.sRA + p.w * (control.cRA-1.);
    return p1;
}

float4 fold(float4 pos,device Control &control) {
    for(int i=0;i<3;i++){
        pos.xyz=abs(pos.xyz);
        float t =-2.*min(0.,dot(pos,control.nd));
        pos += t * control.nd;
    }
    return pos;
}

float DDV(float ca, float sa, float r,device Control &control) {
    //magic formula to convert from spherical distance to planar distance.
    //involves transforming from 3-plane to 3-sphere, getting the distance
    //on the sphere (which is an angle -read: sa==sin(a) and ca==cos(a))
    //then going back to the 3-plane.
    //return r-(2.*r*ca-(1.-r*r)*sa)/((1.-r*r)*ca+2.*r*sa+1.+r*r);
    return (2. * r * control.cVR-(1.-r*r) * control.sVR)/((1.-r*r) * control.cVR + 2.*r * control.sVR+1.+r*r)-(2.*r*ca-(1.-r*r)*sa)/((1.-r*r)*ca+2.*r*sa+1.+r*r);
}

float DDS(float ca, float sa, float r,device Control &control) {
    return (2.*r * control.cSR-(1.-r*r) * control.sSR)/((1.-r*r) * control.cSR+2.*r * control.sSR+1.+r*r)-(2.*r*ca-(1.-r*r)*sa)/((1.-r*r)*ca+2.*r*sa+1.+r*r);
}

float dist2Vertex(float4 z, float r,device Control &control) {
    float ca=dot(z,control.p);
    float sa=0.5*length(control.p-z) * length(control.p+z);
    return DDV(ca,sa,r,control);
}

float dist2Segment(float4 z, float4 n, float r,device Control &control) {
    //pmin is the orthogonal projection of z onto the plane defined by p and n
    //then pmin is projected onto the unit sphere
    float zn=dot(z,n);
    float zp=dot(z,control.p);
    float np=dot(n,control.p);
    float alpha= zp-zn*np;
    float beta = zn-zp*np;
    float4 pmin=normalize(alpha * control.p + min(0.,beta)*n);
    //ca and sa are the cosine and sine of the angle between z and pmin. This is the spherical distance.
    float ca =dot(z,pmin);
    float sa =0.5*length(pmin-z)*length(pmin+z);//sqrt(1.-ca*ca);//
    return DDS(ca,sa,r,control);//-SRadius;
}

float dist2Segments(float4 z, float r,device Control &control) {
    float da = dist2Segment(z, float4(1,0,0,0), r,control);
    float db = dist2Segment(z, float4(0,1,0,0), r,control);
    float dc = dist2Segment(z, float4(0,0,1,0), r,control);
    float dd = dist2Segment(z, control.nd, r,control);
    
    return min(min(da,db),min(dc,dd));
}

float DE_POLYCHORA(float3 pos,device Control &control) {
    float r = length(pos);
    float4 z4 = float4(2.*pos,1.-r*r)*1./(1.+r*r);//Inverse stereographic projection of pos: z4 lies onto the unit 3-sphere centered at 0.
    z4=Rotate(z4,control);//z4.xyw=rot*z4.xyw;
    z4=fold(z4,control);//fold it
    return min(dist2Vertex(z4,r,control),dist2Segments(z4,r,control));
}

//MARK: -
float DE_QUADRAY(float3 pos,device Control &control) {
    float v = control.cz;
    matrix_float3x4 mc = matrix_float3x4(float4(v,-v,-v, v), float4(v,-v, v,-v), float4(v, v,-v,-v));
    
    float4 cp = abs(mc * pos) + float4(control.cx);
    float4 z = cp;
    float r = length(z);
    int i;
    cp *= control.cy;
    matrix_float4x4 j = matrix_float4x4(1.);
    
    for(i=0; i < control.maxSteps && r < 12; ++i) {
        j = 2.0 *
        matrix_float4x4
        (z.xxyy * float4( 1.,-1., 1., 1.),
         z.yyxx * float4(-1., 1., 1., 1.),
         z.wwzz * float4( 1., 1., 1.,-1.),
         z.zzww * float4( 1., 1.,-1., 1.)) * j + matrix_float4x4(1);
        
        float4 tmp0 = z*z;
        float2 tmp1 = 2. * z.wx * z.zy;
        z = tmp0-tmp0.yxwz + tmp1.xxyy + cp;
        r=length(z.xyz);
    }

    j[0]=abs(j[0]); j[1]=abs(j[1]); j[2]=abs(j[2]); j[3]=abs(j[3]);
    z = j * float4(1.,1.,1.,1.);
    z.xy = max(z.xy,z.zw);
    float dr = max(z.x,z.y);
    
    return 5 * r * log(r) / dr;
}

//MARK: -
float3 powN1(float3 z, float r, thread float &dr,device Control &control) {
    // extract polar coordinates
    float theta = acos(z.z/r);
    float phi = atan2(z.y,z.x);
    dr = pow(r, control.power-1.0)*control.power * dr + 1.0;
    
    // scale and rotate the point
    float zr = pow( r,control.power);
    theta = theta*control.power;
    phi = phi*control.power;
    
    // convert back to cartesian coordinates
    z = zr*float3(sin(theta)*cos(phi), sin(phi)*sin(theta), cos(theta));
    
    return z;
}

float3 powN2(float3 z, float zr0, thread float &dr,device Control &control) {
    float zo0 = asin( z.z/zr0 );
    float zi0 = atan2( z.y,z.x );
    float zr = pow(zr0, control.power-1.0);
    float zo = zo0 * control.power;
    float zi = zi0 * control.power;
    dr = zr * dr * control.power + 1.0;
    zr *= zr0;
    z = zr * float3(cos(zo)*cos(zi), cos(zo)*sin(zi), sin(zo));
    
    return z;
}

// Compute the distance from `pos` to the Mandelbulb.
float mandelDE(float3 pos,device Control &control) {
    float3 z=pos;
    float r;
    float dr=1.0;
    int i=0;
    r=length(z);
    while(r < 8 && (i < control.maxSteps)) {
        if(control.AlternateVersion) {
            z = powN2(z,r,dr,control);
        } else {
            z = powN1(z,r,dr,control);
        }
        
        z += (control.juliaboxMode ? control.julia : pos);
        r=length(z);
        z = rotatePosition(z,0,control.angle1);
        i++;
    }
    
    return 0.5*log(r)*r/dr;
}

// knighty's Menger-Sphere
float mengersDE(float3 pos,device Control &control) {
    float3 ap=abs(pos);
    float Linf=max(max(ap.x,ap.y),ap.z);//infinity norm
    float L2=length(pos);//euclidean norm
    float multiplier = control.cx * L2/Linf;
    pos *= multiplier;//Spherify transform.
    float dd = multiplier; // * 1.6;//to correct the DE. Found by try and error. there should be better formula.
    float r2 = dot(pos,pos);

    for(int i = 0; i < control.msIterations && r2 < 100.;++i) {
        pos = abs(pos);
        if(pos.y > pos.x) pos.xy = pos.yx;
        if(pos.z > pos.y) pos.yz = pos.zy;
        if(pos.y > pos.x) pos.xy = pos.yx;
        pos.z = abs(pos.z-1./3. * control.msOffset.z)+1./3. * control.msOffset.z;
        pos = pos * control.msScale - control.msOffset * (control.msScale-1.);
        dd *= control.msScale;
        pos = rotatePosition(pos,0,control.angle2);
        r2 = dot(pos,pos);
    }

    return (sqrt(r2) - control.sr)/dd;//bounding volume is a sphere
}

float mandelboxDE(float3 pos,device Control &control) {
    float4 p = float4(pos,1.), p0 = p;  // p.w is the distance estimate
    
    for(int i=0; i < control.mbIterations; ++i) {
        float3 temp = p.xyz;
        p.xyz = rotatePosition(temp,0,control.angle1);
        p.xyz = clamp(p.xyz, -1.0, 1.0) * 2.0 - p.xyz;  // min;max;mad
        float r2 = dot(p.xyz, p.xyz);
        p *= clamp(max(control.mbMinRad2/r2, control.mbMinRad2), 0.0, 1.0);  // dp3,div,max.sat,mul
        p = p * control.mbScale + p0;
        if( r2>1000.0) break;
    }
    
    return ((length(p.xyz) - control.absScalem1) / p.w - control.AbsScaleRaisedTo1mIters);
}

float DE_FRAGM(float3 pos,device Control &control) {
    float rd = 0;
    if(control.maxSteps > 0) rd = mandelDE(abs(pos),control);
    if(control.msIterations > 0) rd += mengersDE(abs(pos),control);
    if(control.mbIterations > 0) rd += mandelboxDE(abs(pos),control);
    
    return rd;
};

//MARK: -
float4 stereographic3Sphere(float3 pos,device Control &control) {
    float n = dot(pos,pos)+1.;
    return float4(control.cx * pos,n-2.) / n;
}

float2 complexMul(float2 a, float2 b) { return float2(a.x*b.x - a.y*b.y, a.x*b.y + a.y * b.x); }

float DE_QUATJULIA2(float3 pos,device Control &control) {
    float4 p4 = stereographic3Sphere(pos,control);
    
    p4.xyz += control.julia;    // "offset"

    float2 p = p4.xy;
    float2 c = p4.zw;
    float dp = 1.0;
    
    for (int i = 0; i < control.maxSteps; ++i) {
        dp = 2.0 * length(p) * dp + 1.0;
        p = complexMul(p,p) + c;
        if(dot(p,p) > 10) break;
    }
    
    float r = length(p);
    return r * log(r) / abs(dp);
}

//MARK: -
float DE_MBROT(float3 pos,device Control &control) {
    float4 p = float4(pos, control.cx);
    float4 dp = float4(1.0, 0.0,0.0,0.0);

    p.yzw = rotatePosition(p.yzw,0,control.julia.x);
    p.yzw = rotatePosition(p.yzw,1,control.julia.y);
    p.yzw = rotatePosition(p.yzw,2,control.julia.z);
    
    for (int i = 0; i < control.maxSteps;++i) {
        dp = 2.0 * float4(p.x * dp.x-dot(p.yzw, dp.yzw), p.x*dp.yzw+dp.x*p.yzw + cross(p.yzw, dp.yzw));
        p = float4(p.x * p.x - dot(p.yzw, p.yzw), float3(2.0 *p.x * p.yzw)) + float4(pos, 0.0);
        
        float p2 = dot(p,p);
        if(p2 > 10) break;
    }
    
    float r = length(p);
    return 0.2 * r * log(r) / length(dp);
}

//MARK: -
float DE_KALIBOX(float3 pos,device Control &control) {
    float4 p = float4(pos,1), p0 = float4(control.julia,1);  // p.w is the distance estimate
    
    for (int i = 0; i < control.maxSteps;++i) {
        
        // p.xyz*=rot;
        p.xyz = rotatePosition(p.xyz,0,control.angle1);
        p.xyz = rotatePosition(p.xyz,1,control.angle1);

        p.xyz = abs(p.xyz) + control.n1;
        float r2 = dot(p.xyz, p.xyz);
        p *= clamp(max(control.cy/r2, control.cy), 0.0, 1.0);  // dp3,div,max.sat,mul
        p = p * control.mins + (control.juliaboxMode ? p0 : float4(0.0));
    }
    
    return ((length(p.xyz) - control.absScalem1) / p.w - control.AbsScaleRaisedTo1mIters);
}

//MARK: -
void spudsSphereFold(thread float3 &z, thread float &dz,device Control &control) {
    float r2 = dot(z,z);
    if (r2< control.cx) {
        float temp = (control.cy / control.cx);
        z *= temp;
        dz *= temp;
    } else if (r2 < control.cy) {
        float temp = control.cy /r2;
        z *= temp;
        dz *= temp;
    }
}

void spudsBoxFold(thread float3 &z, thread float &dz,device Control &control) {
    z = clamp(z, -control.cz, control.cz) * 2.0 - z;
}

void spudsBoxFold3(thread float3 &z, thread float &dz,device Control &control) {
    z = clamp(z, -control.cw,control.cw) * 2.0 - z;
}

void spudsPowN2(thread float3 &z, float zr0, thread float &dr,device Control &control) {
    float zo0 = asin( z.z/zr0 );
    float zi0 = atan2( z.y,z.x );
    float zr = pow( zr0, control.power-1.0 );
    float zo = zo0 * control.power;
    float zi = zi0 * control.power;
    dr = zr*dr * control.power * abs(length(float3(1.0,1.0,control.dx)/sqrt(3.0))) + 1.0;
    zr *= zr0;
    z = zr*float3( cos(zo)*cos(zi), cos(zo)*sin(zi), control.dx * sin(zo) );
}

float DE_SPUDS(float3 pos,device Control &control) {
    int n = 0;
    float dz = 1.0;
    float r = length(pos);
    
    while(r < 10 && n < control.maxSteps) {
        if (n < 6) {
            spudsBoxFold(pos,dz,control);
            spudsSphereFold(pos,dz,control);
            pos = control.dz * pos;
            dz *= abs(control.dz);
        } else {
            spudsBoxFold3(pos,dz,control);
            r = length(pos);
            spudsPowN2(pos,r,dz,control);
            pos = control.dw * pos;
            dz *= abs(control.dw);
        }
        
        r = length(pos);
        n++;
    }
    
    return r * log(r) / dz;
}

//MARK: -
void Spheric(thread float3 &z) {
    float rCyz = (z.y*z.y)/(z.z*z.z);
    float rCxyz = (z.y*z.y+z.z*z.z)/(z.x*z.x);
    if(rCyz<1.) { rCyz = sqrt(rCyz+1.); } else { rCyz = sqrt(1./rCyz+1.); }
    if(rCxyz<1.) { rCxyz=sqrt(rCxyz+1.); } else { rCxyz = sqrt(1./rCxyz+1.); }
    
    z.yz *= rCyz;
    z *= rCxyz;
}

void unSpheric(thread float3 &z) {
    float rCyz = (z.y*z.y)/(z.z*z.z);
    if(rCyz<1.) { rCyz = 1./sqrt(rCyz+1.); } else { rCyz = 1./sqrt(1./rCyz+1.); }
    z.yz *= rCyz;
    float rCxyz= (z.y*z.y+z.z*z.z)/(z.x*z.x);
    if(rCxyz<1.) { rCxyz = 1./sqrt(rCxyz+1.); } else { rCxyz = 1./sqrt(1./rCxyz+1.); }
    z.xyz *= rCxyz;
}

void Tubular (thread float3 &z) {
    float rCyz = (z.y*z.y)/(z.z*z.z);
    if(rCyz<1.) { rCyz = sqrt(rCyz+1.); } else { rCyz = sqrt(1./rCyz+1.); }
    z.yz *= rCyz;
}

void polygonator (thread float3 &z,device Control &control) { // use with tubular or (polyhedronator & spheric)
    float rCyz = atan2(z.z,z.y);
    float i=1.;
    while(rCyz >  PI/control.cx && i < control.cx) { rCyz -= PI2/control.cx; i++;}
    while(rCyz < -PI/control.cx && i < control.cx) { rCyz += PI2/control.cx; i++;}
    z.yz *= cos(rCyz);
}

void polyhedronator (thread float3 &z,device Control &control) {
    z.yz *= tan(PI/control.cy);
    float rCxyz = atan2(sqrt(z.y*z.y+z.z*z.z),z.x);
    float i=1.;
    while(rCxyz >  PI/control.cy && i < control.cy) { rCxyz -= PI2/control.cy; i++; }
    while(rCxyz < -PI/control.cy && i < control.cy) { rCxyz += PI2/control.cy; i++; }
    z *= cos(rCxyz);
}

//void unpolygonator (thread float3 &z,device Control &control) { // use with tubular or (polyhedronator & spheric)
//    float rCyz = atan2(z.z,z.y);
//    float i=1.;
//    while (rCyz >  PI/control.cx && i < control.cx) { rCyz -= PI2/control.cx; i++; }
//    while (rCyz <- PI/control.cx && i < control.cx) { rCyz += PI2/control.cx; i++; }
//    z.yz /= cos(rCyz);
//}
//
//void unpolyhedronator (thread float3 &z,device Control &control) {
//    float i=1.;
//    float rCxyz = atan2(sqrt(z.y*z.y+z.z*z.z),z.x);
//    while ( rCxyz >  PI/control.cy && i < control.cy) { rCxyz -= PI2/control.cy; i++; }
//    while ( rCxyz <- PI/control.cy && i < control.cy) { rCxyz += PI2/control.cy; i++; }
//    z /= cos(rCxyz);
//}

void gravitate (thread float3 &z,device Control &control) {
    float sr13 = sqrt(1./3.);
    float sr23 = sqrt(2./3.);
    float yz = sqrt(z.x*z.x+z.y*z.y+z.z*z.z);
    float tanyz = control.cw / yz;
    tanyz = sr13-sr23 * tanyz;
    tanyz *= tanyz;
    yz =sqrt(tanyz + 2./3.);
    z.xyz *= yz;
}

float DE_MPOLY(float3 pos,device Control &control) {
    float t = 9999.0;
    float sc = control.cz;
    float sc1 = sc-1.0;
    float sc2 = sc1 / sc;
    float3 C = float3(1.0,1.0,.5);
    float w=1.;
    
    if(control.polygonate) polygonator(pos,control);
    if(control.polyhedronate) polyhedronator(pos,control);
    if(control.TotallyTubular) Tubular(pos);

    pos = rotatePosition(pos,1,control.angle1);

    if(control.Sphere || control.HoleSphere) Spheric(pos);
    if(control.unSphere) unSpheric(pos);
    if (control.gravity) gravitate(pos,control);
    
    for (int i = 0; i < control.maxSteps; ++i) {
        pos = float3(sqrt(pos.x * pos.x + control.dx), sqrt(pos.y * pos.y + control.dx), sqrt(pos.z * pos.z + control.dx));

        if(control.HoleSphere) unSpheric(pos);
        t = pos.x - pos.y;
        t = 0.5 * (t - sqrt(t*t + control.dx));
        pos.x = pos.x - t;
        pos.y = pos.y + t;
        
        t = pos.x - pos.z;
        t = 0.5 * (t - sqrt(t*t + control.dx));
        pos.x = pos.x - t;
        pos.z = pos.z + t;
        
        t = pos.y - pos.z;
        t = 0.5 * (t - sqrt(t*t + control.dx));
        pos.y = pos.y - t;
        pos.z = pos.z + t;
        if(control.HoleSphere) Spheric(pos);
        
        pos.z = pos.z - C.z * sc2;
        pos.z = -sqrt(pos.z * pos.z + control.dx);
        pos.z = pos.z + C.z * sc2;
        
        pos.x = sc * pos.x -C.x * sc1;
        pos.y = sc * pos.y -C.y * sc1;
        pos.z = sc * pos.z;
        
        w = w * sc;
    }

    return abs(length(pos)) / w;
}

//MARK: - distance estimate
float DE(float3 pos,device Control &control) {
    switch(control.equation) {
        case EQU_MANDELBULB  : return DE_MANDELBULB(pos,control);
        case EQU_APOLLONIAN  : return DE_APOLLONIAN(pos,control);
        case EQU_APOLLONIAN2 : return DE_APOLLONIAN2(pos,control);
        case EQU_KLEINIAN    : return DE_KLEINIAN(pos,control);
        case EQU_MANDELBOX   : return DE_MANDELBOX(pos,control);
        case EQU_QUATJULIA   : return DE_QUATJULIA(pos,control);
        case EQU_MONSTER     : return DE_MONSTER(pos,control);
        case EQU_KALI_TOWER  : return DE_KALI_TOWER(pos,control);
        case EQU_POLY_MENGER : return DE_POLY_MENGER(pos,control);
        case EQU_GOLD        : return DE_GOLD(pos,control);
        case EQU_SPIDER      : return DE_SPIDER(pos,control);
        case EQU_KLEINIAN2   : return DE_KLEINIAN2(pos,control);
        case EQU_KIFS        : return DE_KIFS(pos,control);
        case EQU_IFS_TETRA   : return DE_IFS_TETRA(pos,control);
        case EQU_IFS_OCTA    : return DE_IFS_OCTA(pos,control);
        case EQU_IFS_DODEC   : return DE_IFS_DODEC(pos,control);
        case EQU_IFS_MENGER  : return DE_IFS_MENGER(pos,control);
        case EQU_SIERPINSKI  : return DE_SIERPINSKI_T(pos,control);
        case EQU_HALF_TETRA  : return DE_HALF_TETRA(pos,control);
        case EQU_FULL_TETRA  : return DE_FULL_TETRA(pos,control);
        case EQU_CUBIC       : return DE_CUBIC(pos,control);
        case EQU_HALF_OCTA   : return DE_HALF_OCTA(pos,control);
        case EQU_FULL_OCTA   : return DE_FULL_OCTA(pos,control);
        case EQU_KALEIDO     : return DE_KALEIDO(pos,control);
        case EQU_POLYCHORA   : return DE_POLYCHORA(pos,control);
        case EQU_QUADRAY     : return DE_QUADRAY(pos,control);
        case EQU_FRAGM       : return DE_FRAGM(pos,control);
        case EQU_QUATJULIA2  : return DE_QUATJULIA2(pos,control);
        case EQU_MBROT       : return DE_MBROT(pos,control);
        case EQU_KALIBOX     : return DE_KALIBOX(pos,control);
        case EQU_SPUDS       : return DE_SPUDS(pos,control);
        case EQU_MPOLY       : return DE_MPOLY(pos,control);
    }
    
    return 0;
}

//MARK: -
// x = distance, y = iteration count

float2 shortest_dist(float3 eye, float3 marchingDirection,device Control &control) {
    float dist;
    float2 ans = float2(MIN_DIST,0);
    int i = 0;
    
    for(; i < MAX_MARCHING_STEPS; ++i) {
        dist = DE(eye + ans.x * marchingDirection,control);
        if(dist < MIN_DIST) break;

        ans.x += dist;
        if(ans.x >= MAX_DIST) break;
    }
    
    ans.y = float(i);
    return ans;
}

float3 calcNormal(float3 pos,device Control &control) {
    float2 e = float2(1.0,-1.0) * 0.0057;
    float3 ans = normalize(e.xyy * DE( pos + e.xyy, control) +
                           e.yyx * DE( pos + e.yyx, control) +
                           e.yxy * DE( pos + e.yxy, control) +
                           e.xxx * DE( pos + e.xxx, control) );
    
    return normalize(ans);
}

//MARK: -
// boxplorer's method
float3 getBlinnShading(float3 normal, float3 direction, float3 light,device Control &control) {
    float3 halfLV = normalize(light + direction);
    float spe = pow(max( dot(normal, halfLV), 0.0 ), 32.0);
    float dif = dot(normal, light) * 0.5 + 0.75;
    return dif + spe * control.specular;
}

//MARK: -

kernel void rayMarchShader
(
 texture2d<float, access::write> outTexture [[texture(0)]],
 device Control &control [[buffer(0)]],
 uint2 p [[thread_position_in_grid]]
 )
{
    float den = float(control.xSize);
    float dx =  1.5 * (float(p.x)/den - 0.5);
    float dy = -1.5 * (float(p.y)/den - 0.5);
    float3 color = float3();
    
    float3 direction = normalize((control.sideVector * dx) + (control.topVector * dy) + control.viewVector);
    float2 dist = shortest_dist(control.camera,direction,control);
    
    if (dist.x <= MAX_DIST - 0.0001) {
        float3 position = control.camera + dist.x * direction;
        float3 normal = calcNormal(position,control);
        
        color = float3(1 - (normal / 10 + sqrt(dist.y / 100))) * control.bright;
        color = 0.5 + (color - 0.5) * control.contrast * 2;
        
        float3 light = getBlinnShading(normal, direction, control.nlight, control);
        color = mix(light, color, 0.8);
    }
    
    outTexture.write(float4(color.xzy,1),p);
}
