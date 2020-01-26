// http://blog.hvidtfeldts.net/index.php/2011/06/distance-estimated-3d-fractals-part-i/
// https://github.com/portsmouth/snelly (under fractals: apollonian_pt.html)
// also visit: http://paulbourke.net/fractals/apollony/
// apollonian: https://www.shadertoy.com/view/4ds3zn
// apollonian2: https://www.shadertoy.com/view/llKXzh
// mandelbox : http://www.fractalforums.com/3d-fractal-generation/a-mandelbox-distance-estimate-formula/
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
// menger helix by dr2 : https://www.shadertoy.com/view/4sVyDt
// FlowerHive: https://www.shadertoy.com/view/lt3Gz8
// Jungle : https://www.shadertoy.com/view/Wd23RD
// Prisoner : https://www.shadertoy.com/view/llVGDR
// SpiralBox : https://fractalforums.org/fragmentarium/17/last-length-increase-colouring-well-sort-of/2515
// spider : https://www.shadertoy.com/view/XtKcDm
// Aleksandrov MandelBulb : https://fractalforums.org/fractal-institute/47/formulas-of-aleksandrov/656
// Surfbox : http://www.fractalforums.com/amazing-box-amazing-surf-and-variations/httpwww-shaperich-comproshred-elite-review/
// Twistbox: http://www.fractalforums.com/amazing-box-amazing-surf-and-variations/twistbox-spiralling-1-scale-box-variant/
// Kali Rontgen : https://www.shadertoy.com/view/XlXcRj
// VERTEBRAE (+ equ 6) : https://fractalforums.org/code-snippets-fragments/74/logxyzsinxyz-transforms/2430
// DarkBeamSurf : https://fractalforums.org/code-snippets-fragments/74/darkbeams-surfbox/2366
// Buffalo : https://fractalforums.org/fragmentarium/17/buffalo-bulb-deltade/2313
// Ancient Temple : https://www.shadertoy.com/view/4lX3Rj
// Kali 3 : https://www.shadertoy.com/view/Xs2GDK
// Sponge : https://www.shadertoy.com/view/3dlXWn
// Floral Hybrid: https://www.shadertoy.com/view/MsS3zc
// Torus Knot : https://www.shadertoy.com/view/3dXXDN
// Donuts : https://www.shadertoy.com/view/lttcWn
//------------------------------------------------------------
// Procedure to add a new fractal algorithm to the list
// 1. Find the fractals' DE (Distance estimation routine).
//    To fit the pattern of the other fractals, this routine should accept a
//    float3 position, and output a float distance.
// 2. Add a new entry to the fractal ID list at the top of shader.h
//    If your new fractal is named fooBar, I would give it the ID "EQU_42_fooBar"
//    (or whatever # is next in line)
// 3. Add the fractal's name to the end of the titleString[] array (viewcontroller, ~line #129)
// 4. Add the fractal ID to the compute shader's switch statement. (this file, ~line #1617)
//    Have it call your new DE routine (example: DE_fooBar(pos,control) )
// 5. Add your DE routine to Shaders.metal (this file)
// 6. Refactor your DE routine as necessary:
//    a. To matchup with the other routines, your input position variable should be called 'pos'
//    b. Replace all vec2,float3,vec4 with float2,float3,float4.
//    c. Replace desired hard-wired parameters with 'control variables of your choosing.
//       Note that control (defined in Shader.h) already has many variables you can use in your routine.
//       Suggest you use cx,cy,cz,cw,dx,dy,dz,dw,ex,ey,ez,ew,angle1,angle2. (look at the other DEs )
// 7. We need to update the reset() routine to provide default values for all your control parameters.
//    In viewController.swift, ~line #501, add your new ID case statement,
//    and a block of default values you can copy/paste from some other case statement in that has
//    parameters roughly matching your list. We'll set the final default values in a few more steps.
//    You might want to set your param defaults to match values you learned from the DE author's writeup.
// 8. We need to update the defineWidgetsForCurrentEquation() routine so that it displays the correct parameters
//    when you fractal is active.
//    In viewController.swift, ~line #1080, add your new ID case statement,
//    and the widget entries that match the control parameters you used.
//
//    example: widget.addEntry("Box",&control.cx, 0,10,0.01)
//    control's cx value will hold the fractal's 'Box' variable.
//    It will range between 0 and 10, and each press of the Lt/Rt arrow keys will alter it by 0.01
// 9. Almost done. The code should all compile now.
//    Run the program. It defaults to showing fractal #1.
//    Press the '1' key to step backwards in the fractal list to the last entry, your new fractal.
//    You should see your fractal's name in the window title bar,
//    and the widgets you defined the instruction text.
//    But if your luck is like mine, the screen is black.
//    We need to find the collection of parameter values that produce an image.
//
//    Follow these steps:
//    1. Triple check your DE routine. Compare it to the code in the other DE routines,
//       especially the way it determines the return value after the iteration loop terminates.
//    2. Tap the 'H' key repeatedly until you see ANY pixels on the screen.
//       Take a look at the setControlParametersToRandomValues() routine in viewcontroller.swift line #766,
//       which is called every 'H' press.
//       Alter setControlParametersToRandomValues() if necessary so that it randomizes all your control params.
//       (angle1, angle2 can be ignored, because they always work)
//    3. When you get some rendered pixels, press 'V' (calls displayControlParametersInConsoleWindow(), that you might want to augment)
//       It will display a block of variable settings in the console window.
//       Copy that whole block, and paste it into your DE's reset() case statement
//       (viewController.swift, ~line #501).
//    4. Now look over the list of parameter settings you just pasted.
//       You can remove settings that don't apply to your fractal.
//       Ensure your widget definitions encompass the values the random routine found.
//       For example, perhaps you used "widget.addEntry("Box",&control.cx, 0,10,0.01)"
//       which restricts cx to 0 ... 10,  yet your new default setting has cx = -3.
//       Update your widget definitions as necessary so that when we re-run the program,
//       you can begin to manually edit each parameter to find a good rendering.
//    5. Every time you make progress in getting a better rendering, repeat step 3 so
//       that your default settings capture your progress.
//       It's easy to have something that "isn't bad, but I bet I can make it better..",
//       and then make too many bad moves and you can't find a way back.
//    6. You finally found the default rendering you want to present to the users,
//       including the camera position. Do step 3 one last time to capture the dataset.
//       Now one by one, exercise each widget, and tighten up it's min/max values to reasonable settings.
//       Also update the 'delta' value so the widget has fine control over changes.
//
// The swift routine that calls the compute shader is computeTexture()  (Viewcontroller, line # 510).
// We want to do as much variable preparation as we can on the CPU side,
// rather than repeatedly in the shader.
//
// Take a look at EQU_25_POLYCHORA preparation at line #550...
// At this time the 'c' variable is a copy of the control structure that will be passed to the shader.
//
// Take a look at EQU_27_FRAGM preparation at line #563...
// It calls prepareJulia().  Many of the fractals optionally use a 'Julia set constant position'
// prepareJulia() packs the 3 widget values into a float3 for the shader.
//
// Also look at EQU_27_FRAGM section of displayWidgets()  (Widget.swift, line #157..)
// Here we call juliaEntry() so that the Julia on/off instruction is displayed.
// also note how booleanEntry() is used to add a toggle instruction "K: Alternate Version"
// That "K" keypress is handled in Viewcontroller's keyDown() routine, line #649.
//
// good luck
//------------------------------------------------------------

#include <metal_stdlib>
#include "Shader.h"

using namespace metal;

constant int MAX_MARCHING_STEPS = 255;
constant float MIN_DIST = 0.00002;
constant float MAX_DIST = 60;
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

//MARK: - 1
float DE_MANDELBULB(float3 pos,device Control &control,thread float4 &orbitTrap) {
    float dr = 1;
    float r,theta,phi,pwr,ss;

    float3 ot,trap = control.otFixed;
    if(int(control.orbitStyle + 0.5) == 2) trap -= pos;
    
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
        
        ot = pos;
        if(control.orbitStyle > 0) ot -= trap;
        float4 hk = float4(ot,r);
        orbitTrap = min(orbitTrap, dot(hk,hk));
    }

    return 0.5 * log(r) * r/dr;
}

//MARK: - 2
float DE_APOLLONIAN(float3 pos,device Control &control,thread float4 &orbitTrap) {
    float k,t = control.foam2 + 0.25 * cos(control.bend * PI * control.multiplier * (pos.z - pos.x));
    float scale = 1;

    float3 ot,trap = control.otFixed;
    if(int(control.orbitStyle + 0.5) == 2) trap -= pos;
    
    for(int i=0; i< control.maxSteps; ++i) {
        pos = -1.0 + 2.0 * fract(0.5 * pos + 0.5);
        k = t / dot(pos,pos);
        pos *= k * control.foam;
        scale *= k * control.foam;
        
        ot = pos;
        if(control.orbitStyle > 0) ot -= trap;
        orbitTrap = min(orbitTrap, float4(abs(ot), dot(ot,ot)));
    }
    
    return 1.5 * (0.25 * abs(pos.y) / scale);
}

//MARK: - 3
float DE_APOLLONIAN2(float3 pos,device Control &control,thread float4 &orbitTrap) {
    float t = control.foam2 + 0.25 * cos(control.bend * PI * control.multiplier * (pos.z - pos.x));
    float scale = 1;
    
    float3 ot,trap = control.otFixed;
    if(int(control.orbitStyle + 0.5) == 2) trap -= pos;
    
    for(int i=0; i< control.maxSteps; ++i) {
        pos = -1.0 + 2.0 * fract(0.5 * pos + 0.5);
        pos -= sign(pos) * control.foam / 20;
        
        float k = t / dot(pos,pos);
        pos *= k;
        scale *= k;
        
        ot = pos;
        if(control.orbitStyle > 0) ot -= trap;
        orbitTrap = min(orbitTrap, float4(abs(ot), dot(ot,ot)));
    }
    
    float d1 = sqrt( min( min( dot(pos.xy,pos.xy), dot(pos.yz,pos.yz) ), dot(pos.zx,pos.zx) ) ) - 0.02;
    float dmi = min(d1,abs(pos.y));
    return 0.5 * dmi / scale;
}

//MARK: - 4

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

