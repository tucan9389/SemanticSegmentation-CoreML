# SemanticSegmentation-CoreML

![platform-ios](https://img.shields.io/badge/platform-ios-lightgrey.svg)
![swift-version](https://img.shields.io/badge/swift-5.0-red.svg)
![lisence](https://img.shields.io/badge/license-MIT-black.svg)

This project is Object Segmentation on iOS with Core ML.<br>If you are interested in iOS + Machine Learning, visit [here](https://github.com/motlabs/iOS-Proejcts-with-ML-Models) you can see various DEMOs.<br>

| DeepLabV3-DEMO1                                              | FaceParsing-DEMO                                             | DeepLabV3-DEMO-2                              | DeepLabV3-DEMO-3                              |
| ------------------------------------------------------------ | ------------------------------------------------------------ | --------------------------------------------- | --------------------------------------------- |
| <img src="https://user-images.githubusercontent.com/37643248/99242802-167ad280-2843-11eb-959a-5fe3b169d8f0.gif" width=240px> | <img src="https://user-images.githubusercontent.com/37643248/110972921-e8943d80-839f-11eb-9559-2a32d3b56de0.gif" width=240px> | <img src="resource/IMG_3633.PNG" width=240px> | <img src="resource/IMG_3635.PNG" width=240px> |

## How it works

> When use Metal

![image](https://user-images.githubusercontent.com/37643248/100520189-da9b2200-31df-11eb-928f-db6f503ea4e0.png)

## Requirements

- Xcode 10.2+
- iOS 12.0+
- Swift 5

## Models

### Download

Download model from [apple's model page](https://developer.apple.com/machine-learning/models/).

### Matadata

| Name             |           Input           |             Output             |  Size   | iOS version+ |                           Download                           |
| :--------------- | :-----------------------: | :----------------------------: | :-----: | :----------: | :----------------------------------------------------------: |
| DeepLabV3        | `Image (Color 513 × 513)` | `MultiArray (Int32 513 × 513)` | 8.6 MB  |  iOS 12.0+   | [link](https://developer.apple.com/machine-learning/models/) |
| DeepLabV3FP16    | `Image (Color 513 × 513)` | `MultiArray (Int32 513 × 513)` | 4.3 MB  |  iOS 12.0+   | [link](https://developer.apple.com/machine-learning/models/) |
| DeepLabV3Int8LUT | `Image (Color 513 × 513)` | `MultiArray (Int32 513 × 513)` | 2.3 MB  |  iOS 12.0+   | [link](https://developer.apple.com/machine-learning/models/) |
| FaceParsing      | `Image (Color 512 × 512)` | `MultiArray (Int32)` 512 × 512 | 52.7 MB |  iOS 14.0+   | [link](https://github.com/tucan9389/SemanticSegmentation-CoreML/releases/download/support-face-parsing/FaceParsing.mlmodel) |

### Inference Time − DeepLabV3

| Device            | Inference Time | Total Time (GPU) | Total Time (CPU) |
| ----------------- | :------------: | :--------------: | :--------------: |
| iPhone 12 Pro     |   **29 ms**    |    **29 ms**     |      240 ms      |
| iPhone 12 Pro Max |       ⏲        |        ⏲        |        ⏲        |
| iPhone 12         |     30 ms      |      31 ms       |     253 ms       |
| iPhone 12 Mini    |     29 ms      |      30 ms       |   **226 ms**     |
| iPhone 11 Pro     |     39 ms      |      40 ms       |      290 ms      |
| iPhone 11 Pro Max |     35 ms      |      36 ms       |      280 ms      |
| iPhone 11         |       ⏲        |        ⏲         |        ⏲        |
| iPhone SE (2nd)   |       ⏲        |        ⏲         |        ⏲        |
| iPhone XS Max     |       ⏲        |        ⏲         |        ⏲        |
| iPhone XS         |     54 ms      |      55 ms        |      327 ms      |
| iPhone XR         |     133 ms     |        ⏲         |      402 ms      |
| iPhone X          |     137 ms     |      143 ms       |      376 ms      |
| iPhone 8+         |     140 ms     |      146 ms       |      420 ms      |
| iPhone 8          |     189 ms     |        ⏲         |      529 ms      |
| iPhone 7+         |     240 ms     |        ⏲         |      667 ms      |
| iPhone 7          |     192 ms     |      208 ms       |      528 ms      |
| iPhone 6S +       |     309 ms     |        ⏲         |     1015 ms      |

⏲: need to measure

### Inference Time − FaceParsing

| Device        | Inference Time | Total Time (GPU) | Total Time (CPU) |
| ------------- | :------------: | :--------------: | :--------------: |
| iPhone 12 Pro |       ⏲        |        ⏲         |        ⏲         |
| iPhone 11 Pro |     37 ms      |      37 ms       |        ⏲         |

### Labels − DeepLabV3

```
# total 21
["background", "aeroplane", "bicycle", "bird", "boat", 
"bottle", "bus", "car", "cat", "chair", 
"cow", "diningtable", "dog", "horse", "motorbike", 
"person", "pottedplant", "sheep", "sofa", "train", 
"tv"]
```

### Labels − FaceParsing

```
# total 19
["background", "skin", "l_brow", "r_brow", "l_eye", 
"r_eye", "eye_g", "l_ear", "r_ear", "ear_r", 
"nose", "mouth", "u_lip", "l_lip", "neck", 
"neck_l", "cloth", "hair", "hat"]
```

## See also

- [motlabs/iOS-Proejcts-with-ML-Models](https://github.com/motlabs/iOS-Proejcts-with-ML-Models)<br>
  : The challenge using machine learning model created from tensorflow on iOS
- [DeepLab on TensorFlow](https://github.com/tensorflow/models/tree/master/research/deeplab)<br>
  : The repository providing DeepLabV3 model
- [FaceParsing](https://github.com/zllrunning/face-parsing.PyTorch)<Br>: The repository providing the FaceParsing pytorch model
