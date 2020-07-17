//
//  HeatmapPostProcessor.swift
//  SemanticSegmentation-CoreML
//
//  Created by Doyoung Gwak on 20/07/2019.
//  Copyright © 2019 Doyoung Gwak. All rights reserved.
//

import CoreML

class SegmentationPostProcessor {
    func convertTo2DArray(from heatmaps: MLMultiArray) -> Array<Array<Int32>> {
        guard heatmaps.shape.count >= 3 else {
            print("heatmap's shape is invalid. \(heatmaps.shape)")
            return []
        }
        let _/*keypoint_number*/ = heatmaps.shape[0].intValue
        let heatmap_w = heatmaps.shape[1].intValue
        let heatmap_h = heatmaps.shape[2].intValue
        
        var convertedHeatmap: Array<Array<Int32>> = Array(repeating: Array(repeating: 0, count: heatmap_w), count: heatmap_h)
        
        for i in 0..<heatmap_w {
            for j in 0..<heatmap_h {
                let index = i*(heatmap_h) + j
                let segmetationIndex = heatmaps[index].int32Value
                
                convertedHeatmap[j][i] = segmetationIndex
            }
        }
        
        return convertedHeatmap
    }
}