float JosKleinian(float3 z,device Control &control,thread float4 &orbitTrap) {
    float3 lz=z+float3(1.), llz=z+float3(-1.);
    float DE=1e10;
    float DF = 1.0;
    float a = control.KleinR, b = control.KleinI;
    float f = sign(b) ;

    float3 ot,trap = control.otFixed;
    if(int(control.orbitStyle + 0.5) == 2) trap -= z;
    
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
        
        ot = z;
        if(control.orbitStyle > 0) ot -= trap;
        orbitTrap = min(orbitTrap, float4(abs(ot), dot(ot,ot)));
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

float DE_KLEINIAN(float3 pos,device Control &control,thread float4 &orbitTrap) {
    if(control.doInversion) {
        pos = pos - control.InvCenter;
        float r = length(pos);
        float r2 = r*r;
        pos = (control.InvRadius * control.InvRadius / r2 ) * pos + control.InvCenter;
        
        float an = atan2(pos.y,pos.x) + control.InvAngle;
        float ra = sqrt(pos.y * pos.y + pos.x * pos.x);
        pos.x = cos(an)*ra;
        pos.y = sin(an)*ra;
        float de = JosKleinian(pos,control,orbitTrap);
        de = r2 * de / (control.InvRadius * control.InvRadius + r * de);
        return de;
    }
    
    return JosKleinian(pos,control,orbitTrap);
}

//MARK: - 5
float boxFold(float v, float fold) { return abs(v + fold) - fabs(v- fold) - v; }

float boxFold2(float v, float fold) { // http://www.fractalforums.com/new-theories-and-research/mandelbox-variant-21/
    if(v < -fold) v = -2 * fold - v;
    return v;
}

float DE_MANDELBOX(float3 pos,device Control &control,thread float4 &orbitTrap) {
    // For the Juliabox, c is a constant. For the Mandelbox, c is variable.
    float3 c = control.juliaboxMode ? control.julia : pos;
    float r2,dr = control.power;

    float fR2 = control.cz * control.cz;
    float mR2 = control.cw * control.cw;

    float3 ot,trap = control.otFixed;
    if(int(control.orbitStyle + 0.5) == 2) trap -= pos;
    
    for(int i = 0; i < control.maxSteps; ++i) {
        if(control.doInversion) {
            pos.x = boxFold(pos.x,control.cx);
            pos.y = boxFold(pos.y,control.cx);
            pos.z = boxFold(pos.z,control.cx);
        }
        else {
            pos.x = boxFold2(pos.x,control.cx);
            pos.y = boxFold2(pos.y,control.cx);
            pos.z = boxFold2(pos.z,control.cx);
        }

        r2 = pos.x*pos.x + pos.y*pos.y + pos.z*pos.z;

        if(r2 < mR2) {
            float temp = fR2 / mR2;
            pos *= temp;
            dr *= temp;
        }
        else if(r2 < fR2) {
            float temp = fR2 / r2;
            pos *= temp;
            dr *= temp;
        }

        pos = pos * control.power + c;
        dr *= control.power;
        
        ot = pos;
        if(control.orbitStyle > 0) ot -= trap;
        orbitTrap = min(orbitTrap, float4(abs(ot), dot(ot,ot)));
    }

    return length(pos)/abs(dr);
}

//MARK: - 6
float DE_QUATJULIA(float3 pos,device Control &control,thread float4 &orbitTrap) {
    float4 c = 0.5 * float4(control.cx, control.cy, control.cz, control.cw);
    float4 nz;
    float md2 = 1.0;
    float4 z = float4(pos,0);
    float mz2 = dot(z,z);
    
    float3 ot,trap = control.otFixed;
    if(int(control.orbitStyle + 0.5) == 2) trap -= pos;
    
    for(int i=0;i < control.maxSteps; ++i) {
        md2 *= 4.0 * mz2;
        nz.x = z.x * z.x - dot(z.yzw,z.yzw);
        nz.yzw = 2.0 * z.x * z.yzw;
        z = nz+c;
        
        mz2 = dot(z,z);
        if(mz2 > 12.0) break;

        ot = z.xyz;
        if(control.orbitStyle > 0) ot -= trap;
        orbitTrap = min(orbitTrap, float4(abs(ot), mz2));
    }
    
    return 0.3 * sqrt(mz2/md2) * log(mz2);
}
    
//MARK: - 7
float4x4 rotationMat(float3 xyz )
{
    float3 si = sin(xyz);
    float3 co = cos(xyz);
    
    return float4x4( co.y*co.z, co.y*si.z, -si.y, 0.0,
                    si.x*si.y*co.z-co.x*si.z, si.x*si.y*si.z+co.x*co.z, si.x*co.y,  0.0,
                    co.x*si.y*co.z+si.x*si.z, co.x*si.y*si.z-si.x*co.z, co.x*co.y,  0.0,
                    0.0,                      0.0,                      0.0,        1.0 );
}

float DE_MONSTER(float3 pos,device Control &control,thread float4 &orbitTrap) {
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
    
    float3 ot,trap = control.otFixed;
    if(int(control.orbitStyle + 0.5) == 2) trap -= pos;
    
    for( int i=0; i < control.maxSteps; i++ ) {
        m = min( m, dot(pos,pos) /(k*k) );
        pos = (control.mm * float4((abs(pos)),1.0)).xyz;
        
        r = dot(pos,pos);
        if(r > 1) break;
        
        k *= control.cw;

        ot = pos;
        if(control.orbitStyle > 0) ot -= trap;
        orbitTrap = min(orbitTrap, float4(abs(ot), dot(ot,ot)));
    }
    
    float d = (length(pos)-0.5)/k;
    return d * 0.25;
}

//MARK: - 8
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

float DE_KALI_TOWER(float3 pos,device Control &control,thread float4 &orbitTrap) {
    float aa = smoothstep(0.,1.,clamp(cos(control.cy - pos.y * 0.4)*1.5,0.,1.)) * PI;
    float4 p = float4(pos,1);
    
    p.y -= control.cy * 0.25;
    p.y = abs(3.-fract((p.y - control.cy) / 2));
    
    float3 ot,trap = control.otFixed;
    if(int(control.orbitStyle + 0.5) == 2) trap -= pos;
    
    for (int i=0; i < control.maxSteps; i++) {
        p.xyz = abs(p.xyz) - float3(.0,control.cx,.0);
        p = p * 2./clamp(dot(p.xyz,p.xyz),.3,1.) - float4(0.5,1.5,0.5,0.);
        
        p = rotateXZ(p,aa * control.cz);
        
        ot = p.xyz;
        if(control.orbitStyle > 0) ot -= trap;
        orbitTrap = min(orbitTrap, float4(abs(ot), dot(ot,ot)));
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

//MARK: - 9
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

float DE_POLY_MENGER(float3 p,device Control &control,thread float4 &orbitTrap) {
    float nIt = 9.69;
    float sclFac = control.cy;
    float3 b = (sclFac - 1) * float3(0.8, 1., 0.5) * (1. + 0.03 * sin (float3(1.23, 1., 1.43)));
    p = DodecSym(p,control);
    p.z += 0.6 * (1. + b.z);
    p.xy /= 1. - control.cz * p.z;

    float3 ot,trap = control.otFixed;
    if(int(control.orbitStyle + 0.5) == 2) trap -= p;
    
    for (float n = 0.; n < nIt; n ++) {
        p = abs (p);
        p.xy = (p.x > p.y) ? p.xy : p.yx;
        p.xz = (p.x > p.z) ? p.xz : p.zx;
        p.yz = (p.y > p.z) ? p.yz : p.zy;
        p = sclFac * p - b;
        p.z += b.z * step (p.z, -0.5 * b.z);
        
        ot = p;
        if(control.orbitStyle > 0) ot -= trap;
        orbitTrap = min(orbitTrap, float4(abs(ot), dot(ot,ot)));
    }

    return 0.8 * PrBoxDf (p, float3 (1.)) / pow (sclFac, nIt);
}

//MARK: - 10
float DE_GOLD(float3 p,device Control &control,thread float4 &orbitTrap) {
    p.xz = mod(p.xz + 1.0, 2.0) - 1.0;
    float4 q = float4(p, 1);
    float3 offset1 = float3(control.cx, control.cy, control.cz);
    float4 offset2 = float4(control.cw, control.dx, control.dy, control.dz);

    float3 ot,trap = control.otFixed;
    if(int(control.orbitStyle + 0.5) == 2) trap -= p;
    
    for(int n = 0; n < control.maxSteps; ++n) {
        q.xyz = abs(q.xyz) - offset1;
        q = 2.0*q/clamp(dot(q.xyz, q.xyz), 0.4, 1.0) - offset2;
        
        ot = q.xyz;
        if(control.orbitStyle > 0) ot -= trap;
        orbitTrap = min(orbitTrap, float4(abs(ot), dot(ot,ot)));
    }
    
    return length(q.xyz)/q.w;
}

//MARK: - 11
float smax(float a, float b, float s) { // iq smin
    float h = clamp( 0.5 + 0.5*(a-b)/s, 0.0, 1.0 );
    return mix(b, a, h) + h*(1.0-h)*s;
}

float DE_SPIDER(float3 p,device Control &control,thread float4 &orbitTrap) {
    float q = sin(p.z * control.cx) * control.cy * 10 + 0.6;
    float t = length(p.xy);
    float s = 1.0;
    
    float3 ot,trap = control.otFixed;
    if(int(control.orbitStyle + 0.5) == 2) trap -= p;
    
    for(int i = 0; i < 2; ++i) {
        float m = dot(p,p);
        p = abs(fract(p/m)-0.5);
        p = rotatePosition(p,0,q);
        s *= m;

        ot = p;
        if(control.orbitStyle > 0) ot -= trap;
        orbitTrap = min(orbitTrap, float4(abs(ot), dot(ot,ot)));
    }
    
    float d = (length(p.xz) - control.cz) * s;
    return smax(d,-t, 0.3);
}

//MARK: - 12
float DE_KLEINIAN2(float3 pos,device Control &control,thread float4 &orbitTrap) {
    float k, scale = 1;

    float3 ot,trap = control.otFixed;
    if(int(control.orbitStyle + 0.5) == 2) trap -= pos;
    
    for(int i=0; i < control.maxSteps; ++i) {
        pos = 2 * clamp(pos, control.mins.xyz, control.maxs.xyz) - pos;
        k = max(control.mins.w / dot(pos,pos), control.power);
        pos *= k;
        scale *= k;

        ot = pos;
        if(control.orbitStyle > 0) ot -= trap;
        orbitTrap = min(orbitTrap, float4(abs(ot), dot(ot,ot)));
    }

    float rxy = length(pos.xy);
    return .7 * max(rxy - control.maxs.w, rxy * pos.z / length(pos)) / scale;
}

//MARK: - 13
float DE_KIFS(float3 pos,device Control &control,thread float4 &orbitTrap) {
    float4 z = float4(pos,1.0);
    float3 offset = float3(control.cx,1.1,0.5);
    float scale = control.cy;
    float q;
    
    float3 ot,trap = control.otFixed;
    if(int(control.orbitStyle + 0.5) == 2) trap -= pos;
    
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

        ot = z.xyz;
        if(control.orbitStyle > 0) ot -= trap;
        orbitTrap = min(orbitTrap, float4(abs(ot), dot(ot,ot)));
    }
    
    return(length(max(abs(z.xyz)-float3(1.0),0.0))-0.05)/z.w;
}

//MARK: - 14
float DE_IFS_TETRA(float3 pos,device Control &control,thread float4 &orbitTrap) {
    int n = 0;

    float3 ot,trap = control.otFixed;
    if(int(control.orbitStyle + 0.5) == 2) trap -= pos;
    
    while(n < 25) {
        pos = rotatePosition(pos,0,control.angle1);
        
        if(pos.x +pos.y < 0.0) pos.xy = -pos.yx;
        if(pos.x +pos.z < 0.0) pos.xz = -pos.zx;
        if(pos.y +pos.z < 0.0) pos.zy = -pos.yz;
        
        pos = pos * control.cx - float3(1,1,1) * (control.cx - 1.0);
        pos = rotatePosition(pos,1,control.angle2);
        
        ot = pos;
        if(control.orbitStyle > 0) ot -= trap;
        orbitTrap = min(orbitTrap, float4(abs(ot), dot(ot,ot)));

        n++;
    }
    
    return 0.55 * length(pos) * pow(control.cx, -float(n));
}

//MARK: - 15
float DE_IFS_OCTA(float3 pos,device Control &control,thread float4 &orbitTrap) {
    int n = 0;

    float3 ot,trap = control.otFixed;
    if(int(control.orbitStyle + 0.5) == 2) trap -= pos;
    
    while(n < 18) {
        pos = rotatePosition(pos,0,control.angle1);
        
        if(pos.x+pos.y < 0.0) pos.xy = -pos.yx;
        if(pos.x+pos.z < 0.0) pos.xz = -pos.zx;
        if(pos.x-pos.y < 0.0) pos.xy = pos.yx;
        if(pos.x-pos.z < 0.0) pos.xz = pos.zx;
        
        pos = pos * control.cx - float3(1,0,0) * (control.cx - 1.0);
        pos = rotatePosition(pos,1,control.angle2);

        ot = pos;
        if(control.orbitStyle > 0) ot -= trap;
        orbitTrap = min(orbitTrap, float4(abs(ot), dot(ot,ot)));

        n++;
    }
    
    return 0.55 * length(pos) * pow(control.cx, -float(n));
}

//MARK: - 16
float DE_IFS_DODEC(float3 pos,device Control &control,thread float4 &orbitTrap) {
    int n = 0;
    float d;

    float3 ot,trap = control.otFixed;
    if(int(control.orbitStyle + 0.5) == 2) trap -= pos;
    
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
        
        d = dot(pos,pos);
        if(d > 12) break;
        
        ot = pos;
        if(control.orbitStyle > 0) ot -= trap;
        orbitTrap = min(orbitTrap, float4(abs(ot), d));

        n++;
    }
    
    return 0.35 * length(pos) * pow(control.cx,float(-n-1));
}

//MARK: - 17
float DE_IFS_MENGER(float3 pos,device Control &control,thread float4 &orbitTrap) {
    pos = pos * 0.5 + float3(0.5);
    float3 pp = abs(pos-0.5)-0.5;
    float k = 1.0;
    float d1 = max(pp.x,max(pp.y,pp.z));
    float d = d1;
    
    float3 ot,trap = control.otFixed;
    if(int(control.orbitStyle + 0.5) == 2) trap -= pos;
    
    for(int i = 0; i < control.maxSteps; ++i) {
        float3 posa = mod(3.0 * pos * k, 3.0);
        k *= control.cx;
        
        pp = 0.5-abs(posa-1.5) + float3(control.cy);
        pp = rotatePosition(pp,0,control.angle1);
        d1 = min(max(pp.x,pp.z),min(max(pp.x,pp.y),max(pp.y,pp.z)))/k;
        d = max(d,d1);
        
        ot = pp;
        if(control.orbitStyle > 0) ot -= trap;
        orbitTrap = min(orbitTrap, float4(abs(ot), dot(ot,ot)));
    }
    
    return d;
}

//MARK: - 18
float DE_SIERPINSKI_T(float3 pos,device Control &control,thread float4 &orbitTrap) {
    int i;

    float3 ot,trap = control.otFixed;
    if(int(control.orbitStyle + 0.5) == 2) trap -= pos;
    
    for(i=0;i < control.maxSteps; ++i) {
        pos = rotatePosition(pos,0,control.angle1);

        if(pos.x + pos.y < 0.0) pos.xy = -pos.yx;
        if(pos.x + pos.z < 0.0) pos.xz = -pos.zx;
        if(pos.y + pos.z < 0.0) pos.zy = -pos.yz;

        pos = rotatePosition(pos,1,control.angle2);
        pos = pos * control.cx - control.n1 * (control.cx - 1.0);
        if(length(pos) > 4) break;
        
        ot = pos;
        if(control.orbitStyle > 0) ot -= trap;
        orbitTrap = min(orbitTrap, float4(abs(ot), dot(ot,ot)));
    }
    
    return (length(pos) - 2) * pow(control.cx, -float(i));
}

//MARK: - 19
float DE_HALF_TETRA(float3 pos,device Control &control,thread float4 &orbitTrap) {
    int i;
    
    float3 ot,trap = control.otFixed;
    if(int(control.orbitStyle + 0.5) == 2) trap -= pos;
    
    for(i=0;i < control.maxSteps; ++i) {
        pos = rotatePosition(pos,0,control.angle1);
        
        if(pos.x - pos.y < 0.0) pos.xy = pos.yx;
        if(pos.x - pos.z < 0.0) pos.xz = pos.zx;
        if(pos.y - pos.z < 0.0) pos.zy = pos.yz;
        
        pos = rotatePosition(pos,2,control.angle2);
        pos = pos * control.cx - control.n1 * (control.cx - 1.0);
        if(length(pos) > 4) break;

        ot = pos;
        if(control.orbitStyle > 0) ot -= trap;
        orbitTrap = min(orbitTrap, float4(abs(ot), dot(ot,ot)));
    }
    
    return (length(pos) - 2) * pow(control.cx, -float(i));
}

//MARK: - 20
float DE_FULL_TETRA(float3 pos,device Control &control,thread float4 &orbitTrap) {
    int i;
    
    float3 ot,trap = control.otFixed;
    if(int(control.orbitStyle + 0.5) == 2) trap -= pos;
    
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

        ot = pos;
        if(control.orbitStyle > 0) ot -= trap;
        orbitTrap = min(orbitTrap, float4(abs(ot), dot(ot,ot)));
    }
    
    return (length(pos) - 2) * pow(control.cx, -float(i));
}

