//
//  LiveFaceDetectionAndFaceParsingViewController.swift
//  SemanticSegmentation-CoreML
//
//  Created by Doyoung Gwak on 2021/03/19.
//  Copyright © 2021 Doyoung Gwak. All rights reserved.
//

import UIKit
import Vision

class LiveFaceDetectionAndFaceParsingViewController: UIViewController {

    @IBOutlet weak var cameraMetalVideoView: MetalVideoView?
    @IBOutlet weak var faceCropepdMetalView: MetalVideoView?
    @IBOutlet weak var faceParsedMetalView: MetalVideoView?
    
    var cameraTextureGenerater = CameraTextureGenerater()
    var croppedTextureGenerater = CroppedTextureGenerater()
    var multitargetSegmentationTextureGenerater = MultitargetSegmentationTextureGenerater()
    var overlayingTexturesGenerater = OverlayingTexturesGenerater()
    
    // MARK: - Vision Properties
    var segmentationRequest: VNCoreMLRequest?
    var visionModel: VNCoreMLModel?
    var detectionRequest: VNDetectFaceRectanglesRequest?
    
    // MARK: -
    var faceRectHistory: [CGRect] = []
    let maximumFaceRectNumber = 7 // optimized in iPhone 11 Pro device
    
    // MARK: - AV Properties
    var videoCapture: VideoCapture!
    
    @available(iOS 14.0, *)
    lazy var segmentationModel: FaceParsing = {
        let model = try! FaceParsing()
        return model
    }()
    let numberOfLabels = 19 // <#if you changed the segmentationModel, you have to change the numberOfLabels#>
    
    var isInferencing = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // setup ml model
        setUpModel()
        
        // setup camera
        setUpCamera()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.videoCapture.start()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.videoCapture.stop()
    }
    
    // MARK: - Setup Core ML
    func setUpModel() {
        // face detector
        self.detectionRequest = VNDetectFaceRectanglesRequest()
        
        // face parsing semantic segmentation
        if #available(iOS 14.0, *) {
            if let visionModel = try? VNCoreMLModel(for: segmentationModel.model) {
                self.visionModel = visionModel
                segmentationRequest = VNCoreMLRequest(model: visionModel)
                segmentationRequest?.imageCropAndScaleOption = .centerCrop
            } else {
                fatalError()
            }
        } else {
            // Fallback on earlier versions
        }
    }
    
    // MARK: - Setup camera
    func setUpCamera() {
        videoCapture = VideoCapture()
        videoCapture.delegate = self
        videoCapture.fps = 50
        videoCapture.setUpCamera(sessionPreset: .vga640x480, position: .front) { (success) in
            if success {
                // 초기설정이 끝나면 라이브 비디오를 시작할 수 있음
                self.videoCapture.start()
            }
        }
    }
}

// MARK: - VideoCaptureDelegate
extension LiveFaceDetectionAndFaceParsingViewController: VideoCaptureDelegate {
    func videoCapture(_ capture: VideoCapture, didCaptureVideoSampleBuffer sampleBuffer: CMSampleBuffer) {
        
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        if !isInferencing {
            // predict!
            predict(with: pixelBuffer)
        }
    }
}

// MARK: - Inference
extension LiveFaceDetectionAndFaceParsingViewController {
    // prediction
    func predict(with pixelBuffer: CVPixelBuffer) {
        // ==================================================
        // 1. rendering camera frame
        // ==================================================
        guard let cameraTexture = cameraTextureGenerater.texture(from: pixelBuffer) else { return }
        cameraMetalVideoView?.currentTexture = cameraTexture
        
        guard !isInferencing else { return }
        isInferencing = true
        
        // ==================================================
        // 2. face detection and rendering cropped face frame
        // ==================================================
        guard let request = detectionRequest else { fatalError() }
        let imageRequestHandler: VNImageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer)
        try? imageRequestHandler.perform([request])
        
        guard let faceDetectionObservations = request.results as? [VNFaceObservation] else { fatalError() }
        
