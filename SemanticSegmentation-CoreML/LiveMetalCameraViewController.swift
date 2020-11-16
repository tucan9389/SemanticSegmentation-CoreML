//
//  LiveMetalCameraViewController.swift
//  SemanticSegmentation-CoreML
//
//  Created by Doyoung Gwak on 2020/11/16.
//  Copyright © 2020 Doyoung Gwak. All rights reserved.
//

import UIKit
import Vision

class LiveMetalCameraViewController: UIViewController {

    // MARK: - UI Properties
    @IBOutlet weak var metalVideoPreview: MetalVideoView!
    @IBOutlet weak var drawingView: DrawingSegmentationView!
    
    @IBOutlet weak var inferenceLabel: UILabel!
    @IBOutlet weak var etimeLabel: UILabel!
    @IBOutlet weak var fpsLabel: UILabel!
    
    var cameraTextureGenerater = CameraTextureGenerater()
    var segmentationTextureGenerater = SegmentationTextureGenerater()
    var overlayingTexturesGenerater = OverlayingTexturesGenerater()
    
    var cameraTexture: Texture?
    var segmentationTexture: Texture?
    
    // MARK: - AV Properties
    var videoCapture: VideoCapture!
    
    // MARK - Core ML model
    // DeepLabV3(iOS12+), DeepLabV3FP16(iOS12+), DeepLabV3Int8LUT(iOS12+)
    let segmentationModel = DeepLabV3Int8LUT()

//    11 Pro
//    DeepLabV3        : 37 465 1
//    DeepLabV3FP16    : 40 511 1
//    DeepLabV3Int8LUT : 40 520 1
//
//    XS
//    DeepLabV3        : 135 409 2
//    DeepLabV3FP16    : 136 403 2
//    DeepLabV3Int8LUT : 135 412 2
//
//    X
//    DeepLabV3        : 177 531 1
//    DeepLabV3FP16    : 177 530 1
//    DeepLabV3Int8LUT : 177 517 1
    
    // MARK: - Vision Properties
    var request: VNCoreMLRequest?
    var visionModel: VNCoreMLModel?
    
    var isInferencing = false
    
    // MARK: - Performance Measurement Property
    private let 👨‍🔧 = 📏()
    
    let maf1 = MovingAverageFilter()
    let maf2 = MovingAverageFilter()
    let maf3 = MovingAverageFilter()
    
    // MARK: - View Controller Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // setup ml model
        setUpModel()
        
        // setup camera
        setUpCamera()
        
        // setup delegate for performance measurement
        👨‍🔧.delegate = self
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
        if let visionModel = try? VNCoreMLModel(for: segmentationModel.model) {
            self.visionModel = visionModel
            request = VNCoreMLRequest(model: visionModel, completionHandler: visionRequestDidComplete)
            request?.imageCropAndScaleOption = .centerCrop
        } else {
            fatalError()
        }
    }
    
    // MARK: - Setup camera
    func setUpCamera() {
        videoCapture = VideoCapture()
        videoCapture.delegate = self
        videoCapture.fps = 50
        videoCapture.setUp(sessionPreset: .hd1280x720) { success in
            
            if success {
                // UI에 비디오 미리보기 뷰 넣기
//                if let previewLayer = self.videoCapture.previewLayer {
//                    self.videoPreview.layer.addSublayer(previewLayer)
//                    self.resizePreviewLayer()
//                }
                
                // 초기설정이 끝나면 라이브 비디오를 시작할 수 있음
                self.videoCapture.start()
            }
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // resizePreviewLayer()
    }
    
//    func resizePreviewLayer() {
//        videoCapture.previewLayer?.frame = videoPreview.bounds
//    }
}

// MARK: - VideoCaptureDelegate
extension LiveMetalCameraViewController: VideoCaptureDelegate {
    func videoCapture(_ capture: VideoCapture, didCaptureVideoSampleBuffer sampleBuffer: CMSampleBuffer) {
        
        // 카메라 프리뷰 텍스쳐
        cameraTexture = cameraTextureGenerater.texture(from: sampleBuffer)
        
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        if !isInferencing {
            isInferencing = true

            // start of measure
            self.👨‍🔧.🎬👏()

            // predict!
            predict(with: pixelBuffer)
        }
    }
}

// MARK: - Inference
extension LiveMetalCameraViewController {
    // prediction
    func predict(with pixelBuffer: CVPixelBuffer) {
        guard let request = request else { fatalError() }
        
        // vision framework configures the input size of image following our model's input configuration automatically
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        try? handler.perform([request])
    }
    
    // post-processing
    func visionRequestDidComplete(request: VNRequest, error: Error?) {
        self.👨‍🔧.🏷(with: "endInference")
        
        if let observations = request.results as? [VNCoreMLFeatureValueObservation],
            let segmentationmap = observations.first?.featureValue.multiArrayValue {
            
            guard let row = segmentationmap.shape[0] as? Int,
                let col = segmentationmap.shape[1] as? Int else {
                    return
            }
            
            let targetClass = 15 // index of human category
            
            guard let cameraTexture = cameraTexture,
                  let segmentationTexture = segmentationTextureGenerater.texture(segmentationmap, row, col, targetClass) else {
                return
            }
            
            let overlayedTexture = overlayingTexturesGenerater.texture(cameraTexture, segmentationTexture)
            metalVideoPreview.currentTexture = overlayedTexture
            
            DispatchQueue.main.async { [weak self] in
                self?.👨‍🔧.🎬🤚()
                self?.isInferencing = false
            }
            
//            let segmentationResultMLMultiArray = SegmentationResultMLMultiArray(mlMultiArray: segmentationmap)
//            DispatchQueue.main.async { [weak self] in
//                // update result
//                self?.drawingView.segmentationmap = segmentationResultMLMultiArray
//
//                // end of measure
//
//                self?.isInferencing = false
//            }
        } else {
            // end of measure
            self.👨‍🔧.🎬🤚()
            isInferencing = false
        }
    }
}

// MARK: - 📏(Performance Measurement) Delegate
extension LiveMetalCameraViewController: 📏Delegate {
    func updateMeasure(inferenceTime: Double, executionTime: Double, fps: Int) {
        self.maf1.append(element: Int(inferenceTime*1000.0))
        self.maf2.append(element: Int(executionTime*1000.0))
        self.maf3.append(element: fps)
        
        self.inferenceLabel.text = "inference: \(self.maf1.averageValue) ms"
        self.etimeLabel.text = "execution: \(self.maf2.averageValue) ms"
        self.fpsLabel.text = "fps: \(self.maf3.averageValue)"
    }
}

//class MovingAverageFilter {
//    private var arr: [Int] = []
//    private let maxCount = 10
//
//    public func append(element: Int) {
//        arr.append(element)
//        if arr.count > maxCount {
//            arr.removeFirst()
//        }
//    }
//
//    public var averageValue: Int {
//        guard !arr.isEmpty else { return 0 }
//        let sum = arr.reduce(0) { $0 + $1 }
//        return Int(Double(sum) / Double(arr.count))
//    }
//}
