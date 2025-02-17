//
//  ContentView.swift
//  Demo
//
//  Created by Yuki Kuwashima on 2025/02/14.
//

import SwiftUI
import EasyShaderView
import TransformUtils
import MetalKit

struct ContentView: View {

    let renderer = MyRenderer()

    var body: some View {
        ShaderView(renderer)
    }
}

class MyRenderer: RendererBase {

    static let textureLoader: MTKTextureLoader = MTKTextureLoader(device: MTLCreateSystemDefaultDevice()!)
    let texture: MTLTexture = try! textureLoader.newTexture(name: "sample", scaleFactor: 2, bundle: .main)

    override func compute(encoder: any MTLComputeCommandEncoder) {

    }
    override func render(encoder: any MTLRenderCommandEncoder) {
        // mainTexture: fragment texture binding at 0
        // color: baseUniform.color -> uses color when main texture is nil

        encoder.setFragmentTexture(texture, index: 0)

        let vertices1: [MainVertex] = [
            MainVertex(position: f3(1, 0, 0), normal: f3(0, 0, 1), uv: f2(1, 0), colorRGBA: f4(1, 1, 0, 0.3)),
            MainVertex(position: f3(1, 1, 0), normal: f3(0, 0, 1), uv: f2(1, 1), colorRGBA: f4(1, 1, 0, 0.3)),
            MainVertex(position: f3(0, 1, 0), normal: f3(0, 0, 1), uv: f2(0, 1), colorRGBA: f4(1, 1, 0, 0.3)),
        ]
        encoder.setVertexBytes(vertices1, length: MainVertex.memorySize * vertices1.count, index: 0)
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertices1.count)

        let vertices2: [MainVertex] = [
            MainVertex(position: f3(1, 0, 2), normal: f3(0, 0, 1), uv: f2(1, 0), colorRGBA: f4(0, 0, 1, 0.3)),
            MainVertex(position: f3(0, 1, 2), normal: f3(0, 0, 1), uv: f2(0, 1), colorRGBA: f4(0, 0, 1, 0.3)),
            MainVertex(position: f3(0, 0, 2), normal: f3(0, 0, 1), uv: f2(0, 0), colorRGBA: f4(0, 0, 1, 0.3)),
        ]
        encoder.setVertexBytes(vertices2, length: MainVertex.memorySize * vertices2.count, index: 0)
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertices2.count)
    }
}
