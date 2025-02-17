//
//  Shader.metal
//  ShaderView
//
//  Created by Yuki Kuwashima on 2025/02/07.
//
//  Original source code from Apple Inc. https://developer.apple.com/videos/play/tech-talks/605/
//  Modified by Yuki Kuwashima on 2022/12/14.
//
//  Copyright © 2017 Apple Inc.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


#include <metal_stdlib>
using namespace metal;

constexpr sampler textureSampler (coord::normalized, address::repeat, filter::linear);

struct MainVertex {
    float3 position [[ attribute(0) ]];
    float3 normal [[ attribute(1) ]];
    float2 uv [[ attribute(2) ]];
    float4 colorRGBA [[ attribute(3) ]];
};

struct RasterizerData {
    float4 position [[ position ]];
    float4 color;
    float3 normal;
    float2 uv;
    float3 worldPosition;
    float3 cameraWorldPosition [[ flat ]];
};

struct Uniform3D {
    float4x4 projectionMatrix;
    float4x4 viewMatrix;
    float4x4 viewMatrixInverse;
    float4x4 modelToWorldMatrix;
    float4x4 modelToWorldMatrixInverse;
    float4x4 modelToWorldNormalMatrix;
};

vertex RasterizerData main_vert
(
 const MainVertex vIn [[ stage_in ]],
 const device Uniform3D& uniform [[ buffer(10) ]]
 ) {

    RasterizerData rd;
    rd.position = uniform.projectionMatrix * uniform.viewMatrix * uniform.modelToWorldMatrix * float4(vIn.position, 1.0);
    rd.color = vIn.colorRGBA;
    rd.normal = normalize((uniform.modelToWorldNormalMatrix * float4(vIn.normal, 0.0)).xyz);
    rd.uv = vIn.uv;
    rd.worldPosition = (uniform.modelToWorldMatrix * float4(vIn.position, 1.0)).xyz;
    rd.cameraWorldPosition = float3(uniform.viewMatrixInverse.columns[3].x, uniform.viewMatrixInverse.columns[3].y, uniform.viewMatrixInverse.columns[3].z);
    return rd;
}

constant uint useDeviceMemory [[ function_constant(0) ]];
typedef rgba8unorm<half4> rgba8storage;
typedef r8unorm<half> r8storage;

template <int NUM_LAYERS>
struct OITData {
    static constexpr constant short s_numLayers = NUM_LAYERS;
    rgba8storage colors [[ raster_order_group(0) ]] [NUM_LAYERS];
    half depths [[ raster_order_group(0) ]] [NUM_LAYERS];
    r8storage transmittances [[ raster_order_group(0) ]] [NUM_LAYERS];
};

template <int NUM_LAYERS>
struct OITImageblock {
    OITData<NUM_LAYERS> oitData;
};

template <int NUM_LAYERS>
struct FragOut {
    OITImageblock<NUM_LAYERS> aoitImageBlock [[ imageblock_data ]];
};

template <typename OITDataT>
inline void InsertFragment(OITDataT oitData, half4 color, half depth, half transmittance) {
    const short numLayers = oitData->s_numLayers;
    for (short i = 0; i < numLayers - 1; ++i) {
        half layerDepth = oitData->depths[i];
        half4 layerColor = oitData->colors[i];
        half layerTransmittance = oitData->transmittances[i];

        bool insert = (depth <= layerDepth);
        oitData->colors[i] = insert ? color : layerColor;
        oitData->depths[i] = insert ? depth : layerDepth;
        oitData->transmittances[i] = insert ? transmittance : layerTransmittance;

        color = insert ? layerColor : color;
        depth = insert ? layerDepth : depth;
        transmittance = insert ? layerTransmittance : transmittance;
    }
    const short lastLayer = numLayers - 1;
    half lastDepth = oitData->depths[lastLayer];
    half4 lastColor = oitData->colors[lastLayer];
    half lastTransmittance = oitData->transmittances[lastLayer];

    bool newDepthFirst = (depth <= lastDepth);

    half firstDepth = newDepthFirst ? depth : lastDepth;
    half4 firstColor = newDepthFirst ? color : lastColor;
    half4 secondColor = newDepthFirst ? lastColor : color;
    half firstTransmittance = newDepthFirst ? transmittance : lastTransmittance;

    oitData->colors[lastLayer] = firstColor + secondColor * firstTransmittance;
    oitData->depths[lastLayer] = firstDepth;
    oitData->transmittances[lastLayer] = transmittance * lastTransmittance;
}

template <typename OITDataT>
void OITFragmentFunction(RasterizerData in,
                         OITDataT oitData,
                         texture2d<half> tex) {
    const float depth = in.position.z / in.position.w;

    half4 fragmentColor = half4(in.color);
    fragmentColor.rgb *= (fragmentColor.a);

    if (!is_null_texture(tex)) {
        constexpr sampler textureSampler (coord::pixel, address::clamp_to_edge, filter::linear);
        fragmentColor = tex.sample(textureSampler, float2(in.uv.x*tex.get_width(), in.uv.y*tex.get_height())) * fragmentColor.rgba;
    }

    if (fragmentColor.a == 0) {
        fragmentColor = half4(0, 0, 0, 0);
    }

    fragmentColor = half4(fragmentColor);

    InsertFragment(oitData, fragmentColor, depth, 1 - fragmentColor.a);
}

template <int NUM_LAYERS>
void OITClear(imageblock<OITImageblock<NUM_LAYERS>, imageblock_layout_explicit> oitData, ushort2 tid) {
    threadgroup_imageblock OITData<NUM_LAYERS> &pixelData = oitData.data(tid)->oitData;
    const short numLayers = pixelData.s_numLayers;
    for (ushort i = 0; i < numLayers; ++i) {
        pixelData.colors[i] = half4(0.0);
        pixelData.depths[i] = 65504.0;
        pixelData.transmittances[i] = 1.0;
    }
}

template <int NUM_LAYERS>
half4 OITResolve(OITData<NUM_LAYERS> pixelData) {
    const short numLayers = pixelData.s_numLayers;
    half4 finalColor = 0;
    half transmittance = 1;
    for (ushort i = 0; i < numLayers; ++i) {
        finalColor += (half4)pixelData.colors[i] * transmittance;
        transmittance *= (half)pixelData.transmittances[i];
    }
//    finalColor.w = 1;
    return finalColor;
}

fragment FragOut<4>
OITFragmentFunction_4Layer(RasterizerData in [[ stage_in ]],
                           OITImageblock<4> oitImageblock [[ imageblock_data ]],
                           texture2d<half, access::sample> tex [[ texture(0) ]]) {
    OITFragmentFunction(in, &oitImageblock.oitData, tex);
    FragOut<4> Out;
    Out.aoitImageBlock = oitImageblock;
    return Out;
}

kernel void OITClear_4Layer(imageblock<OITImageblock<4>, imageblock_layout_explicit> oitData,
                            ushort2 tid [[ thread_position_in_threadgroup ]]) {
    OITClear(oitData, tid);
}

fragment half4 OITResolve_4Layer(OITImageblock<4> oitImageblock [[ imageblock_data ]]) {
    return OITResolve(oitImageblock.oitData);
}


