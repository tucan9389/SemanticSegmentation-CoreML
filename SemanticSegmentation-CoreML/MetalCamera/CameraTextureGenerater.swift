//
//  MetalCamera.swift → CameraTextureGenerater.swift
//  MetalCamera → SemanticSegmentation-CoreML
//
//  Created by Eric on 2020/06/06.
//  Updated by Doyoung Gwak on 2020/11/16.
//

import CoreMedia

class CameraTextureGenerater: NSObject {
    
    public let sourceKey: String
    var videoTextureCache: CVMetalTextureCache?
    
    public init(sourceKey: String = "camera") {
        self.sourceKey = sourceKey
        super.init()

        CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, sharedMetalRenderingDevice.device, nil, &videoTextureCache)
    }
    
    func texture(from cameraFrame: CVPixelBuffer) -> Texture? {
        guard let videoTextureCache = videoTextureCache else { return nil }

        let bufferWidth = CVPixelBufferGetWidth(cameraFrame)
        let bufferHeight = CVPixelBufferGetHeight(cameraFrame)

        var textureRef: CVMetalTexture? = nil
        let _ = CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                          videoTextureCache,
                                                          cameraFrame,
                                                          nil,
                                                          .bgra8Unorm,
                                                          bufferWidth,
                                                          bufferHeight,
                                                          0,
                                                          &textureRef)
        if let concreteTexture = textureRef,
            let cameraTexture = CVMetalTextureGetTexture(concreteTexture) {
            return Texture(texture: cameraTexture, textureKey: self.sourceKey)
        } else {
            return nil
        }
    }
    
    func texture(from sampleBuffer: CMSampleBuffer) -> Texture? {
        guard let cameraFrame = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil }
        return texture(from: cameraFrame)
    }
}
