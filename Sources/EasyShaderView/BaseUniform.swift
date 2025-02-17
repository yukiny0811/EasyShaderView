//
//  BaseUniform.swift
//  ShaderView
//
//  Created by Yuki Kuwashima on 2025/02/17.
//

import MetalVertexHelper
import simd
import Metal

@VertexObject
public struct BaseUniform {
    /// The projection matrix that transforms 3D coordinates into 2D screen space.
    public var projectionMatrix: simd_float4x4

    /// The view matrix that transforms world coordinates into camera (view) space.
    public var viewMatrix: simd_float4x4 {
        didSet {
            viewMatrixInverse = viewMatrix.inverse
        }
    }

    /// The inverse of the view matrix, useful for various calculations such as transforming normals.
    public var viewMatrixInverse: simd_float4x4

    /// The model-to-world transformation matrix that converts coordinates from model space to world space.
    public var modelToWorldMatrix: simd_float4x4 {
        didSet {
            modelToWorldMatrixInverse = modelToWorldMatrix.inverse
            modelToWorldNormalMatrix = modelToWorldMatrix.inverse.transpose
        }
    }

    /// The inverse of the model-to-world matrix, used for reversing the model-to-world transformation.
    public var modelToWorldMatrixInverse: simd_float4x4

    /// The normal matrix used to correctly transform normals from model space to world space.
    /// Typically derived from the inverse transpose of the model-to-world matrix.
    public var modelToWorldNormalMatrix: simd_float4x4

    public var color: simd_float4
}
