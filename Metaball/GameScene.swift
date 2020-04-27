//
//  GameScene.swift
//  Metaball
//
//  Created by Oleksandr Glagoliev on 16.03.2020.
//  Copyright © 2020 Oleksandr Glagoliev. All rights reserved.
//

import SpriteKit

extension CGFloat {
    static let unit: CGFloat = 2.0
    
    static func unit(_ n: Int) -> CGFloat {
        CGFloat(n) * .unit
    }
}

class GameScene: SKScene {
    private var blob: SKShapeNode!
    
    private var ms: MarchingSquares!
    
    let w = 200
    let h = 200
    
    var rect: CGRect {
        CGRect(
            x: .unit(50),
            y: .unit(50),
            width: .unit(w),
            height: .unit(h)
        )
    }
    
    override func didMove(to view: SKView) {
        drawGrid(unit: 40, rect: rect)
        
        
        blob = SKShapeNode()
        blob.strokeColor = .black
        blob.lineWidth = 1.0
        addChild(blob)
               
        ms = MarchingSquares(
            unit: .unit,
            width: w,
            height: h,
            threshold: 15.0
        )
        
        generateMap()
    }
    
    private func generateMap() {
        let numCircles: Int = 30
        let elevationStepRange: ClosedRange<CGFloat> = 6...6.0
        let circleRadiusVariance: ClosedRange<CGFloat> = 100.0...300.0
        let bounds = CGRect(
            x: .unit(5),
            y: .unit(5),
            width: .unit(w),
            height: .unit(h)
        )
        
        circles = (0..<numCircles).map { _ in
            let randomPointWithinRect = CGPoint(
                x: CGFloat.random(in: bounds.minX...bounds.maxX),
                y: CGFloat.random(in: bounds.minY...bounds.maxY)
            )
            return Circle(center: randomPointWithinRect, r: CGFloat.random(in: circleRadiusVariance))
        }
        
        let vectors = (0..<numCircles).map { _ in
            CGPoint(
                x: CGFloat.random(in: -8...8),
                y: CGFloat.random(in: -8...8)
            )
        }
        
        var k = 0
        while circles.map({ $0.r }).reduce(0, +) != 0 {
            k += 1
            var i = -1
            circles = circles.map {
                i += 1
                return Circle(center: CGPoint(x: $0.center.x + vectors[i].x / CGFloat.random(in: 1...2), y:  $0.center.y + vectors[i].y / CGFloat.random(in: 1...2)), r: max($0.r - CGFloat.random(in: elevationStepRange), 0))
            }
            
            drawContour(circles: circles, isOdd: k % 2 == 0)
        }
    }
    
    private func drawContour(circles: [Circle], isOdd: Bool = true) {
        let node = SKShapeNode()
        node.strokeColor = .white
        node.lineWidth = 1.0
        node.fillColor = isOdd ? UIColor.white : UIColor.black
        addChild(node)
        
        let path = CGMutablePath()
        let contours = ms.update(
            circles: circles.map {
                Circle(
                    center: CGPoint(
                                x: $0.center.x - rect.minX,
                                y: $0.center.y - rect.minY
                            ),
                    r: $0.r
                )
            }
        )
        
        for contour in contours {
            for i in 0..<contour.count {
                let p = contour[i]
                if i == 0 {
                    path.move(
                        to: CGPoint(x: p.x + rect.minX, y: p.y + rect.minY)
                    )
                } else {
                    path.addLine(
                        to: CGPoint(x: p.x + rect.minX, y: p.y + rect.minY)
                    )
                }
            }
            path.closeSubpath()
        }
        
        node.path = path
    }
    
    private func drawGrid(unit: CGFloat, rect: CGRect) {
        let grid = SKShapeNode()
        grid.strokeColor = UIColor.lightGray.withAlphaComponent(0.5)
        grid.lineWidth = 1.0
        addChild(grid)
        
        let path = CGMutablePath()
        let rows = Int(rect.height / unit)
        let cols = Int(rect.width / unit)
        (0...rows).forEach {
            let y = CGFloat($0) * unit + rect.minY
            path.move(to: CGPoint(x: rect.minX, y: y))
            path.addLine(to: CGPoint(x: rect.maxX, y: y))
        }
        (0...cols).forEach {
            let x = CGFloat($0) * unit + rect.minX
            path.move(to: CGPoint(x: x, y: rect.minY))
            path.addLine(to: CGPoint(x: x, y: rect.maxY))
        }
        grid.path = path
    }
    
    // MARK: - Touch -
    var circles = [Circle]()
    
    func touchDown(atPoint pos : CGPoint) {
        removeAllChildren()
        drawGrid(unit: 40, rect: rect)
        generateMap()
//        let r: CGFloat = CGFloat.random(in: 5...100)
//        let circle = SKShapeNode(circleOfRadius: r)
//        circle.position = pos
//        circle.strokeColor = .red
//        addChild(circle)
//        circles.append(
//            Circle(center: pos, r: r)
//        )
//
//        let path = CGMutablePath()
//        let contours = ms.update(
//            circles: circles.map {
//                Circle(
//                    center: CGPoint(
//                                x: $0.center.x - rect.minX,
//                                y: $0.center.y - rect.minY
//                            ),
//                    r: $0.r
//                )
//            }
//        )
//
//        for contour in contours {
//            for i in 0..<contour.count {
//                let p = contour[i]
//                if i == 0 {
//                    path.move(
//                        to: CGPoint(x: p.x + rect.minX, y: p.y + rect.minY)
//                    )
//                } else {
//                    path.addLine(
//                        to: CGPoint(x: p.x + rect.minX, y: p.y + rect.minY)
//                    )
//                }
//            }
//            path.closeSubpath()
//        }
//
//        blob.path = path
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchDown(atPoint: t.location(in: self)) }
    }
}
