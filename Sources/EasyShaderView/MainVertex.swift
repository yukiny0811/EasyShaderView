//
//  MainVertex.swift
//  EasyShaderView
//
//  Created by Yuki Kuwashima on 2025/02/17.
//

import MetalVertexHelper
import simd
import Metal

@VertexObject
public struct MainVertex {
    public var position: simd_float3
    public var normal: simd_float3
    public var uv: simd_float2
    public var colorRGBA: simd_float4
    public init(position: simd_float3, normal: simd_float3, uv: simd_float2, colorRGBA: simd_float4) {
        self.position = position
        self.normal = normal
        self.uv = uv
        self.colorRGBA = colorRGBA
    }
}
