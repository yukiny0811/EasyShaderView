//
//  ContentView.swift
//  Demo
//
//  Created by Yuki Kuwashima on 2025/02/14.
//

import SwiftUI
import EasyShaderView
import TransformUtils

struct ContentView: View {

    let renderer = MyRenderer()

    var body: some View {
        ShaderView(renderer)
    }
}

class MyRenderer: RendererBase {
    override func compute(encoder: any MTLComputeCommandEncoder) {

    }
    override func render(encoder: any MTLRenderCommandEncoder) {
        // mainTexture: fragment texture binding at 0
        // color: baseUniform.color -> uses color when main texture is nil

        let vertices: [MainVertex] = [
            MainVertex(position: f3(1, 0, 0), normal: f3(0, 0, 1), uv: f2(0, 0)),
            MainVertex(position: f3(1, 1, 0), normal: f3(0, 0, 1), uv: f2(0, 0)),
            MainVertex(position: f3(0, 1, 0), normal: f3(0, 0, 1), uv: f2(0, 0)),
            MainVertex(position: f3(1, 0, 0), normal: f3(0, 0, 1), uv: f2(0, 0)),
            MainVertex(position: f3(0, 1, 0), normal: f3(0, 0, 1), uv: f2(0, 0)),
            MainVertex(position: f3(0, 0, 0), normal: f3(0, 0, 1), uv: f2(0, 0)),
        ]
        baseUniform.color = f4(1, 1, 0, 1)
        encoder.setVertexBytes(vertices, length: MainVertex.memorySize * vertices.count, index: 0)
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertices.count)
    }
}
