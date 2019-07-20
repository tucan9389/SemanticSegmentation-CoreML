//
//  DrawingSegmentationView.swift
//  ObjectSegmentation-CoreML
//
//  Created by Doyoung Gwak on 20/07/2019.
//  Copyright © 2019 Doyoung Gwak. All rights reserved.
//

import UIKit

class DrawingSegmentationView: UIView {
    
    static private var colors: [Int32: UIColor] = [:]
    
    func segmentationColor(with index: Int32) -> UIColor {
        if let color = DrawingSegmentationView.colors[index] {
            return color
        } else {
            let color = UIColor(hue: .random(in: 0...1), saturation: 1, brightness: 1, alpha: 0.5)
            DrawingSegmentationView.colors[index] = color
            return color
        }
    }
    
    var segmentationmap: Array<Array<Int32>>? = nil {
        didSet {
            self.setNeedsDisplay()
        }
    }
    
    override func draw(_ rect: CGRect) {
        
        if let ctx = UIGraphicsGetCurrentContext() {
            
            ctx.clear(rect);
            
            guard let segmentationmap = self.segmentationmap else { return }
            
            let size = self.bounds.size
            let segmentationmap_w = segmentationmap.count
            let segmentationmap_h = segmentationmap.first?.count ?? 0
            let w = size.width / CGFloat(segmentationmap_w)
            let h = size.height / CGFloat(segmentationmap_h)
            
            for j in 0..<segmentationmap_h {
                for i in 0..<segmentationmap_w {
                    let value = segmentationmap[i][j]

                    let rect: CGRect = CGRect(x: CGFloat(i) * w, y: CGFloat(j) * h, width: w, height: h)

                    let color: UIColor = segmentationColor(with: Int32(value))

                    color.setFill()
                    UIRectFill(rect)
                }
            }
        }
    } // end of draw(rect:)

}
