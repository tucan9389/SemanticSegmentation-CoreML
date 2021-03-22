//
//  CroppedTextureGenerater.swift
//  SemanticSegmentation-CoreML
//
//  Created by Doyoung Gwak on 2021/03/12.
//  Copyright © 2021 Doyoung Gwak. All rights reserved.
//

import MetalKit
import MetalPerformanceShaders

class CroppedTextureGenerater: NSObject {
    
    func texture(_ source1: Texture, _ sourceRegion: CGRect) -> Texture? {
        let destRegion = sourceRegion
        let outputTexture = Texture(Int(destRegion.width), Int(destRegion.height), textureKey: "cropping")
        
        let scaleX = Double(destRegion.size.width) / Double(sourceRegion.size.width)
        let scaleY = Double(destRegion.size.height) / Double(sourceRegion.size.height)
        let translateX = Double(-sourceRegion.origin.x) * scaleX
        let translateY = Double(-sourceRegion.origin.y) * scaleY
        let filter = MPSImageLanczosScale(device: sharedMetalRenderingDevice.device)
        var transform = MPSScaleTransform(scaleX: scaleX, scaleY: scaleY, translateX: translateX, translateY: translateY)
        let commandBuffer = sharedMetalRenderingDevice.commandQueue.makeCommandBuffer()
        withUnsafePointer(to: &transform) { (transformPtr: UnsafePointer<MPSScaleTransform>) -> () in
            filter.scaleTransform = transformPtr
            filter.encode(commandBuffer: commandBuffer!, sourceTexture: source1.texture, destinationTexture: outputTexture.texture)
        }
        commandBuffer?.commit()
        
        return outputTexture
    }
}
