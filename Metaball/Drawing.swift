//
//  Drawing.swift
//  MarchingSquares
//
//  Created by Oleksandr Glagoliev on 1/16/19.
//  Copyright © 2019 Oleksandr Glagoliev. All rights reserved.
//

import UIKit

struct Draw {
    static func drawCircle(in context: CGContext, of radius: CGFloat, at location: CGPoint, startAngle: CGFloat = 0, endAngle: CGFloat = .pi * 2) {
        let circle = UIBezierPath(
            arcCenter: location,
            radius: radius, startAngle: startAngle,
            endAngle: endAngle,
            clockwise: true
        )

        context.saveGState()
        UIColor.black.setStroke()
        context.addPath(circle.cgPath)
        context.strokePath()
        context.restoreGState()
    }

    static func drawDot(in context: CGContext, at location: CGPoint, color: UIColor = .black) {
        let dot = UIBezierPath(
            arcCenter: location,
            radius: 2, startAngle: 0,
            endAngle: .pi * 2,
            clockwise: true
        )

        context.saveGState()
        color.setFill()

        context.addPath(dot.cgPath)
        context.fillPath()

        context.restoreGState()
    }
    
    static func drawRect(in context: CGContext, rect: CGRect, color: UIColor = .black) {
        context.saveGState()
        color.setFill()
        context.addRect(rect)
        context.fillPath()
        context.restoreGState()
    }

    static func drawLine(in context: CGContext, from: CGPoint, to: CGPoint, color: UIColor = .lightGray) {
        context.saveGState()
        context.setLineWidth(1)
        color.setStroke()
        context.move(to: from)
        context.addLine(to: to)
        context.strokePath()
        context.restoreGState()
    }
}
