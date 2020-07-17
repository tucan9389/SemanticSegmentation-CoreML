//
//  StillImageViewController.swift
//  SemanticSegmentation-CoreML
//
//  Created by Doyoung Gwak on 20/07/2019.
//  Copyright © 2019 Doyoung Gwak. All rights reserved.
//

import UIKit
import Vision

class StillImageViewController: UIViewController {

    // MARK: - UI Properties
    @IBOutlet weak var mainImageView: UIImageView!
    @IBOutlet weak var drawingView: DrawingSegmentationView!
    
    let imagePickerController = UIImagePickerController()
    
    // MARK - Core ML model
    // DeepLabV3(iOS12+), DeepLabV3FP16(iOS12+), DeepLabV3Int8LUT(iOS12+)
    let segmentationModel = DeepLabV3()
    
    // MARK: - Vision Properties
    var request: VNCoreMLRequest?
    var visionModel: VNCoreMLModel?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // setup ml model
        setUpModel()
        
        // image picker delegate setup
        imagePickerController.delegate = self
    }
    
    @IBAction func tapCamera(_ sender: Any) {
        self.present(imagePickerController, animated: true)
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
}

// MARK: - UIImagePickerControllerDelegate & UINavigationControllerDelegate
extension StillImageViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[.originalImage] as? UIImage,
            let url = info[.imageURL] as? URL {
            mainImageView.image = image
            self.predict(with: url)
        }
        dismiss(animated: true, completion: nil)
    }
}

// MARK: - Inference
extension StillImageViewController {
    // prediction
    func predict(with url: URL) {
        guard let request = request else { fatalError() }
        
        // vision framework configures the input size of image following our model's input configuration automatically
        let handler = VNImageRequestHandler(url: url, options: [:])
        try? handler.perform([request])
    }
    
    // post-processing
    func visionRequestDidComplete(request: VNRequest, error: Error?) {
        if let observations = request.results as? [VNCoreMLFeatureValueObservation],
            let segmentationmap = observations.first?.featureValue.multiArrayValue {
            
            drawingView.segmentationmap = SegmentationResultMLMultiArray(mlMultiArray: segmentationmap)
        }
    }
}