//MARK: - 21
float DE_CUBIC(float3 pos,device Control &control,thread float4 &orbitTrap) {
    int i;
    
    float3 ot,trap = control.otFixed;
    if(int(control.orbitStyle + 0.5) == 2) trap -= pos;
    
    for(i=0;i < control.maxSteps; ++i) {
        pos = rotatePosition(pos,0,control.angle1);

        pos = abs(pos);

        pos = rotatePosition(pos,1,control.angle2);
        pos = pos * control.cx - control.n1 * (control.cx - 1.0);
        if(length(pos) > 4) break;

        ot = pos;
        if(control.orbitStyle > 0) ot -= trap;
        orbitTrap = min(orbitTrap, float4(abs(ot), dot(ot,ot)));
    }
    
    return (length(pos) - 2) * pow(control.cx, -float(i));
}

//MARK: - 22
float DE_HALF_OCTA(float3 pos,device Control &control,thread float4 &orbitTrap) {
    int i;
    
    float3 ot,trap = control.otFixed;
    if(int(control.orbitStyle + 0.5) == 2) trap -= pos;
    
    for(i=0;i < control.maxSteps; ++i) {
        pos = rotatePosition(pos,0,control.angle1);
        
        if(pos.x - pos.y < 0.0) pos.xy =  pos.yx;
        if(pos.x + pos.y < 0.0) pos.xy = -pos.yx;
        if(pos.x - pos.z < 0.0) pos.xz =  pos.zx;
        if(pos.x + pos.z < 0.0) pos.zy = -pos.yz;

        pos = rotatePosition(pos,1,control.angle2);
        pos = pos * control.cx - control.n1 * (control.cx - 1.0);
        if(length(pos) > 4) break;

        ot = pos;
        if(control.orbitStyle > 0) ot -= trap;
        orbitTrap = min(orbitTrap, float4(abs(ot), dot(ot,ot)));
    }
    
    return (length(pos) - 2) * pow(control.cx, -float(i));
}

//MARK: - 23
float DE_FULL_OCTA(float3 pos,device Control &control,thread float4 &orbitTrap) {
    int i;
    
    float3 ot,trap = control.otFixed;
    if(int(control.orbitStyle + 0.5) == 2) trap -= pos;
    
    for(i=0;i < control.maxSteps; ++i) {
        pos = rotatePosition(pos,0,control.angle1);
        
        pos = abs(pos);
        if(pos.x - pos.y < 0.0) pos.xy =  pos.yx;
        if(pos.x - pos.z < 0.0) pos.xz =  pos.zx;
        if(pos.y - pos.z < 0.0) pos.zy =  pos.yz;
        
        pos = rotatePosition(pos,1,control.angle2);
        pos = pos * control.cx - control.n1 * (control.cx - 1.0);
        if(length(pos) > 4) break;

        ot = pos;
        if(control.orbitStyle > 0) ot -= trap;
        orbitTrap = min(orbitTrap, float4(abs(ot), dot(ot,ot)));
    }
    
    return (length(pos) - 2) * pow(control.cx, -float(i));
}

//MARK: - 24
float DE_KALEIDO(float3 pos,device Control &control,thread float4 &orbitTrap) {
    int i;
    
    float3 ot,trap = control.otFixed;
    if(int(control.orbitStyle + 0.5) == 2) trap -= pos;
    
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

        ot = pos;
        if(control.orbitStyle > 0) ot -= trap;
        orbitTrap = min(orbitTrap, float4(abs(ot), dot(ot,ot)));
    }
    
    return (length(pos) - 2) * pow(control.cx, -float(i));
}

//MARK: - 25
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

float DE_POLYCHORA(float3 pos,device Control &control,thread float4 &orbitTrap) {
    float r = length(pos);
    float4 z4 = float4(2.*pos,1.-r*r)*1./(1.+r*r);//Inverse stereographic projection of pos: z4 lies onto the unit 3-sphere centered at 0.
    z4=Rotate(z4,control);//z4.xyw=rot*z4.xyw;
    z4=fold(z4,control);//fold it
    
    float3 ot,trap = control.otFixed;
    if(int(control.orbitStyle + 0.5) == 2) trap -= pos;
    
    ot = z4.xyz;
    if(control.orbitStyle > 0) ot -= trap;
    orbitTrap = min(orbitTrap, float4(abs(ot), dot(ot,ot)));

    return min(dist2Vertex(z4,r,control),dist2Segments(z4,r,control));
}

//MARK: - 26
float DE_QUADRAY(float3 pos,device Control &control,thread float4 &orbitTrap) {
    float v = control.cz;
    matrix_float3x4 mc = matrix_float3x4(float4(v,-v,-v, v), float4(v,-v, v,-v), float4(v, v,-v,-v));
    
    float4 cp = abs(mc * pos) + float4(control.cx);
    float4 z = cp;
    float r = length(z);
    int i;
    cp *= control.cy;
    matrix_float4x4 j = matrix_float4x4(1.);
    
    float3 ot,trap = control.otFixed;
    if(int(control.orbitStyle + 0.5) == 2) trap -= pos;
    
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
        
        ot = z.xyz;
        if(control.orbitStyle > 0) ot -= trap;
        orbitTrap = min(orbitTrap, float4(abs(ot), dot(ot,ot)));
    }

    j[0]=abs(j[0]); j[1]=abs(j[1]); j[2]=abs(j[2]); j[3]=abs(j[3]);
    z = j * float4(1.,1.,1.,1.);
    z.xy = max(z.xy,z.zw);
    float dr = max(z.x,z.y);
    
    return 5 * r * log(r) / dr;
}

//MARK: - 27
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
float mandelDE(float3 pos,device Control &control,thread float4 &orbitTrap) {
    float3 z=pos;
    float r;
    float dr=1.0;
    int i=0;
    r=length(z);

    float3 ot,trap = control.otFixed;
    if(int(control.orbitStyle + 0.5) == 2) trap -= pos;

    while(r < 8 && (i < control.maxSteps)) {
        if(control.AlternateVersion) {
            z = powN2(z,r,dr,control);
        } else {
            z = powN1(z,r,dr,control);
        }
        
        z += (control.juliaboxMode ? control.julia : pos);
        r=length(z);
        z = rotatePosition(z,0,control.angle1);
        
        ot = z;
        if(control.orbitStyle > 0) ot -= trap;
        orbitTrap = min(orbitTrap, float4(abs(ot), dot(ot,ot)));

        i++;
    }
    
    return 0.5*log(r)*r/dr;
}

// knighty's Menger-Sphere
float mengersDE(float3 pos,device Control &control,thread float4 &orbitTrap) {
    float3 ap=abs(pos);
    float Linf=max(max(ap.x,ap.y),ap.z);//infinity norm
    float L2=length(pos);//euclidean norm
    float multiplier = control.cx * L2/Linf;
    pos *= multiplier;//Spherify transform.
    float dd = multiplier; // * 1.6;//to correct the DE. Found by try and error. there should be better formula.
    float r2 = dot(pos,pos);

    float3 ot,trap = control.otFixed;
    if(int(control.orbitStyle + 0.5) == 2) trap -= pos;
    
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
        
        ot = pos;
        if(control.orbitStyle > 0) ot -= trap;
        orbitTrap = min(orbitTrap, float4(abs(ot), dot(ot,ot)));
    }

    return (sqrt(r2) - control.sr)/dd;//bounding volume is a sphere
}

