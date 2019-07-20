//
//  SegmentationPostProcessor.swift
//  DepthPrediction-CoreML
//
//  Created by Doyoung Gwak on 20/07/2019.
//  Copyright © 2019 Doyoung Gwak. All rights reserved.
//

import CoreML

class SegmentationPostProcessor {
    func convertTo2DArray(from segmentationmap: MLMultiArray) -> Array<Array<Int32>> {
        guard segmentationmap.shape.count >= 2 else {
            print("heatmap's shape is invalid. \(segmentationmap.shape)")
            return []
        }
        
        let segmentationmap_w = segmentationmap.shape[0].intValue
        let segmentationmap_h = segmentationmap.shape[1].intValue
        
        var convertedSegmentationmap: Array<Array<Int32>> = Array(repeating: Array(repeating: 0, count: segmentationmap_w), count: segmentationmap_h)
        
        for i in 0..<segmentationmap_w {
            for j in 0..<segmentationmap_h {
                let index = i*(segmentationmap_h) + j
                let segmentationIndex = segmentationmap[index].int32Value
                
                convertedSegmentationmap[j][i] = segmentationIndex
            }
        }
        
        return convertedSegmentationmap
    }
}
