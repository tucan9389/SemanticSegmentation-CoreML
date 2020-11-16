//
//  MetalRenderingDevice.swift
//  MetalCamera
//
//  Created by Eric on 2020/06/04.
//

import CoreGraphics
import Metal

public let sharedMetalRenderingDevice = MetalRenderingDevice()

public class MetalRenderingDevice {
    public let device: MTLDevice
    public let commandQueue: MTLCommandQueue

    init() {
        guard let device = MTLCreateSystemDefaultDevice() else { fatalError("Could not create Metal Device") }
        self.device = device

        guard let queue = self.device.makeCommandQueue() else { fatalError("Could not create command queue") }
        self.commandQueue = queue
    }

    func generateRenderPipelineDescriptor(_ vertexFuncName: String, _ fragmentFuncName: String, _ colorPixelFormat: MTLPixelFormat = .bgra8Unorm) throws -> MTLRenderPipelineDescriptor {
        let framework = Bundle.main
        let resource = framework.path(forResource: "default", ofType: "metallib")!
        let library = try self.device.makeLibrary(filepath: resource)

        let vertex_func = library.makeFunction(name: vertexFuncName)
        let fragment_func = library.makeFunction(name: fragmentFuncName)
        let rpd = MTLRenderPipelineDescriptor()
        rpd.vertexFunction = vertex_func
        rpd.fragmentFunction = fragment_func
        rpd.colorAttachments[0].pixelFormat = colorPixelFormat

        return rpd
    }

    func makeRenderVertexBuffer(_ origin: CGPoint = .zero, size: CGSize) -> MTLBuffer? {
        let w = size.width, h = size.height
        let vertices = [
            Vertex(position: CGPoint(x: origin.x , y: origin.y), textCoord: CGPoint(x: 0, y: 0)),
            Vertex(position: CGPoint(x: origin.x + w , y: origin.y), textCoord: CGPoint(x: 1, y: 0)),
            Vertex(position: CGPoint(x: origin.x + 0 , y: origin.y + h), textCoord: CGPoint(x: 0, y: 1)),
            Vertex(position: CGPoint(x: origin.x + w , y: origin.y + h), textCoord: CGPoint(x: 1, y: 1)),
        ]
        return makeRenderVertexBuffer(vertices)
    }

    func makeRenderVertexBuffer(_ vertices: [Vertex]) -> MTLBuffer? {
        return self.device.makeBuffer(bytes: vertices, length: MemoryLayout<Vertex>.stride * vertices.count, options: .cpuCacheModeWriteCombined)
    }

    func makeRenderUniformBuffer(_ size: CGSize) -> MTLBuffer? {
        let metrix = Matrix.identity
        metrix.scaling(x: 2 / Float(size.width), y: -2 / Float(size.height), z: 1)
        metrix.translation(x: -1, y: 1, z: 0)
        return self.device.makeBuffer(bytes: metrix.m, length: MemoryLayout<Float>.size * 16, options: [])
    }
}