float mandelboxDE(float3 pos,device Control &control,thread float4 &orbitTrap) {
    float4 p = float4(pos,1.), p0 = p;  // p.w is the distance estimate
    
    float3 ot,trap = control.otFixed;
    if(int(control.orbitStyle + 0.5) == 2) trap -= pos;
    
    for(int i=0; i < control.mbIterations; ++i) {
        float3 temp = p.xyz;
        p.xyz = rotatePosition(temp,0,control.angle1);
        p.xyz = clamp(p.xyz, -1.0, 1.0) * 2.0 - p.xyz;  // min;max;mad
        float r2 = dot(p.xyz, p.xyz);
        p *= clamp(max(control.mbMinRad2/r2, control.mbMinRad2), 0.0, 1.0);  // dp3,div,max.sat,mul
        p = p * control.mbScale + p0;
        if( r2>1000.0) break;
        
        ot = p.xyz;
        if(control.orbitStyle > 0) ot -= trap;
        orbitTrap = min(orbitTrap, float4(abs(ot), dot(ot,ot)));
    }
    
    return ((length(p.xyz) - control.absScalem1) / p.w - control.AbsScaleRaisedTo1mIters);
}

float DE_FRAGM(float3 pos,device Control &control,thread float4 &orbitTrap) {
    float rd = 0;
    if(control.maxSteps > 0) rd = mandelDE(abs(pos),control,orbitTrap);
    if(control.msIterations > 0) rd += mengersDE(abs(pos),control,orbitTrap);
    if(control.mbIterations > 0) rd += mandelboxDE(abs(pos),control,orbitTrap);

    return rd;
};

//MARK: - 28
float4 stereographic3Sphere(float3 pos,device Control &control) {
    float n = dot(pos,pos)+1.;
    return float4(control.cx * pos,n-2.) / n;
}

float2 complexMul(float2 a, float2 b) { return float2(a.x*b.x - a.y*b.y, a.x*b.y + a.y * b.x); }

float DE_QUATJULIA2(float3 pos,device Control &control,thread float4 &orbitTrap) {
    float4 p4 = stereographic3Sphere(pos,control);
    
    p4.xyz += control.julia;    // "offset"

    float2 p = p4.xy;
    float2 c = p4.zw;
    float dp = 1.0;
    float d;
    
    float3 ot,trap = control.otFixed;
    if(int(control.orbitStyle + 0.5) == 2) trap -= pos;
    
    for (int i = 0; i < control.maxSteps; ++i) {
        dp = 2.0 * length(p) * dp + 1.0;
        p = complexMul(p,p) + c;
        
        d = dot(p,p);
        if(d > 10) break;
        
        ot = float3(p,1);
        if(control.orbitStyle > 0) ot -= trap;
        orbitTrap = min(orbitTrap, float4(abs(ot), dot(ot,ot)));
    }
    
    float r = length(p);
    return r * log(r) / abs(dp);
}

//MARK: - 29
float DE_MBROT(float3 pos,device Control &control,thread float4 &orbitTrap) {
    float4 p = float4(pos, control.cx);
    float4 dp = float4(1.0, 0.0,0.0,0.0);

    p.yzw = rotatePosition(p.yzw,0,control.julia.x);
    p.yzw = rotatePosition(p.yzw,1,control.julia.y);
    p.yzw = rotatePosition(p.yzw,2,control.julia.z);
    
    float3 ot,trap = control.otFixed;
    if(int(control.orbitStyle + 0.5) == 2) trap -= pos;
    
    for (int i = 0; i < control.maxSteps;++i) {
        dp = 2.0 * float4(p.x * dp.x-dot(p.yzw, dp.yzw), p.x*dp.yzw+dp.x*p.yzw + cross(p.yzw, dp.yzw));
        p = float4(p.x * p.x - dot(p.yzw, p.yzw), float3(2.0 *p.x * p.yzw)) + float4(pos, 0.0);
        
        float p2 = dot(p,p);
        if(p2 > 10) break;

        ot = p.xyz;
        if(control.orbitStyle > 0) ot -= trap;
        orbitTrap = min(orbitTrap, float4(abs(ot), dot(ot,ot)));
    }
    
    float r = length(p);
    return 0.2 * r * log(r) / length(dp);
}

//MARK: - 30
float DE_KALIBOX(float3 pos,device Control &control,thread float4 &orbitTrap) {
    float4 p = float4(pos,1), p0 = float4(control.julia,1);  // p.w is the distance estimate
    
    float3 ot,trap = control.otFixed;
    if(int(control.orbitStyle + 0.5) == 2) trap -= pos;
    
    for (int i = 0; i < control.maxSteps;++i) {
        
        // p.xyz*=rot;
        p.xyz = rotatePosition(p.xyz,0,control.angle1);
        p.xyz = rotatePosition(p.xyz,1,control.angle1);

        p.xyz = abs(p.xyz) + control.n1;
        float r2 = dot(p.xyz, p.xyz);
        p *= clamp(max(control.cy/r2, control.cy), 0.0, 1.0);  // dp3,div,max.sat,mul
        p = p * control.mins + (control.juliaboxMode ? p0 : float4(0.0));
        
        ot = p.xyz;
        if(control.orbitStyle > 0) ot -= trap;
        orbitTrap = min(orbitTrap, float4(abs(ot), dot(ot,ot)));
    }
    
    return ((length(p.xyz) - control.absScalem1) / p.w - control.AbsScaleRaisedTo1mIters);
}

//MARK: - 31
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

float DE_SPUDS(float3 pos,device Control &control,thread float4 &orbitTrap) {
    int n = 0;
    float dz = 1.0;
    float r = length(pos);
    
    float3 ot,trap = control.otFixed;
    if(int(control.orbitStyle + 0.5) == 2) trap -= pos;
    
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
        
        ot = pos;
        if(control.orbitStyle > 0) ot -= trap;
        orbitTrap = min(orbitTrap, float4(abs(ot), dot(ot,ot)));

        n++;
    }
    
    return r * log(r) / dz;
}

//MARK: - 32
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

float DE_MPOLY(float3 pos,device Control &control,thread float4 &orbitTrap) {
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
    
    float3 ot,trap = control.otFixed;
    if(int(control.orbitStyle + 0.5) == 2) trap -= pos;
    
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
        
        ot = pos;
        if(control.orbitStyle > 0) ot -= trap;
        orbitTrap = min(orbitTrap, float4(abs(ot), dot(ot,ot)));

        w = w * sc;
    }

    return abs(length(pos)) / w;
}

//MARK: - 33
float mHelixPrBoxDf(float3 p, float3 b) {
    float3 d = abs(p) - b;
    return min (max (d.x, max (d.y, d.z)), 0.) + length (max (d, 0.));
}

float2 mHelixRot2D(float2 q, float a) {
    float2 cs = sin(a + float2(0.5 * PI, 0.));
    return float2(dot (q, float2 (cs.x, - cs.y)), dot (q.yx, cs));
}

float DE_MHELIX(float3 pos,device Control &control,thread float4 &orbitTrap) {
#define sclFac control.cx
#define nIt 5.0

    float3 b;
    float r, a;
    
    b = (sclFac - 1.) * control.julia;
    pos.xz = mHelixRot2D(pos.xz, control.angle1);
    r = length (pos.xz);
    a = (r > 0.) ? atan2(pos.z, - pos.x) / (2. * PI) : 0.;
    
    if(control.gravity) pos.y = mod (pos.y - 4. * a + 2., 4.) - 2.;
    pos.x = mod (16. * a + 1., 2.) - 1.;
    pos.z = r - 32. / (2. * PI);

    if(control.gravity)
        pos.yz = Rot2D (pos.yz, 2. * PI * a);
    else
        pos.yz = Rot2D (pos.yz, PI * a);

    float3 ot,trap = control.otFixed;
    if(int(control.orbitStyle + 0.5) == 2) trap -= pos;
    
    for (float n = 0.; n < control.fMaxSteps; n++) {
        pos = abs(pos);
        pos.xy = (pos.x > pos.y) ? pos.xy : pos.yx;
        pos.xz = (pos.x > pos.z) ? pos.xz : pos.zx;
        pos.yz = (pos.y > pos.z) ? pos.yz : pos.zy;
        pos = sclFac * pos - b;
        pos.z += b.z * step(pos.z, -0.5 * b.z);
        
        ot = pos;
        if(control.orbitStyle > 0) ot -= trap;
        orbitTrap = min(orbitTrap, float4(abs(ot), dot(ot,ot)));
    }
    
    return 0.8 * mHelixPrBoxDf(pos, float3(1.)) / pow(sclFac, nIt);
}

//MARK: - 34
float DE_FLOWER(float3 pos,device Control &control,thread float4 &orbitTrap) {
    float4 q = float4(pos, 1);
    float4 juliaOffset = float4(control.julia,0);
    
    float3 ot,trap = control.otFixed;
    if(int(control.orbitStyle + 0.5) == 2) trap -= pos;
    
    for(int i = 0; i < control.maxSteps; ++i) { //kaliset fractal with no mirroring offset
        q.xyz = abs(q.xyz);
        float r = dot(q.xyz, q.xyz);
        q /= clamp(r, 0.0, control.cx);
        
        q = 2.0 * q - juliaOffset;
        
        ot = q.xyz;
        if(control.orbitStyle > 0) ot -= trap;
        orbitTrap = min(orbitTrap, float4(abs(ot), dot(ot,ot)));
    }
    
    return (length(q.xy)/q.w - 0.003); // cylinder primative instead of a sphere primative.
}

//MARK: - 35
float pattern(float2 p) {
    return abs(sin(p.x) + sin(p.y));
}

float boxmap(float3 p) {
    p *= 0.3;
    float3 m = pow(abs(normalize(p)), float3(20));
    float3 a = float3(pattern(p.yz),pattern(p.zx),pattern(p.xy));
    return dot(a,m)/(m.x+m.y+m.z);
}

float3 smin(float3 a, float3 b) {
    float k = 0.08;
    float3 h = clamp( 0.5 + 0.5*(b-a)/k, 0.0, 1.0 );
    return mix( b, a, h ) - k*h*(1.0-h);
}

float3 sabs(float3 p) {
    return  p - 2.0 * smin(float3(0), p);
}

float DE_JUNGLE(float3 pos,device Control &control,thread float4 &orbitTrap) {
    float s = control.cx;
    float amp = 1.0/s;
    float c = control.cy;
    pos = sabs(mod(pos, c * control.cw) - c);
    float de = 100.;
    
    float3 ot,trap = control.otFixed;
    if(int(control.orbitStyle + 0.5) == 2) trap -= pos;
    
    for(int i=0; i< control.maxSteps; ++i) {
        pos = sabs(pos);
        pos *= s;
        pos -= float3(0.2 * pos.z, 0.6 * pos.x, 0.4) * (s - 1.0);
        de = abs(length(pos * amp) - 0.2) ;
        amp /= s;
        
        ot = pos;
        if(control.orbitStyle > 0) ot -= trap;
        orbitTrap = min(orbitTrap, float4(abs(ot), dot(ot,ot)));
    }
    
    return de + boxmap(pos * control.cz) * 0.02 - 0.01;
}

