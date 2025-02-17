//
//  ShaderView.swift
//  ShaderView
//
//  Created by Yuki Kuwashima on 2025/02/17.
//

import SwiftUI
import MetalKit

#if os(macOS)

/**
 A SwiftUI representable view that integrates a Metal-based 3D sketch into a SwiftUI hierarchy.

 The SketchView wraps a MetalKit view (MTKView) configured for 3D rendering using a custom renderer
 (Renderer3D) and sketch (Sketch3D). This allows 3D content rendered by Metal to be embedded in SwiftUI apps.
 */
public struct ShaderView: NSViewRepresentable {

    /// The renderer responsible for managing the 3D rendering loop.
    let renderer: RendererBase

    /**
     Initializes a new SketchView with the provided Sketch3D instance.

     - Parameter sketch: The Sketch3D instance that defines the 3D scene and rendering behavior.
     */
    public init(_ renderer: RendererBase) {
        self.renderer = renderer
    }

    /**
     Creates the underlying NSView (an MTKView) used for rendering the 3D content.

     This method is called once by SwiftUI when the view is first created.

     - Parameter context: The context provided by SwiftUI.
     - Returns: An MTKView configured with the custom renderer for 3D rendering.
     */
    public func makeNSView(context: Context) -> MTKView {
        let mtkView = TouchableMTKView(renderer: renderer)
        return mtkView
    }

    /**
     Updates the NSView when the SwiftUI state changes.

     In this implementation, no dynamic updates are necessary, so this method is left empty.

     - Parameters:
       - nsView: The MTKView to update.
       - context: The context provided by SwiftUI.
     */
    public func updateNSView(_ nsView: MTKView, context: Context) {}
}

#else

public struct ShaderView: UIViewRepresentable {

    /// The renderer responsible for managing the 3D rendering loop.
    let renderer: RendererBase

    /**
     Initializes a new SketchView with the provided Sketch3D instance.

     - Parameter sketch: The Sketch3D instance that defines the 3D scene and rendering behavior.
     */
    public init(_ renderer: RendererBase) {
        self.renderer = renderer
    }

    /**
     Creates the underlying NSView (an MTKView) used for rendering the 3D content.

     This method is called once by SwiftUI when the view is first created.

     - Parameter context: The context provided by SwiftUI.
     - Returns: An MTKView configured with the custom renderer for 3D rendering.
     */
    public func makeUIView(context: Context) -> MTKView {
        let mtkView = TouchableMTKView(renderer: renderer)
        return mtkView
    }

    /**
     Updates the NSView when the SwiftUI state changes.

     In this implementation, no dynamic updates are necessary, so this method is left empty.

     - Parameters:
       - nsView: The MTKView to update.
       - context: The context provided by SwiftUI.
     */
    public func updateUIView(_ uiView: MTKView, context: Context) {}
}

#endif