        guard let boundingbox = faceDetectionObservations.map({ $0.boundingBox }).first else {
            faceCropepdMetalView?.currentTexture = nil
            faceParsedMetalView?.currentTexture = nil
            isInferencing = false
            return
        }
        
        let width = cameraTexture.texture.width
        let height = cameraTexture.texture.height
        
        let cgBoundingBox = convertBoundingBoxForTexture(rect: boundingbox, width: CGFloat(width), height: CGFloat(height))
        let expanedBoundingBox = cgBoundingBox.scaledFromCenterPoint(scaleX: 1.8, scaleY: 1.8)
        faceRectHistory.append(expanedBoundingBox)
        if faceRectHistory.count >= maximumFaceRectNumber {
            faceRectHistory.removeFirst()
        }
        let averagedBoundingBox = faceRectHistory.average
        
        guard let croppedFaceTexture = croppedTextureGenerater.texture(cameraTexture, averagedBoundingBox) else {
            faceCropepdMetalView?.currentTexture = nil
            faceParsedMetalView?.currentTexture = nil
            isInferencing = false
            return
        }
        faceCropepdMetalView?.currentTexture = croppedFaceTexture
        
        // ==================================================
        // 3. face-parsing semantic segemtation and rendering it
        // ==================================================
        guard let segmentationRequest = segmentationRequest else { fatalError() }
        guard let ciImage = CIImage(mtlTexture: croppedFaceTexture.texture)?.oriented(CGImagePropertyOrientation.downMirrored) else { fatalError() }
        
        let segmentationHandler = VNImageRequestHandler(ciImage: ciImage)
        try? segmentationHandler.perform([segmentationRequest])
        
        // post-processing
        guard let segmentationObservations = segmentationRequest.results as? [VNCoreMLFeatureValueObservation],
              let segmentationmap = segmentationObservations.first?.featureValue.multiArrayValue,
              let row = segmentationmap.shape[0] as? Int,
              let col = segmentationmap.shape[1] as? Int else { fatalError() }
            
        guard let segmentationTexture = multitargetSegmentationTextureGenerater.texture(segmentationmap, row, col, numberOfLabels) else {
            return
        }
        
        let overlayedTexture = overlayingTexturesGenerater.texture(croppedFaceTexture, segmentationTexture)
        faceParsedMetalView?.currentTexture = overlayedTexture
        
        isInferencing = false
    }
    
    func convertBoundingBoxForTexture(rect: CGRect, width: CGFloat, height: CGFloat) -> CGRect {
        let transform = CGAffineTransform(scaleX: 1, y: -1).translatedBy(x: 0, y: -1)
        let translate = CGAffineTransform.identity.scaledBy(x: width, y: height)
        return rect.applying(transform).applying(translate)
    }
}

extension CGRect {
    var centerPoint: CGPoint {
        return CGPoint(x: origin.x + size.width/2, y: origin.y + size.height/2)
    }
    
    func scaledFromCenterPoint(scaleX: CGFloat, scaleY: CGFloat) -> CGRect {
        let newWidth = (size.width * scaleX)
        let newHeight = (size.height * scaleY)
        return CGRect(x: centerPoint.x - newWidth/2, y: centerPoint.y - newHeight/2, width: newWidth, height: newHeight)
    }
}

extension Array where Element == CGRect {
    var average: CGRect {
        let x1y1x2y2 = reduce((0.0, 0.0, 0.0, 0.0)) {
            return ($0.0 + $1.origin.x, $0.1 + $1.origin.y, $0.2 + $1.origin.x + $1.size.width, $0.3 + $1.origin.y + $1.size.height)
        }
        return CGRect(origin: CGPoint(x: x1y1x2y2.0 / CGFloat(count), y: x1y1x2y2.1 / CGFloat(count)),
                      size: CGSize(width: (x1y1x2y2.2 - x1y1x2y2.0) / CGFloat(count), height: (x1y1x2y2.3 - x1y1x2y2.1) / CGFloat(count)))
    }
}