//MARK: - 36
float opS(float d1, float d2) { return (-d2>d1)? -d2:d1; }

float sdBox(float3 p, float3 b) {
    float3 d = abs(p) - b;
    return min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0));
}

float shBox(float3 p, float3 b,float thickness) {
    float dist = opS(sdBox(p,b),sdBox(p+float3(0.0,-p.y,0.0),b/thickness));
    dist = opS(dist,sdBox(p+float3(0.0,p.y,0.0),b/thickness));
    dist = opS(dist,sdBox(p+float3(p.x,0.0,0.0),b/thickness));
    dist = opS(dist,sdBox(p+float3(-p.x,0.0,0.0),b/thickness));
    dist = opS(dist,sdBox(p+float3(0.0,0.0,p.z),b/thickness));
    dist = opS(dist,sdBox(p+float3(0.0,0.0,-p.z),b/thickness));
    return dist;
}

float DE_PRISONER(float3 pos,device Control &control,thread float4 &orbitTrap) {
    float dr = 1.0;
    float3 w = pos;
    float wo,wi,wr,ot=1;
    float pwr2 = control.power - 1;
    
    w = rotatePosition(w,2,control.angle1);

    float3 ott,trap = control.otFixed;
    if(int(control.orbitStyle + 0.5) == 2) trap -= pos;
    
    for(int i=0; i< control.maxSteps; ++i) {
        wr = length(w);
        if(wr*wr > 2) {
            ot = float(i);
            break;
        }

        dr = control.power * pow(wr,pwr2) * dr + 1;

        wo = acos(w.y/wr) * pwr2;
        wi = atan2(w.x,w.z) * pwr2;

        wr = pow(wr, pwr2);

        w.x = wr * sin(wo)*sin(wi);
        w.y = wr * cos(wo);
        w.z = wr * sin(wo)*cos(wi);
        
        w += pos;
        
        ott = w;
        if(control.orbitStyle > 0) ott -= trap;
        orbitTrap = min(orbitTrap, float4(abs(ott), dot(ott,ott)));
    }
    
    if(wr*wr <= 14) {
        float bboy1 = shBox(w, float3(control.cx),control.cy) * pow(20.0,-ot);
        float bboy2 = 0.5 * log(wr)*wr/dr;
        
        if(bboy1 < bboy2) return bboy1;
        return bboy2;
    }
    
   return 0.4 * log(wr) * wr/dr;
}

//MARK: - 37
float DE_SPIRALBOX(float3 pos,device Control &control,thread float4 &orbitTrap) {
    float3 z = pos;
    float r,DF = 1.0;
    float3 offset = (control.juliaboxMode ? control.julia/10 : pos);
    
    float3 ot,trap = control.otFixed;
    if(int(control.orbitStyle + 0.5) == 2) trap -= pos;
    
    for(int i=0; i < control.maxSteps; ++i) {
        z.xyz = clamp(z.xyz, -control.cx, control.cx)*2. - z.xyz;
        
        r = dot(z,z);
        if (r< 0.001 || r> 1000.) break;
        
        z/=-r;
        DF/= r;
        z.xz *= -1.;
        z += offset;
        
        ot = z;
        if(control.orbitStyle > 0) ot -= trap;
        orbitTrap = min(orbitTrap, float4(abs(ot), dot(ot,ot)));
    }
    
    r = length(z);
    return 0.5 * sqrt(0.1*r) / (abs(DF)+1.);
}

//MARK: - 38
float DE_ALEK_BULB(float3 pos,device Control &control,thread float4 &orbitTrap) {
    float dr = 1;
    float r,mcangle,theta,pwr;
    
    float3 ot,trap = control.otFixed;
    if(int(control.orbitStyle + 0.5) == 2) trap -= pos;
    
    for(int i=0; i < control.maxSteps; ++i) {
        r = length(pos);
        if(r > 8) break;
        
        mcangle = abs(pos.y) / pos.x;
        mcangle = atan(mcangle);
        mcangle = (PI*0.5 - PI*abs(pos.x)* 0.5/pos.x + mcangle ) * control.power;
        
        theta = acos(pos.z/r) * control.power;

        pwr = pow(r, control.power);
        pos.x = pwr * cos(mcangle) * sin(theta);
        pos.y = pwr * sin(mcangle) * sin(theta) * abs(pos.y)/pos.y;
        pos.z = pwr * cos(theta);
        
        pos += control.julia;

        dr = (pow(r, control.power - 1.0) * control.power * dr ) + 1.0;
        
        ot = pos;
        if(control.orbitStyle > 0) ot -= trap;
        orbitTrap = min(orbitTrap, float4(abs(ot), dot(ot,ot)));
    }
    
    return 0.5 * log(r) * r/dr;
}

//MARK: - 39
float surfBoxFold(float v, float fold, float foldModX) {
    float sg = sign(v);
    float folder = sg * v - fold; // fold is Tglad's
    folder += abs(folder);
    folder = min(folder, foldModX); // and Y,Z,W
    v -= sg * folder;
    
    return v;
}

float DE_SURFBOX(float3 pos,device Control &control,thread float4 &orbitTrap) {
    float3 c = control.juliaboxMode ? control.julia : pos;
    float r2,dr = control.power;
    float fR2 = control.cz * control.cz;
    float mR2 = control.cw * control.cw;
    
    float3 ot,trap = control.otFixed;
    if(int(control.orbitStyle + 0.5) == 2) trap -= pos;
    
    for(int i = 0; i < control.maxSteps; ++i) {
        pos.x = surfBoxFold(pos.x,control.cx,control.dx);
        pos.y = surfBoxFold(pos.y,control.cx,control.dx);
        pos.z = surfBoxFold(pos.z,control.cx,control.dx);
        
        r2 = pos.x*pos.x + pos.y*pos.y + pos.z*pos.z;
        
        if(r2 < mR2) {
            float temp = fR2 / mR2;
            pos *= temp;
            dr *= temp;
        }
        else if(r2 < fR2) {
            float temp = fR2 / r2;
            pos *= temp;
            dr *= temp;
        }
        
        pos = pos * control.power + c;
        dr *= control.power;
        
        ot = pos;
        if(control.orbitStyle > 0) ot -= trap;
        orbitTrap = min(orbitTrap, float4(abs(ot), dot(ot,ot)));
    }
    
    return length(pos)/abs(dr);
}

//MARK: - 40
float DE_TWISTBOX(float3 pos,device Control &control,thread float4 &orbitTrap) {
    float3 c = control.juliaboxMode ? control.julia : pos;
    float r,DF = control.power;
    
    float3 ot,trap = control.otFixed;
    if(int(control.orbitStyle + 0.5) == 2) trap -= pos;
    
    for(int i = 0; i < control.maxSteps; ++i) {
        pos = clamp(pos, -control.cx,control.cx)*2 - pos;
        
        r = dot(pos,pos);
        if(r< 0.001 || r> 1000.) break;
        pos/=-r;
        DF/= r;
        pos.xz *= -1;
        pos += c;
        
        ot = pos;
        if(control.orbitStyle > 0) ot -= trap;
        orbitTrap = min(orbitTrap, float4(abs(ot), dot(ot,ot)));
    }
    
    r = length(pos);
    return 0.5 * sqrt(r)/(abs(DF)+1);
}

//MARK: - 41
float DE_KALI_RONTGEN(float3 pos,device Control &control,thread float4 &orbitTrap) {
    float d = 10000.;
    float4 p = float4(pos, 1.);
    float3 param = float3(control.cx,control.cy,control.cz);
    
    float3 ot,trap = control.otFixed;
    if(int(control.orbitStyle + 0.5) == 2) trap -= pos;
    
    for(int i = 0; i < control.maxSteps; ++i) {
        p = abs(p) / dot(p.xyz, p.xyz);
        
        d = min(d, (length(p.xy - float2(0,.01))-.03) / p.w);
        if(d > 4) break;
        
        p.xyz -= param;
        p.xyz = rotatePosition(p.xyz,1,control.angle1);
        
        ot = p.xyz;
        if(control.orbitStyle > 0) ot -= trap;
        orbitTrap = min(orbitTrap, float4(abs(ot), dot(ot,ot)));
    }

    return d;
}

//MARK: - 42
float DE_VERTEBRAE(float3 pos,device Control &control,thread float4 &orbitTrap) {
    #define scalelogx  control.dx
    #define scalelogy  control.dy
    #define scalelogz  control.dz
    #define scalesinx  control.dw
    #define scalesiny  control.ex
    #define scalesinz  control.ey
    #define offsetsinx control.ez
    #define offsetsiny control.ew
    #define offsetsinz control.fx
    #define slopesinx  control.fy
    #define slopesiny  control.fz
    #define slopesinz  control.fw
    float4 c = 0.5 * float4(control.cx, control.cy, control.cz, control.cw);
    float4 nz;
    float md2 = 1.0;
    float4 z = float4(pos,0);
    float mz2 = dot(z,z);
    
    float3 ot,trap = control.otFixed;
    if(int(control.orbitStyle + 0.5) == 2) trap -= pos;
    
    for(int i=0;i < control.maxSteps; ++i) {
        md2 *= 4.0 * mz2;
        nz.x = z.x * z.x - dot(z.yzw,z.yzw);
        nz.yzw = 2.0 * z.x * z.yzw;
        z = nz+c;
        
        z.x = scalelogx*log(z.x + sqrt(z.x*z.x + 1.));
        z.y = scalelogy*log(z.y + sqrt(z.y*z.y + 1.));
        z.z = scalelogz*log(z.z + sqrt(z.z*z.z + 1.));
        z.x = scalesinx*sin(z.x + offsetsinx)+(z.x*slopesinx);
        z.y = scalesiny*sin(z.y + offsetsiny)+(z.y*slopesiny);
        z.z = scalesinz*sin(z.z + offsetsinz)+(z.z*slopesinz);
        
        mz2 = dot(z,z);
        if(mz2 > 12.0) break;
        
        ot = z.xyz;
        if(control.orbitStyle > 0) ot -= trap;
        orbitTrap = min(orbitTrap, float4(abs(ot), dot(ot,ot)));
    }
    
    return 0.3 * sqrt(mz2/md2) * log(mz2);
}

//MARK: - 43
float DE_DARKSURF(float3 pos,device Control &control,thread float4 &orbitTrap) {
#define scale_43 control.cx
#define MinRad2_43 control.cy
#define Scale_43 control.cz
#define fold_43 control.n1
#define foldMod_43 control.n2
    float absScalem1 = abs(Scale_43 - 1.0);
    float AbsScaleRaisedTo1mIters = pow(abs(Scale_43), float(1-control.maxSteps));
    
    float4 p = float4(pos,1), p0 = p;  // p.w is the distance estimate
    
    float3 ot,trap = control.otFixed;
    if(int(control.orbitStyle + 0.5) == 2) trap -= pos;
    
    for(int i=0;i < control.maxSteps; ++i) {
        p.xyz = rotatePosition(p.xyz,0,control.angle1);
        p.xyz = rotatePosition(p.xyz,1,control.angle1);

        //dark-beam's surfboxfold ported by mclarekin-----------------------------------
        float3 sg = p.xyz; // or 0,0,0
        sg.x = sign(p.x);
        sg.y = sign(p.y);
        sg.z = sign(p.z);
        
        float3 folder = p.xyz; // or 0,0,0
        float3 Tglad = abs(p.xyz + fold_43) - abs(p.xyz - fold_43) - p.xyz;
        
        folder.x = sg.x * (p.x - Tglad.x);
        folder.y = sg.y * (p.y - Tglad.y);
        folder.z = sg.z * (p.z - Tglad.z);
        
        folder = abs(folder);
        
        folder.x = min(folder.x, foldMod_43.x);
        folder.y = min(folder.y, foldMod_43.y);
        folder.z = min(folder.z, foldMod_43.z);
        
        p.x -= sg.x * folder.x;
        p.y -= sg.y * folder.y;
        p.z -= sg.z * folder.z;
        //----------------------------------------------------------
        
        float r2 = dot(p.xyz, p.xyz);
        p *= clamp(max(MinRad2_43/r2, MinRad2_43), 0.0, 1.0);
        p = p * scale_43 + p0;
        if ( r2>1000.0) break;
        
        ot = p.xyz;
        if(control.orbitStyle > 0) ot -= trap;
        orbitTrap = min(orbitTrap, float4(abs(ot), dot(ot,ot)));
    }

    return ((length(p.xyz) - absScalem1) / p.w - AbsScaleRaisedTo1mIters);
}

