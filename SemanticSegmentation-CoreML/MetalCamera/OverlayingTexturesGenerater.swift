//
//  OverlayingTexturesGenerater.swift
//  SemanticSegmentation-CoreML
//
//  Created by Eric on 2020/06/06.
//  Copyright © 2020 Eric. All rights reserved.
//

import MetalKit

public let standardImageVertices: [Float] = [-1.0, 1.0, 1.0, 1.0, -1.0, -1.0, 1.0, -1.0]
public let standardTextureCoordinate: [Float] = [0.0, 0.0, 1.0, 0.0, 0.0, 1.0, 1.0, 1.0]

class OverlayingTexturesGenerater: NSObject {
    
    private var pipelineState: MTLRenderPipelineState!
    
    private var textureBuffer1: MTLBuffer?
    private var textureBuffer2: MTLBuffer?
    
    public var alphaValue: Float = 0.5
    
    public override init() {
        super.init()
        setup()
    }

    private func setup() {
        setupPiplineState()
    }

    private func setupPiplineState(_ colorPixelFormat: MTLPixelFormat = .bgra8Unorm) {
        do {
            let rpd = try sharedMetalRenderingDevice.generateRenderPipelineDescriptor("two_vertex_render_target",
                                                                                      "alphaBlendFragment",
                                                                                      colorPixelFormat)
            pipelineState = try sharedMetalRenderingDevice.device.makeRenderPipelineState(descriptor: rpd)
        } catch {
            debugPrint(error)
        }
    }
    
    private func generateTextureBuffer(_ width: Int, _ height: Int, _ targetWidth: Int, _ targetHeight: Int) -> MTLBuffer? {
        let targetRatio = Float(targetWidth)/Float(targetHeight)
        let curRatio = Float(width)/Float(height)

        let coordinates: [Float]

        if targetRatio > curRatio {
            let remainHeight = (Float(height) - Float(width) * targetRatio)/2.0
            let remainRatio = remainHeight/Float(height)
            coordinates = [0.0, remainRatio, 1.0, remainRatio, 0.0, 1.0 - remainRatio, 1.0, 1.0 - remainRatio]
        } else {
            let remainWidth = (Float(width) - Float(height) * targetRatio)/2.0
            let remainRatio = remainWidth/Float(width)
            coordinates = [remainRatio, 0.0, 1.0 - remainRatio, 0.0, remainRatio, 1.0, 1.0 - remainRatio, 1.0]
        }

        let textureBuffer = sharedMetalRenderingDevice.device.makeBuffer(bytes: coordinates,
                                                                         length: coordinates.count * MemoryLayout<Float>.size,
                                                                         options: [])!
        return textureBuffer
    }
    
    func texture(_ source1: Texture, _ source2: Texture) -> Texture? {
        let minX = min(source1.texture.width, source2.texture.width)
        let minY = min(source1.texture.height, source2.texture.height)
        
        // 버퍼 준비
        if textureBuffer1 == nil {
            textureBuffer1 = generateTextureBuffer(source1.texture.width, source1.texture.height, minX, minY)
        }
        if textureBuffer2 == nil {
            textureBuffer2 = generateTextureBuffer(source2.texture.width, source2.texture.height, minX, minY)
        }

        let outputTexture = Texture(minX, minY, textureKey: source1.textureKey)

        let renderPassDescriptor = MTLRenderPassDescriptor()
        let attachment = renderPassDescriptor.colorAttachments[0]
        attachment?.clearColor = MTLClearColorMake(1, 0, 0, 1)
        attachment?.texture = outputTexture.texture
        attachment?.loadAction = .clear
        attachment?.storeAction = .store
        
        // command buffer 준비
        let commandBuffer = sharedMetalRenderingDevice.commandQueue.makeCommandBuffer()
        // command encoder 생성
        let commandEncoder = commandBuffer?.makeRenderCommandEncoder(descriptor: renderPassDescriptor)

        commandEncoder?.setFrontFacing(.counterClockwise)
        commandEncoder?.setRenderPipelineState(pipelineState)
        
        // vertex buffer 준비
        let vertexBuffer = sharedMetalRenderingDevice.device.makeBuffer(bytes: standardImageVertices,
                                                                        length: standardImageVertices.count * MemoryLayout<Float>.size,
                                                                        options: [])!
        vertexBuffer.label = "Vertices"
        commandEncoder?.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        commandEncoder?.setVertexBuffer(textureBuffer1, offset: 0, index: 1)
        commandEncoder?.setVertexBuffer(textureBuffer2, offset: 0, index: 2)

        // fragment texture, buffer 준비
        commandEncoder?.setFragmentTexture(source1.texture, index: 0)
        commandEncoder?.setFragmentTexture(source2.texture, index: 1)
        let uniformBuffer = sharedMetalRenderingDevice.device.makeBuffer(bytes: [alphaValue],
                                                                         length: 1 * MemoryLayout<Float>.size,
                                                                         options: [])!
        commandEncoder?.setFragmentBuffer(uniformBuffer, offset: 0, index: 1)
        
        // privitive 설정
        commandEncoder?.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        // command encoder 끝
        commandEncoder?.endEncoding()
        // 실행
        commandBuffer?.commit()
        
        return outputTexture
    }
}
