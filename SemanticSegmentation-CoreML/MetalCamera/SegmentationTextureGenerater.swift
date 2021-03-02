//
//  AlphaBlend.swift → SegmentationTextureGenerater.swift
//  MetalCamera → SemanticSegmentation-CoreML
//
//  Created by Eric on 2020/06/16.
//  Updated by Doyoung Gwak on 2020/11/16.
//

import MetalKit
import CoreML

class SegmentationTextureGenerater: NSObject {
    
    private var pipelineState: MTLRenderPipelineState!
    private var render_target_vertex: MTLBuffer!
    private var render_target_uniform: MTLBuffer!
    
    private func setupPiplineState(_ colorPixelFormat: MTLPixelFormat = .bgra8Unorm, width: Int, height: Int) {
        do {
            let rpd = try sharedMetalRenderingDevice.generateRenderPipelineDescriptor("vertex_render_target",
                                                                                      "segmentation_render_target",
                                                                                      colorPixelFormat)
            pipelineState = try sharedMetalRenderingDevice.device.makeRenderPipelineState(descriptor: rpd)

            render_target_vertex = sharedMetalRenderingDevice.makeRenderVertexBuffer(size: CGSize(width: width, height: height))
            render_target_uniform = sharedMetalRenderingDevice.makeRenderUniformBuffer(CGSize(width: width, height: height))
        } catch {
            debugPrint(error)
        }
    }
    
    func texture(_ segmentationMap: MLMultiArray, _ row: Int, _ col: Int, _ targetClass: Int) -> Texture? {
        if pipelineState == nil {
            setupPiplineState(width: col, height: row)
        }

        let outputTexture = Texture(col, row, textureKey: "segmentation")

        let renderPassDescriptor = MTLRenderPassDescriptor()
        let attachment = renderPassDescriptor.colorAttachments[0]
        attachment?.clearColor = .red
        attachment?.texture = outputTexture.texture
        attachment?.loadAction = .clear
        attachment?.storeAction = .store

        let commandBuffer = sharedMetalRenderingDevice.commandQueue.makeCommandBuffer()
        let commandEncoder = commandBuffer?.makeRenderCommandEncoder(descriptor: renderPassDescriptor)

        commandEncoder?.setRenderPipelineState(pipelineState)

        commandEncoder?.setVertexBuffer(render_target_vertex, offset: 0, index: 0)
        commandEncoder?.setVertexBuffer(render_target_uniform, offset: 0, index: 1)

        let segmentationBuffer = sharedMetalRenderingDevice.device.makeBuffer(bytes: segmentationMap.dataPointer,
                                                                              length: segmentationMap.count * MemoryLayout<Int32>.size,
                                                                              options: [])!
        commandEncoder?.setFragmentBuffer(segmentationBuffer, offset: 0, index: 0)

        let uniformBuffer = sharedMetalRenderingDevice.device.makeBuffer(bytes: [Int32(targetClass), Int32(col), Int32(row)] as [Int32],
                                                                         length: 3 * MemoryLayout<Int32>.size,
                                                                         options: [])!
        commandEncoder?.setFragmentBuffer(uniformBuffer, offset: 0, index: 1)

        commandEncoder?.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        commandEncoder?.endEncoding()
        commandBuffer?.commit()

        return outputTexture
    }
}

extension MTLClearColor {
    static var red: Self {
        return MTLClearColorMake(1, 0, 0, 1) // r, g, b, a
    }
}