//MARK: - 44
void BuffaloIteration(thread float3 &z, float r, thread float &r_dz,device Control &control) {
    #define power44 control.cy
    r_dz = r_dz * 2 * r;
    
    if (control.preabsx) z.x = abs(z.x);
    if (control.preabsy) z.y = abs(z.y);
    if (control.preabsz) z.z = abs(z.z);
    
    float x2 = z.x * z.x;
    float y2 = z.y * z.y;
    float z2 = z.z * z.z;
    float temp = 1.0 - (z2 / (x2 + y2));
    float newx = (x2 - y2) * temp;
    float newy = power44 * z.x * z.y * temp;
    float newz = -power44 * z.z * sqrt(x2 + y2);
    
    z.x = control.absx ? abs(newx) : newx;
    z.y = control.absy ? abs(newy) : newy;
    z.z = control.absz ? abs(newz) : newz;
}

#define Bailout 4.0

// Compute the distance from `pos` to the bulb.
float3 DE1(float3 pos,device Control &control,thread float4 &orbitTrap) {
    float3 z=pos;
    float r = length(z);
    float dr=1.0;
    int i=0;
    
    float3 ot,trap = control.otFixed;
    if(int(control.orbitStyle + 0.5) == 2) trap -= pos;
    
    while(r<Bailout && (i<control.maxSteps)) {
        BuffaloIteration(z,r,dr,control);
        z+=(control.juliaboxMode ? control.julia : pos);
        r=length(z);
        
        z = rotatePosition(z,1,control.angle1);
        z = rotatePosition(z,2,control.angle1);
        
        ot = z;
        if(control.orbitStyle > 0) ot -= trap;
        orbitTrap = min(orbitTrap, float4(abs(ot), dot(ot,ot)));

        i++;
    }
    
    return z;
}

float DE_BUFFALO(float3 pos,device Control &control,thread float4 &orbitTrap) {
#define DEScale control.cx
    float3 z = pos;
    if(control.UseDeltaDE) {
        // Author: Krzysztof Marczak (buddhi1980@gmail.com) from  MandelbulberV2
        float deltavalue = max(length(z) * 0.000001, DEScale);
        float3 deltaX = float3 (deltavalue, 0.0, 0.0);
        float3 deltaY = float3 (0.0, deltavalue, 0.0);
        float3 deltaZ = float3 (0.0, 0.0, deltavalue);
        
        float3 zCenter = DE1(z,control,orbitTrap);
        float r = length(zCenter);
        
        float3 d;
        float3 zx1 = DE1(z + deltaX,control,orbitTrap);
        float3 zx2 = DE1(z - deltaX,control,orbitTrap);
        d.x = min(abs(length(zx1) - r), abs(length(zx2) - r)) / deltavalue;
        
        float3 zy1 = DE1(z + deltaY,control,orbitTrap);
        float3 zy2 = DE1(z - deltaY,control,orbitTrap);
        d.y = min(abs(length(zy1) - r), abs(length(zy2) - r)) / deltavalue;
        
        float3 zz1 = DE1(z + deltaZ,control,orbitTrap);
        float3 zz2 = DE1(z - deltaZ,control,orbitTrap);
        d.z = min(abs(length(zz1) - r), abs(length(zz2) - r)) / deltavalue;
        
        float dr = length(d);
        
        return 0.5 * r * log(r)/dr;  //logarythmic DeltaDE
        //return 0.5 * r/dr; //linear DeltaDE
    }
    
    float r = length(z);
    float dr=1.0;
    int i=0;
    
    float3 ot,trap = control.otFixed;
    if(int(control.orbitStyle + 0.5) == 2) trap -= pos;
    
    while(r<Bailout && (i<control.maxSteps)) {
        BuffaloIteration(z,r,dr,control);
        z+=(control.juliaboxMode ? control.julia : pos);
        r=length(z);

        z = rotatePosition(z,1,control.angle1);
        z = rotatePosition(z,2,control.angle1);
        
        ot = z;
        if(control.orbitStyle > 0) ot -= trap;
        orbitTrap = min(orbitTrap, float4(abs(ot), dot(ot,ot)));

        i++;
    }
    
    return 0.5*log(r)*r/dr;
}

//MARK: - 45
float DE_TEMPLE(float3 pos,device Control &control,thread float4 &orbitTrap) {
#define Scale45   control.cx
#define tt        control.cy
#define ceiling45 control.cz
#define floor45   control.cw
    float3 p=pos;
    p.xz=abs(.5-mod(pos.xz,1.))+.01;
    float DEfactor=1.;

    float3 ot,trap = control.otFixed;
    if(int(control.orbitStyle + 0.5) == 2) trap -= pos;
    
    for (int i=0; i<control.maxSteps; i++) {
        p = abs(p)-float3(0.,control.cy,0.);
        float r2 = dot(p, p);
        float sc=Scale45/clamp(r2 * control.dy,control.dx,1.);
        p*=sc;
        DEfactor*=sc;
        p = p - float3(0.5,1.,0.5);
        
        p = rotatePosition(p,0,control.angle1);
        p = rotatePosition(p,1,control.angle2);
        
        ot = p;
        if(control.orbitStyle > 0) ot -= trap;
        orbitTrap = min(orbitTrap, float4(abs(ot), dot(ot,ot)));
    }

    float rr=length(pos+float3(0.,-3.03,1.85-tt))-.017;
    float fl=pos.y - ceiling45;
    float d=min(fl,length(p)/DEfactor-.0005);
    d=min(d,-pos.y + floor45);
    d=min(d,rr);
    return d;
}

//MARK: - 46
float DE_KALI3(float3 pos,device Control &control,thread float4 &orbitTrap) {
#define C46 control.julia
#define g46 control.cx
    float dr = 1.0;
    float r2;
    
    float3 ot,trap = control.otFixed;
    if(int(control.orbitStyle + 0.5) == 2) trap -= pos;
    
    for (int i=0; i<control.maxSteps; i++) {
        r2 = dot(pos,pos);
        if(r2>100.)continue;
        
        pos = abs(pos) / r2 * g46 - C46;
        
        dr = dr / r2 * g46;
        
        ot = pos;
        if(control.orbitStyle > 0) ot -= trap;
        orbitTrap = min(orbitTrap, float4(abs(ot), dot(ot,ot)));
    }
    
    //return .1*(abs(pos.x)+abs(pos.y))*length(pos)/dr;
    
    //return .1*(length(pos.xz)*abs(pos.y)+length(pos.xy)*abs(pos.z)+length(pos.yz)*abs(pos.x))/dr;
    return .15*(length(pos.xz))*length(pos.xy)/dr;
    //return .125*sqrt(r2)*log(r2)/dr;
    //return .1*length(pos)/dr;
}

//MARK: - 47
float sdSponge(float3 z,device Control &control) {
    z *= control.ey; //3;
    //folding
    for (int i=0; i < 4; i++) {
        z = abs(z);
        z.xy = (z.x < z.y) ? z.yx : z.xy;
        z.xz = (z.x < z.z) ? z.zx : z.xz;
        z.zy = (z.y < z.z) ? z.yz : z.zy;
        z = z * 3.0 - 2.0;
        z.z += (z.z < -1.0) ? 2.0 : 0.0;
    }

    //distance to cube
    z = abs(z) - float3(1.0);
    float dis = min(max(z.x, max(z.y, z.z)), 0.0) + length(max(z, 0.0));
    //scale cube size to iterations
    return dis * 0.2 * pow(3.0, -3.0);
}

float DE_SPONGE(float3 pos,device Control &control,thread float4 &orbitTrap) {
#define param_min control.mins
#define param_max control.maxs
    float k, r2;
    float scale = 1.0;

    float3 ot,trap = control.otFixed;
    if(int(control.orbitStyle + 0.5) == 2) trap -= pos;
    
    for (int i=0; i < control.maxSteps; i++) {
        pos = 2.0 * clamp(pos, param_min.xyz, param_max.xyz) - pos;
        r2 = dot(pos, pos);
        k = max(param_min.w / r2, 1.0);
        pos *= k;
        scale *= k;

        ot = pos;
        if(control.orbitStyle > 0) ot -= trap;
        orbitTrap = min(orbitTrap, float4(abs(ot), dot(ot,ot)));
    }
    pos /= scale;
    pos *= param_max.w * control.ex;
    return float(0.1 * sdSponge(pos,control) / (param_max.w * control.ex));
}
    
//MARK: - 48
float3 tsqr(thread float3 p) {
    if(p.x==0. && p.y==0.) return float3(-p.z*p.z,0.,0.);
    float a = 1.-p.z*p.z/dot(p.xy,p.xy);
    return float3((p.x*p.x-p.y*p.y)*a ,2.*p.x*p.y*a,2.*p.z*length(p.xy));
}

float3 talt(thread float3 z) { return float3(z.xy,-z.z); }

float DE_FLORAL(float3 pos,device Control &control,thread float4 &orbitTrap) {
#define ss48     control.cx
#define g48      control.cy
#define CSize48  control.n1
#define C148     control.n2
#define offset48 control.n3
    float scale = 1.0;
    
    float3 ot,trap = control.otFixed;
    if(int(control.orbitStyle + 0.5) == 2) trap -= pos;
    
    for (int i=0; i < control.maxSteps; i++) {
        
        //BoxFold
        pos = clamp(pos,-CSize48, CSize48) * 2.0 - pos;
        pos.xyz = C148 - abs(abs(pos.zyx + CSize48)-C148) - CSize48;
        
        //Trap
        float r2 = dot(pos,pos);
        if(r2 > 100) break;

        //SphereFold and scaling
        float k = max(ss48/r2,.1) * g48;
        
        pos   *= k;
        scale *= k;
        
        //Triplex squaring and translation
        pos = tsqr(pos) - offset48;  //talt(tsqr(p))-.6;//
        scale *= 2.*(length(pos));      //??? was intended to be before previous line
        
        ot = pos;
        if(control.orbitStyle > 0) ot -= trap;
        orbitTrap = min(orbitTrap, float4(abs(ot), dot(ot,ot)));
    }

    return .85*length(pos)/scale;
}

//MARK: - 49
float deTorus(float3 p, float2 t) {
    float2 q = float2(length(p.xz)-t.x,p.y);
    return length(q)-t.y;
}

float lengthN(float2 p, float n) {
    p = pow(abs(p), float2(n));
    return pow(p.x+p.y, 1.0/n);
}

float3 torusKnot(float t,device Control &control) {
    t *= control.cx;
    float angle = t * control.cy;
    float3 p = 0.3 * float3(cos(angle),sin(angle),0);
    p.x += control.cz;
    
    p = rotatePosition(p,1,t*2);
    return p;
}

