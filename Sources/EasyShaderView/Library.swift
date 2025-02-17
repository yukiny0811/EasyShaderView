//
//  Library.swift
//  ShaderView
//
//  Created by Yuki Kuwashima on 2025/02/17.
//

@preconcurrency import MetalKit
import TransformUtils

/**
 An enumeration encapsulating Metal-related objects and configurations for rendering.

 This library provides shared access to the Metal device, default library, command queue,
 render pipeline states, depth-stencil states, and vertex descriptors. It centralizes
 resource creation and configuration for use throughout the rendering system.
 */
public enum Library {

    /// The default Metal device for the system.
    static let device = MTLCreateSystemDefaultDevice()!

    /// The default Metal library loaded from the main bundle.
    static let library = try! device.makeDefaultLibrary(bundle: .module)

    /// The command queue used to schedule and execute rendering commands.
    public static let commandQueue = device.makeCommandQueue()!

    static let depthStencilState: MTLDepthStencilState = {
        let depthStateDesc = Self.createDepthStencilDescriptor(compareFunc: .less, writeDepth: false)
        return device.makeDepthStencilState(descriptor: depthStateDesc)!
    }()

    static let constantValue = MTLFunctionConstantValues()

    /// The main render pipeline state used for rendering, configured with vertex and fragment functions,
    /// vertex descriptor, and appropriate pixel formats for color, depth, and stencil attachments.
    static let mainRenderPipelineState: MTLRenderPipelineState = {
        let desc = MTLRenderPipelineDescriptor()
        desc.vertexFunction = library.makeFunction(name: "main_vert")!
        desc.fragmentFunction = try! library.makeFunction(name: "OITFragmentFunction_4Layer", constantValues: constantValue)
        desc.vertexDescriptor = MainVertex.generateVertexDescriptor()
        desc.rasterSampleCount = 1
        desc.colorAttachments[0].pixelFormat = .bgra8Unorm
        desc.colorAttachments[0].isBlendingEnabled = false

        desc.depthAttachmentPixelFormat = .depth32Float_stencil8
        desc.stencilAttachmentPixelFormat = .depth32Float_stencil8

        return try! device.makeRenderPipelineState(descriptor: desc)
    }()

    static let resolvePipelineState: MTLRenderPipelineState = {
        let tileDesc = MTLTileRenderPipelineDescriptor()
        tileDesc.tileFunction = try! library.makeFunction(name: "OITResolve_4Layer", constantValues: constantValue)
        tileDesc.colorAttachments[0].pixelFormat = .bgra8Unorm
        tileDesc.threadgroupSizeMatchesTileSize = true
        return try! device.makeRenderPipelineState(tileDescriptor: tileDesc, options: .bindingInfo, reflection: nil)
    }()

    static let clearPipelineState: MTLRenderPipelineState = {
        let tileDesc = MTLTileRenderPipelineDescriptor()
        tileDesc.tileFunction = try! library.makeFunction(name: "OITClear_4Layer", constantValues: constantValue)
        tileDesc.colorAttachments[0].pixelFormat = .bgra8Unorm
        tileDesc.threadgroupSizeMatchesTileSize = true
        return try! device.makeRenderPipelineState(tileDescriptor: tileDesc, options: .bindingInfo, reflection: nil)
    }()

    static let compositeKernelState: MTLComputePipelineState = try! device.makeComputePipelineState(function: library.makeFunction(name: "composite")!)

    /**
     Creates a depth-stencil descriptor with the specified depth compare function and depth writing option.

     - Parameters:
       - compareFunc: The depth comparison function to use.
       - writeDepth: A Boolean value indicating whether depth writing is enabled.
     - Returns: A configured `MTLDepthStencilDescriptor`.
     */
    private static func createDepthStencilDescriptor(compareFunc: MTLCompareFunction, writeDepth: Bool) -> MTLDepthStencilDescriptor {
        let depthStateDesc = MTLDepthStencilDescriptor()
        depthStateDesc.depthCompareFunction = compareFunc
        depthStateDesc.isDepthWriteEnabled = writeDepth
        return depthStateDesc
    }
}
