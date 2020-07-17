# SemanticSegmentation-CoreML

![platform-ios](https://img.shields.io/badge/platform-ios-lightgrey.svg)
![swift-version](https://img.shields.io/badge/swift-5.0-red.svg)
![lisence](https://img.shields.io/badge/license-MIT-black.svg)

This project is Object Segmentation on iOS with Core ML.<br>If you are interested in iOS + Machine Learning, visit [here](https://github.com/motlabs/iOS-Proejcts-with-ML-Models) you can see various DEMOs.<br>

| Screenshot 1 | Screenshot 2 | Screenshot 3 | Screenshot 4 |
| ------------ | ------------ | ------------ | ------------ |
| ![](resource/IMG_3632.PNG) | ![](resource/IMG_3633.PNG) | ![](resource/IMG_3634.PNG) | ![](resource/IMG_3635.PNG) |

## How it works

> (Preparing...)

## Requirements

- Xcode 10.2+
- iOS 12.0+
- Swift 5

## Model

### Download

Download model from [apple's model page](https://developer.apple.com/machine-learning/models/).

### Matadata

|            | input node    | output node    |   size   |
| :--------: | :-----------: | :------------: | :------: |
| DeepLabV3     | `[1, 513, 513, 3]`<br>name: `image` | `[513, 513]`<br>name: `semanticPredictions` | 8.6 MB |
| DeepLabV3FP16 | `[1, 513, 513, 3]`<br>name: `image` | `[513, 513]`<br>name: `semanticPredictions` | 4.3 MB |
| DeepLabV3Int8LUT | `[1, 513, 513, 3]`<br>name: `image` | `[513, 513]`<br>name: `semanticPredictions` | 2.3 MB |

### Inference Time

| Device        | Inference Time | Total Time |
| ------------- | :------: | :-----: |
| iPhone XS Max | **133 ms** | 434 ms |
| iPhone XS     | 135 ms | 411 ms |
| iPhone XR     | 133 ms | **402 ms** |
| iPhone X      | 178 ms | 509 ms |
| iPhone 8+     | 180 ms | 563 ms |
| iPhone 8      | 189 ms | 529 ms |
| iPhone 7+     | 240 ms | 667 ms |
| iPhone 7      | 247 ms | 688 ms |
| iPhone 6S +   | 309 ms | 1015 ms |
| iPhone 6+     | 1888 ms | 2753 ms |


## See also

- [motlabs/iOS-Proejcts-with-ML-Models](https://github.com/motlabs/iOS-Proejcts-with-ML-Models)<br>
  : The challenge using machine learning model created from tensorflow on iOS
- [deeplab on TensorFlow](https://github.com/tensorflow/models/tree/master/research/deeplab)<br>
  : The repository providing DeepLabV3 model