float deTorusKnot(float3 p,device Control &control,thread float4 &orbitTrap) {
    float ITR = control.maxSteps;
    float pitch = 1.0;
    float t = 0.5;
    float de = 1e10;

    float3 ot,trap = control.otFixed;
    if(int(control.orbitStyle + 0.5) == 2) trap -= p;
    
    for(int j=0; j<2; j++) {
        float t0 = t-pitch*0.5;
        pitch /= ITR;
        for(float i=0.0; i<=ITR; i++) {
            t0 += pitch;
            float de0 = distance(p,torusKnot(t0,control));
            if (de0 < de) {
                de = de0;
                t = t0;
            }
            
            ot = float3(de0,t0,pitch);
            if(control.orbitStyle > 0) ot -= trap;
            orbitTrap = min(orbitTrap, float4(abs(ot), dot(ot,ot)));
        }
    }
    
    float3 u = normalize(torusKnot(t,control));
    float3 v = normalize(torusKnot(t+0.01,control)-torusKnot(t-0.01,control));
    float3 w = normalize(cross(u,v));
    u = cross(v,w);
    p -= torusKnot(t,control);
    p = float3(dot(p,w), dot(p,u), dot(p,v));
    
    return lengthN(float2(length(p.yz), p.x), 3.0)-0.18 ;
}

float DE_KNOT(float3 pos,device Control &control,thread float4 &orbitTrap) {
    return min(deTorusKnot(pos,control,orbitTrap),deTorus(pos,float2(1.5,0.12)));
}

//MARK: - 50
float DE_DONUTS(float3 pos,device Control &control,thread float4 &orbitTrap) {
#define MAJOR_RADIUS control.cx
#define MINOR_RADIUS control.cy
#define SCALE        control.cz
    float3 n = -float3(control.dx,0,control.dy);
    float dis = 1e20;
    float newdis,s = 1.;
    float2 q;
    
    float3 ot,trap = control.otFixed;
    if(int(control.orbitStyle + 0.5) == 2) trap -= pos;
    
    for (int i=0; i < control.maxSteps; i++) {
        q = float2(length(pos.xz) - MAJOR_RADIUS,pos.y);

        newdis = (length(q)-MINOR_RADIUS)*s;
        if(newdis<dis) dis = newdis;
        
        //folding
        pos.xz = abs(pos.xz);//fold to positive quadrant
        if(pos.x < pos.z) pos.xz = pos.zx;//fold 45 degrees
        pos -= 2. * min(0.,dot(pos, n)) * n;//fold 22.5 degrees
        
        //rotation
        pos.yz = float2(-pos.z,pos.y);
        
        //offset
        pos.x -= MAJOR_RADIUS;
        
        //scaling
        pos *= SCALE;
        s /= SCALE;
        
        ot = pos;
        if(control.orbitStyle > 0) ot -= trap;
        orbitTrap = min(orbitTrap, float4(abs(ot), dot(ot,ot)));
    }
    
    return dis;
}

//MARK: - distance estimate
float DE_Inner(float3 pos,device Control &control,thread float4 &orbitTrap) {
    switch(control.equation) {
        case EQU_01_MANDELBULB  : return DE_MANDELBULB(pos,control,orbitTrap);
        case EQU_02_APOLLONIAN  : return DE_APOLLONIAN(pos,control,orbitTrap);
        case EQU_03_APOLLONIAN2 : return DE_APOLLONIAN2(pos,control,orbitTrap);
        case EQU_04_KLEINIAN    : return DE_KLEINIAN(pos,control,orbitTrap);
        case EQU_05_MANDELBOX   : return DE_MANDELBOX(pos,control,orbitTrap);
        case EQU_06_QUATJULIA   : return DE_QUATJULIA(pos,control,orbitTrap);
        case EQU_07_MONSTER     : return DE_MONSTER(pos,control,orbitTrap);
        case EQU_08_KALI_TOWER  : return DE_KALI_TOWER(pos,control,orbitTrap);
        case EQU_09_POLY_MENGER : return DE_POLY_MENGER(pos,control,orbitTrap);
        case EQU_10_GOLD        : return DE_GOLD(pos,control,orbitTrap);
        case EQU_11_SPIDER      : return DE_SPIDER(pos,control,orbitTrap);
        case EQU_12_KLEINIAN2   : return DE_KLEINIAN2(pos,control,orbitTrap);
        case EQU_13_KIFS        : return DE_KIFS(pos,control,orbitTrap);
        case EQU_14_IFS_TETRA   : return DE_IFS_TETRA(pos,control,orbitTrap);
        case EQU_15_IFS_OCTA    : return DE_IFS_OCTA(pos,control,orbitTrap);
        case EQU_16_IFS_DODEC   : return DE_IFS_DODEC(pos,control,orbitTrap);
        case EQU_17_IFS_MENGER  : return DE_IFS_MENGER(pos,control,orbitTrap);
        case EQU_18_SIERPINSKI  : return DE_SIERPINSKI_T(pos,control,orbitTrap);
        case EQU_19_HALF_TETRA  : return DE_HALF_TETRA(pos,control,orbitTrap);
        case EQU_20_FULL_TETRA  : return DE_FULL_TETRA(pos,control,orbitTrap);
        case EQU_21_CUBIC       : return DE_CUBIC(pos,control,orbitTrap);
        case EQU_22_HALF_OCTA   : return DE_HALF_OCTA(pos,control,orbitTrap);
        case EQU_23_FULL_OCTA   : return DE_FULL_OCTA(pos,control,orbitTrap);
        case EQU_24_KALEIDO     : return DE_KALEIDO(pos,control,orbitTrap);
        case EQU_25_POLYCHORA   : return DE_POLYCHORA(pos,control,orbitTrap);
        case EQU_26_QUADRAY     : return DE_QUADRAY(pos,control,orbitTrap);
        case EQU_27_FRAGM       : return DE_FRAGM(pos,control,orbitTrap);
        case EQU_28_QUATJULIA2  : return DE_QUATJULIA2(pos,control,orbitTrap);
        case EQU_29_MBROT       : return DE_MBROT(pos,control,orbitTrap);
        case EQU_30_KALIBOX     : return DE_KALIBOX(pos,control,orbitTrap);
        case EQU_31_SPUDS       : return DE_SPUDS(pos,control,orbitTrap);
        case EQU_32_MPOLY       : return DE_MPOLY(pos,control,orbitTrap);
        case EQU_33_MHELIX      : return DE_MHELIX(pos,control,orbitTrap);
        case EQU_34_FLOWER      : return DE_FLOWER(pos,control,orbitTrap);
        case EQU_35_JUNGLE      : return DE_JUNGLE(pos,control,orbitTrap);
        case EQU_36_PRISONER    : return DE_PRISONER(pos,control,orbitTrap);
        case EQU_37_SPIRALBOX   : return DE_SPIRALBOX(pos,control,orbitTrap);
        case EQU_38_ALEK_BULB   : return DE_ALEK_BULB(pos,control,orbitTrap);
        case EQU_39_SURFBOX     : return DE_SURFBOX(pos,control,orbitTrap);
        case EQU_40_TWISTBOX    : return DE_TWISTBOX(pos,control,orbitTrap);
        case EQU_41_KALI_RONTGEN: return DE_KALI_RONTGEN(pos,control,orbitTrap);
        case EQU_42_VERTEBRAE   : return DE_VERTEBRAE(pos,control,orbitTrap);
        case EQU_43_DARKSURF    : return DE_DARKSURF(pos,control,orbitTrap);
        case EQU_44_BUFFALO     : return DE_BUFFALO(pos,control,orbitTrap);
        case EQU_45_TEMPLE      : return DE_TEMPLE(pos,control,orbitTrap);
        case EQU_46_KALI3       : return DE_KALI3(pos,control,orbitTrap);
        case EQU_47_SPONGE      : return DE_SPONGE(pos,control,orbitTrap);
        case EQU_48_FLORAL      : return DE_FLORAL(pos,control,orbitTrap);
        case EQU_49_KNOT        : return DE_KNOT(pos,control,orbitTrap);
        case EQU_50_DONUTS      : return DE_DONUTS(pos,control,orbitTrap);
    }
    
    return 0;
}

float DE(float3 pos,device Control &control,thread float4 &orbitTrap) {
    if(control.doInversion) {
        pos = pos - control.InvCenter;
        float r = length(pos);
        float r2 = r*r;
        pos = (control.InvRadius * control.InvRadius / r2 ) * pos + control.InvCenter;
        
        float an = atan2(pos.y,pos.x) + control.InvAngle;
        float ra = sqrt(pos.y * pos.y + pos.x * pos.x);
        pos.x = cos(an)*ra;
        pos.y = sin(an)*ra;
        float de = DE_Inner(pos,control,orbitTrap);
        de = r2 * de / (control.InvRadius * control.InvRadius + r * de);
        return de;
    }
    
    return DE_Inner(pos,control,orbitTrap);
}

//MARK: -
// x = distance, y = iteration count, z = average distance hop

float3 shortest_dist(float3 eye, float3 marchingDirection,device Control &control,thread float4 &orbitTrap) {
    float dist,hop = 0;
    float3 ans = float3(MIN_DIST,0,0);
    float secondSurface = control.secondSurface;
    int i = 0;
    
    for(; i < MAX_MARCHING_STEPS; ++i) {
        dist = DE(eye + ans.x * marchingDirection,control,orbitTrap);
        if(dist < MIN_DIST) {
            if(secondSurface == 0.0) break;     // secondSurface is disabled (equals 0), or has 2already been used
            ans.x += secondSurface;             // move along ray, and start looking for 2nd surface
            secondSurface = 0;                  // set to zero as 'already been used' marker
        }

        ans.x += dist;
        if(ans.x >= MAX_DIST) break;
        
        // don't let average distance be driven into the dirt
        if(dist >= 0.0001) hop = mix(hop,dist,0.95);
    }
    
    ans.y = float(i);
    ans.z = hop;
    return ans;
}

float3 calcNormal(float3 pos,device Control &control) {
    float4 temp = float4(10000);
    float2 e = float2(1.0,-1.0) * 0.057;
    float3 ans = normalize(e.xyy * DE( pos + e.xyy, control,temp) +
                           e.yyx * DE( pos + e.yyx, control,temp) +
                           e.yxy * DE( pos + e.yxy, control,temp) +
                           e.xxx * DE( pos + e.xxx, control,temp) );
    
    return normalize(ans);
}

//MARK: -
// boxplorer's method
float3 getBlinnShading(float3 normal, float3 direction, float3 light,device Control &control) {
    float3 halfLV = normalize(light + direction);
    float spe = pow(dot(normal, halfLV), 2);
    float dif = dot(normal, light) * 0.5 + 0.75;
    return dif + spe * control.specular;
}

float3 lerp(float3 a, float3 b, float w) { return a + w*(b-a); }

float3 hsv2rgb(float3 c) {
    return lerp(saturate((abs(fract(c.x + float3(1,2,3)/3) * 6 - 3) - 1)),1,c.y) * c.z;
}

float3 HSVtoRGB(float3 hsv) {
    /// Implementation based on: http://en.wikipedia.org/wiki/HSV_color_space
    hsv.x = mod(hsv.x,2.*PI);
    int Hi = int(mod(hsv.x / (2.*PI/6.), 6.));
    float f = (hsv.x / (2.*PI/6.)) -float( Hi);
    float p = hsv.z*(1.-hsv.y);
    float q = hsv.z*(1.-f*hsv.y);
    float t = hsv.z*(1.-(1.-f)*hsv.y);
    if (Hi == 0) { return float3(hsv.z,t,p); }
    if (Hi == 1) { return float3(q,hsv.z,p); }
    if (Hi == 2) { return float3(p,hsv.z,t); }
    if (Hi == 3) { return float3(p,q,hsv.z); }
    if (Hi == 4) { return float3(t,p,hsv.z); }
    if (Hi == 5) { return float3(hsv.z,p,q); }
    return float3(0.);
}

