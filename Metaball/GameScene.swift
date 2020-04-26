//
//  GameScene.swift
//  Metaball
//
//  Created by Oleksandr Glagoliev on 16.03.2020.
//  Copyright © 2020 Oleksandr Glagoliev. All rights reserved.
//

import SpriteKit

extension CGFloat {
    static let unit: CGFloat = 20.0
    
    static func unit(_ n: Int) -> CGFloat {
        CGFloat(n) * .unit
    }
}

class GameScene: SKScene {
    private var blob: SKShapeNode!
    
    private var ms: MarchingSquares!
    
    let w = 40
    let h = 20
    var rect: CGRect {
        CGRect(
            x: .unit(5),
            y: .unit(5),
            width: .unit(w),
            height: .unit(h)
        )
    }
    
    override func didMove(to view: SKView) {
        drawGrid(unit: .unit, rect: rect)
        
        
        blob = SKShapeNode()
        blob.strokeColor = .black
        blob.lineWidth = 1.0
        addChild(blob)
        
        
        ms = MarchingSquares(
            unit: .unit,
            width: w,
            height: h,
            threshold: 1.0
        )
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
            let y = .unit($0) + rect.minY
            path.move(to: CGPoint(x: rect.minX, y: y))
            path.addLine(to: CGPoint(x: rect.maxX, y: y))
        }
        (0...cols).forEach {
            let x = .unit($0) + rect.minX
            path.move(to: CGPoint(x: x, y: rect.minY))
            path.addLine(to: CGPoint(x: x, y: rect.maxY))
        }
        grid.path = path
    }
    
    // MARK: - Touch -
    var circles = [Circle]()
    func touchDown(atPoint pos : CGPoint) {
        let r: CGFloat = CGFloat.random(in: 5...100)
        let circle = SKShapeNode(circleOfRadius: r)
        circle.position = pos
        circle.strokeColor = .red
        addChild(circle)
        circles.append(
            Circle(center: pos, r: r)
        )
        
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
        
        blob.path = path
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchDown(atPoint: t.location(in: self)) }
    }
}
