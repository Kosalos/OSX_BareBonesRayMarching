#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <simd/simd.h>
#include "Shader.h"

Control *cPtr = NULL;

void setControlPointer(Control *ptr) { cPtr = ptr; }

void flightReset(void) {
    for(int i=0;i<NUM_LIGHT;++i) {
        cPtr->flight[i].bright = 0;
        cPtr->flight[i].power = 0.1;
        cPtr->flight[i].x = 0;
        cPtr->flight[i].y = 0;
        cPtr->flight[i].z = 0;
        cPtr->flight[i].r = 1;
        cPtr->flight[i].g = 1;
        cPtr->flight[i].b = 1;
    }
}

float max(float v1,float v2) { if(v1 > v2) return v1;  return v2; }

void flightEncode(void) {
    for(int i=0;i<NUM_LIGHT;++i) {
        cPtr->flight[i].bright = max(cPtr->flight[i].bright,0);
        cPtr->flight[i].power = max(cPtr->flight[i].power,0.1);
        cPtr->flight[i].pos.x = 0.001 + -(cPtr->flight[i].x); // mirror image X
        cPtr->flight[i].pos.y = cPtr->flight[i].y;
        cPtr->flight[i].pos.z = cPtr->flight[i].z;
        cPtr->flight[i].color.x = cPtr->flight[i].r;
        cPtr->flight[i].color.y = cPtr->flight[i].g;
        cPtr->flight[i].color.z = cPtr->flight[i].b;
    }

    int i = 0;
    printf("Light %d: B %5.3f, P %5.3f, Pos %5.3f,%5.3f,%5.3f\n",i,cPtr->flight[i].bright,cPtr->flight[i].power,cPtr->flight[i].pos.x,
           cPtr->flight[i].pos.y,cPtr->flight[i].pos.z);
}

float* lightBright(int index)   { return &cPtr->flight[index].bright; }
float* lightPower(int index)    { return &cPtr->flight[index].power; }
float* lightX(int index)        { return &cPtr->flight[index].x; }
float* lightY(int index)        { return &cPtr->flight[index].y; }
float* lightZ(int index)        { return &cPtr->flight[index].z; }
float* lightR(int index)        { return &cPtr->flight[index].r; }
float* lightG(int index)        { return &cPtr->flight[index].g; }
float* lightB(int index)        { return &cPtr->flight[index].b; }
