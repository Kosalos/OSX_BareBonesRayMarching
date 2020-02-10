#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <simd/simd.h>
#include "Shader.h"

Control *c = NULL;

void setControlPointer(Control *ptr) { c = ptr; }

void resetAllLights(void) {
    for(int i=0;i<NUM_LIGHT;++i) {
        c->flight[i].bright = 0;
        c->flight[i].power = 0.1;
        c->flight[i].x = 0;
        c->flight[i].y = 0;
        c->flight[i].z = 0;
        c->flight[i].r = 1;
        c->flight[i].g = 1;
        c->flight[i].b = 1;
    }
}

float max(float v1,float v2) { if(v1 > v2) return v1;  return v2; }

simd_float3 normalize(simd_float3 v) {
    float len = simd_length(v);
    if(len == 0) len += 0.0001;
    return v / len;
}

void encodeWidgetDataForAllLights(void) {
    for(int i=0;i<NUM_LIGHT;++i) {
        c->flight[i].bright = max(c->flight[i].bright,0);
        c->flight[i].power = max(c->flight[i].power,0.1);
        c->flight[i].relativePos.x = 0.001 + -(c->flight[i].x); // mirror image X
        c->flight[i].relativePos.y = c->flight[i].y;
        c->flight[i].relativePos.z = c->flight[i].z;
        
        c->flight[i].color.x = c->flight[i].r;
        c->flight[i].color.y = c->flight[i].g;
        c->flight[i].color.z = c->flight[i].b;

        // light position is relative to camera position and aim
        c->flight[i].pos = c->camera
            - (c->sideVector * c->flight[i].relativePos.x)
            + (c->topVector  * c->flight[i].relativePos.y)
            + (c->viewVector * c->flight[i].relativePos.z);
                
        c->flight[i].nrmPos = simd_normalize(c->flight[i].pos);
    }

//    int i = 0;
//    printf("Light %d: B %5.3f, P %5.3f, Pos %5.3f,%5.3f,%5.3f\n",i,c->flight[i].bright,c->flight[i].power,c->flight[i].pos.x,
//           c->flight[i].pos.y,c->flight[i].pos.z);
}

float* lightBright(int index)   { return &c->flight[index].bright; }
float* lightPower(int index)    { return &c->flight[index].power; }
float* lightX(int index)        { return &c->flight[index].x; }
float* lightY(int index)        { return &c->flight[index].y; }
float* lightZ(int index)        { return &c->flight[index].z; }
float* lightR(int index)        { return &c->flight[index].r; }
float* lightG(int index)        { return &c->flight[index].g; }
float* lightB(int index)        { return &c->flight[index].b; }