//MARK: -

float3 cycle(float3 c, float s, device Control &control) {
    float ss = s * control.Cycles;    
    return float3(0.5) + 0.5 * float3( cos(ss + c.x), cos(ss + c.y), cos(ss + c.z));
}

float3 getOrbitColor(device Control &control,float4 orbitTrap) {
    orbitTrap.w = sqrt(orbitTrap.w);
    
    float3 orbitColor;
    
    if (control.Cycles > 0.0) {
        orbitColor =
            cycle(control.X.xyz, orbitTrap.x, control) * control.X.w * orbitTrap.x +
            cycle(control.Y.xyz, orbitTrap.y, control) * control.Y.w * orbitTrap.y +
            cycle(control.Z.xyz, orbitTrap.z, control) * control.Z.w * orbitTrap.z +
            cycle(control.R.xyz, orbitTrap.w, control) * control.R.w * orbitTrap.w;
    } else {
        orbitColor =
            control.X.xyz * control.X.w * orbitTrap.x +
            control.Y.xyz * control.Y.w * orbitTrap.y +
            control.Z.xyz * control.Z.w * orbitTrap.z +
            control.R.xyz * control.R.w * orbitTrap.w;
    }
    
    return orbitColor;
}

//MARK: -

kernel void rayMarchShader
(
 texture2d<float, access::write> outTexture     [[texture(0)]],
 texture2d<float, access::read> coloringTexture [[texture(1)]],
 device Control &c      [[ buffer(0) ]],
 device TVertex* vData  [[ buffer(1) ]],
 uint2 p [[thread_position_in_grid]]
 )
{
    uint2 srcP = p; // copy of pixel coordinate, altered during radial symmetry
    if(srcP.x >= uint(c.xSize)) return; // screen size not evenly divisible by threadGroups
    if(srcP.y >= uint(c.ySize)) return;
    if(c.skip > 1 && ((srcP.x % c.skip) != 0 || (srcP.y % c.skip) != 0)) return;
    
    // apply radial symmetry? ---------
    if(c.radialAngle > 0.01) { // 0 = don't apply
        float centerX = c.xSize/2;
        float centerY = c.ySize/2;
        float dx = float(p.x - centerX);
        float dy = float(p.y - centerY);

        float angle = fabs(atan2(dy,dx));

        float dRatio = 0.01 + c.radialAngle;
        while(angle > dRatio) angle -= dRatio;
        if(angle > dRatio/2) angle = dRatio - angle;

        float dist = sqrt(dx * dx + dy * dy);

        srcP.x = uint(centerX + cos(angle) * dist);
        srcP.y = uint(centerY + sin(angle) * dist);
    }
    
    float3 color = float3();

    uint2 q = srcP;                 // copy of current pixel coordinate; x is altered for stereo
    unsigned int xsize = c.xSize;   // copy of current window size; x is altered for stereo
    float3 camera = c.camera;       // copy of camera position; x is altered for stereo
    
    if(c.isStereo) {
        xsize /= 2;                 // window x size adjusted for 2 views side by side
        float3 offset = c.sideVector * c.parallax;

        if(srcP.x >= xsize) {   // right side of stereo pair?
            q.x -= xsize;       // base 0  X coordinate
            camera -= offset;   // adjust for right side parallax
        }
        else {
            camera += offset;   // adjust for left side parallax
        }
    }
    
    // drawing high resolution 2D window, and companion 3D window is active : draw white colored Region of Interest rectangle on 2D window
    // here we determine whether the current pixel lies on the ROI rectangle. If so, draw white pixel and exit.
    if(c.skip == 1 && c.win3DFlag > 0 && c.win3DDirty) {  // draw 3D bounding box
        bool mark = false;
        if((p.x == c.xmin3D-1 || p.x == c.xmin3D) && p.y >= c.ymin3D && p.y <= c.ymax3D) mark = true; else
        if((p.x == c.xmax3D+1 || p.x == c.xmax3D) && p.y >= c.ymin3D && p.y <= c.ymax3D) mark = true;
        if(!mark) {
            if((p.y == c.ymin3D-1 || p.y == c.ymin3D) && p.x >= c.xmin3D && p.x <= c.xmax3D) mark = true; else
            if((p.y == c.ymax3D+1 || p.y == c.ymax3D) && p.x >= c.xmin3D && p.x <= c.xmax3D) mark = true;
        }
        
        if(mark) {
            outTexture.write(float4(1,1,1,1),p);
            return;
        }
    }
    
    float4 orbitTrap = float4(10000.0);

    float den = float(xsize);
    float dx =  1.5 * (float(q.x)/den - 0.5);
    float dy = -1.5 * (float(q.y)/den - 0.5);
    float3 direction = normalize((c.sideVector * dx) + (c.topVector * dy) + c.viewVector);
    float3 dist = shortest_dist(camera,direction,c,orbitTrap);
    
    if (dist.x <= MAX_DIST - 0.0001) {
        float3 position = camera + dist.x * direction;
        float3 cc,normal = calcNormal(position,c);
        
        // use texture
        if(c.txtOnOff) {
            float scale = c.tScale * 4;
            float len = length(position) / dist.x;
            float x = normal.x / len;
            float y = normal.z / len;
            float w = c.txtSize.x;
            float h = c.txtSize.y;
            float xx = w + (c.tCenterX * 4 + x * scale) * (w + len);
            float yy = h + (c.tCenterY * 4 + y * scale) * (h + len);
            
            uint2 pt;
            pt.x = uint(fmod(xx,w));
            pt.y = uint(c.txtSize.y - fmod(yy,h)); // flip Y coord
            color = coloringTexture.read(pt).xyz;
        }
        
        switch(c.colorScheme) {
            case 0 :
                color += float3(1 - (normal / 10 + sqrt(dist.y / 80)));
                break;
            case 1 :
                color += float3(abs(1 - (normal / 3 + sqrt(dist.y / 8)))) / 10;
                break;
            case 2 :
                color += float3(1 - (normal + sqrt(dist.y / 20))) / 10;
                cc = 0.5 + 0.5*cos( 6.2831 * position.z + float3(0.0,1.0,2.0) );
                color = mix(color,cc,0.5);
                break;
            case 3 :
                color += abs(normal) * 0.1;
                color += HSVtoRGB(color * dist.y * 0.1);
                break;
            case 4 :
                color += abs(normal) * dist.y * 0.01;
                color += hsv2rgb(color.yzx);
                break;
            case 5 :
            {
                float3 nn = normal;
                nn.x += nn.z;
                nn.y += nn.z;
                color += hsv2rgb( normalize(0.5 - nn));
            }
                break;
            case 6 :
            {
                float escape = dist.z * c.colorParam;
                float co = dist.y * 0.3 - log(log(length(position))/log(escape))/log(3.);
                co = sqrt(co) / 3;
                color += float3(.5 + cos(co + float3(0,0.3,0.4)) ); // blue,magenta,yellow
            }
                break;
            case 7 :
            {
                float escape = dist.z * c.colorParam;
                float co = dist.y - log(log(length(position))/log(escape))/log(3.);
                co = sqrt(co / 3);
                color += float3(.5 + sin(co) * 8);
            }
                break;
        }
        
        float3 light = getBlinnShading(normal, direction, c.nlight, c);
        color = mix(light, color, 0.8);
        
        float4 temp = float4(10000);
        float3 diff = c.viewVector * dist.y / 10;
        float d1 = DE(position - diff,c,temp);
        float d2 = DE(position + diff,c,temp);
        float d3 = d1-d2;
        color *= (1 + (1-d3) * c.enhance);
        
        color *= c.bright;
        color = 0.5 + (color - 0.5) * c.contrast * 2;

        float3 oColor = getOrbitColor(c,orbitTrap);
        color = mix(color, 3.0 * oColor, c.OrbitStrength);
        
        // fog ---------------------
        if(c.fog > 0) {
            float3 backColor = float3(c.fogR,c.fogG,c.fogB);
            color = mix(color, backColor, 1.0-exp(-pow(c.fog,4.0) * dist.x * dist.x));
        }

    } // hit object
    else {
        // background color from texture
        if(c.txtOnOff) {
            float scale = c.tScale;
            float x = direction.x;
            float y = direction.z;
            float w = c.txtSize.x;
            float h = c.txtSize.y;
            float xx = w + (c.tCenterX * 4 + x * scale) * w;
            float yy = h + (c.tCenterY * 4 + y * scale) * h;
            
            uint2 pt;
            pt.x = uint(fmod(xx,w));
            pt.y = uint(c.txtSize.y - fmod(yy,h)); // flip Y coord
            color = coloringTexture.read(pt).xyz;
        }
    }

    if(c.skip == 1) {
        outTexture.write(float4(color.xyz,1),p);

        // update vData[] for 3D window -----------------
        if(c.win3DDirty) {
            if(p.x >= c.xmin3D && p.x < c.xmax3D && p.y >= c.ymin3D && p.y < c.ymax3D) {
                int x = int(p.x - c.xmin3D) * int(SIZE3D) / int(c.xSize3D);
                int y = int(p.y - c.ymin3D) * int(SIZE3D) / int(c.ySize3D);
                int index = y * SIZE3D + x;
                
                vData[index].height = dist.x;
                vData[index].color = float4(color,1);
            }
        }
    }
    else {
        uint2 pp;
        for(int x=0;x<c.skip;++x) {
            pp.x = p.x + x;
            for(int y=0;y<c.skip;++y) {
                pp.y = p.y + y;
                outTexture.write(float4(color.xyz,1),pp);
            }
        }
    }
}

/////////////////////////////////////////////////////////////////////////

kernel void normalShader
(
 device TVertex* v [[ buffer(0) ]],
 uint2 p [[thread_position_in_grid]])
{
    if(p.x >= SIZE3D || p.y >= SIZE3D) return; // data size not evenly divisible by threadGroups
    
    int i = int(p.y) * SIZE3D + int(p.x);
    int i2 = i + ((p.x < SIZE3Dm) ? 1 : -1);
    int i3 = i + ((p.y < SIZE3Dm) ? SIZE3D : -SIZE3D);
    
    TVertex v1 = v[i];
    TVertex v2 = v[i2];
    TVertex v3 = v[i3];
    
    v[i].normal = normalize(cross(v1.position - v2.position, v1.position - v3.position));
}

/////////////////////////////////////////////////////////////////////////

struct Transfer {
    float4 position [[position]];
    float4 lighting;
    float4 color;
};

vertex Transfer texturedVertexShader
(
 constant TVertex *data     [[ buffer(0) ]],
 constant Uniforms &uniforms[[ buffer(1) ]],
 unsigned int vid [[ vertex_id ]])
{
    TVertex in = data[vid];
    Transfer out;
    
    float4 p = float4(in.position,1);
    
    if(in.height > uniforms.ceiling3D) {
        p.y = uniforms.floor3D;
        float G = 0.1;
        out.color = float4(G,G,G,1);
    }
    else {
        p.y = in.height * uniforms.yScale3D;
        out.color = in.color;
    }
    
    out.position = uniforms.mvp * p;

    float distance = length(uniforms.light.position - in.position.xyz);
    float intensity = uniforms.light.ambient + saturate(dot(in.normal.rgb, uniforms.light.position) / pow(distance,uniforms.light.power) );
    out.lighting = float4(intensity,intensity,intensity,1);
    
    return out;
}

fragment float4 texturedFragmentShader
(
 Transfer data [[stage_in]])
{
    return data.color * data.lighting;
}
