//
//  RendererBase.swift
//  ShaderView
//
//  Created by Yuki Kuwashima on 2025/02/17.
//

import MetalKit
import TransformUtils

open class RendererBase: NSObject, MTKViewDelegate {

    private static let optimalTileSize = MTLSize(width: 32, height: 16, depth: 1)

    /// The camera used for 3D viewing. Its frame is initially set to 1×1.
    public var camera: Camera = Camera(frameWidth: 1, frameHeight: 1)

    /// The configuration for the 3D sketch, including camera type and scaling factor.
    public var configuration: CameraConfiguration = CameraConfiguration(cameraType: .orbit, scaleFactor: 2)

    /// The current mouse position, stored as a 2-component vector (optional).
    public var mousePosition: f2?

    private var revealTexture: MTLTexture?

    public var elapsed: Float = 0

    public var startDate: Date = Date()

    public var baseUniform: BaseUniform = BaseUniform(
        projectionMatrix: .identity,
        viewMatrix: .identity,
        viewMatrixInverse: .identity,
        modelToWorldMatrix: .identity,
        modelToWorldMatrixInverse: .identity,
        modelToWorldNormalMatrix: .identity
    )

    internal var frameSize: f2 = .one {
        didSet {
            camera.setFrame(width: frameSize.x * configuration.scaleFactor, height: frameSize.y * configuration.scaleFactor)
        }
    }

    public override init() {
        super.init()
    }

    public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        frameSize = size.f2Value
    }

    public func draw(in view: MTKView) {
        guard let drawable = view.currentDrawable else { return }
        let commandBuffer = Library.commandQueue.makeCommandBuffer()!

        draw(commandBuffer: commandBuffer, drawableTexture: drawable.texture)

        commandBuffer.present(drawable)
        commandBuffer.commit()
    }

    open func draw(commandBuffer: MTLCommandBuffer, drawableTexture: MTLTexture) {

        if revealTexture == nil || revealTexture?.width != drawableTexture.width || revealTexture?.height != drawableTexture.height {
            revealTexture = Self.createTexture(width: drawableTexture.width, height: drawableTexture.height, pixelFormat: drawableTexture.pixelFormat, label: "reveal tex", isRenderTarget: true)
        }

        elapsed = Float(Date().timeIntervalSince(startDate))

        let computeEncoder = commandBuffer.makeComputeCommandEncoder()!
        compute(encoder: computeEncoder)
        computeEncoder.endEncoding()

        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = drawableTexture
        renderPassDescriptor.colorAttachments[0].clearColor = .init(red: 0, green: 0, blue: 0, alpha: 0)
        renderPassDescriptor.colorAttachments[0].loadAction = .load
        renderPassDescriptor.colorAttachments[0].storeAction = .store
        
        renderPassDescriptor.tileWidth = Self.optimalTileSize.width
        renderPassDescriptor.tileHeight = Self.optimalTileSize.height
        renderPassDescriptor.imageblockSampleLength = Library.resolvePipelineState.imageblockSampleLength
        renderPassDescriptor.colorAttachments[0].loadAction = .clear

        // Create a render command encoder.
        let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!

        encoder.setRenderPipelineState(Library.clearPipelineState)
        encoder.dispatchThreadsPerTile(Self.optimalTileSize)
        encoder.setCullMode(.none)
        encoder.setRenderPipelineState(Library.mainRenderPipelineState)

        // Pass the uniform data to the vertex shader.
        encoder.setVertexBytes([baseUniform], length: MemoryLayout<BaseUniform>.stride, index: 10)

        // Update uniform values based on the current camera state.
        baseUniform.projectionMatrix = camera.perspectiveMatrix
        baseUniform.viewMatrix = camera.viewMatrix
        baseUniform.viewMatrixInverse = camera.viewMatrix.inverse
        baseUniform.modelToWorldMatrix = .identity
        baseUniform.modelToWorldNormalMatrix = .identity

        // Invoke the sketch's custom drawing routine.
        render(encoder: encoder)

        // End encoding and commit the command buffer.
        encoder.setRenderPipelineState(Library.resolvePipelineState)
        encoder.dispatchThreadsPerTile(Self.optimalTileSize)
        encoder.endEncoding()
    }

    open func compute(encoder: MTLComputeCommandEncoder) {}
    open func render(encoder: MTLRenderCommandEncoder) {}

    public static func createTexture(width: Int, height: Int, pixelFormat: MTLPixelFormat, label: String?, isRenderTarget: Bool = true) -> MTLTexture {
        let descriptor = MTLTextureDescriptor()
        descriptor.pixelFormat = pixelFormat
        descriptor.textureType = .type2D
        descriptor.width = width
        descriptor.height = height
        if isRenderTarget {
            descriptor.usage = [.shaderRead, .shaderWrite, .renderTarget]
        } else {
            descriptor.usage = [.shaderRead, .shaderWrite]
        }
        descriptor.resourceOptions = .storageModePrivate
        let texture = Library.device.makeTexture(descriptor: descriptor)!
        texture.label = label
        return texture
    }

    open func mouseDown() {}
    open func mouseMoved(delta: f2?) {}
    open func mouseDragged(delta: f2?) {}
    open func mouseUp() {}
    open func scrollWheel(delta: f2) {}
    open func mouseEntered() {}
    open func mouseExited() {}
    open func keyDown(keyCode: UInt16) {}
    open func keyUp() {}
}
