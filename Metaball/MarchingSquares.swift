//
//  MarchingSquares.swift
//  Metaball
//
//  Created by Oleksandr Glagoliev on 23.04.2020.
//  Copyright © 2020 Oleksandr Glagoliev. All rights reserved.
//

import Foundation


// MARK: - Marching squares -
public struct MarchingSquares {
    // See: http://jamie-wong.com/images/14-08-11/marching-squares-mapping.png
    enum Corners: Int {
        /// ○ -- ○
        /// |    |
        /// ○ -- ○
        case none    // 0000 = 0
        
        /// ○ -- ○
        /// |    |
        /// ● -- ○
        case bl      // 0001 = 1
        
        /// ○ -- ○
        /// |    |
        /// ○ -- ●
        case br      // 0010 = 2
        
        /// ○ -- ○
        /// |    |
        /// ● -- ●
        case blbr    // 0011 = 3
        
        /// ○ -- ●
        /// |    |
        /// ○ -- ○
        case tr      // 0100 = 4
        
        /// ○ -- ●
        /// |    |
        /// ● -- ○
        case trbl    // 0101 = 5
        
        /// ○ -- ●
        /// |    |
        /// ○ -- ●
        case trbr    // 0110 = 6
        
        /// ○ -- ●
        /// |    |
        /// ● -- ●
        case trbrbl  // 0111 = 7
        
        /// ● -- ○
        /// |    |
        /// ○ -- ○
        case tl      // 1000 = 8
        
        /// ● -- ○
        /// |    |
        /// ● -- ○
        case tlbl    // 1001 = 9
        
        /// ● -- ○
        /// |    |
        /// ○ -- ●
        case tlbr    // 1010 = 10
        
        /// ● -- ○
        /// |    |
        /// ● -- ●
        case tlbrbl  // 1011 = 11
        
        /// ● -- ●
        /// |    |
        /// ○ -- ○
        case tltr    // 1100 = 12
        
        /// ● -- ●
        /// |    |
        /// ● -- ○
        case trbltl  // 1101 = 13
        
        /// ● -- ●
        /// |    |
        /// ○ -- ●
        case trbrtl  // 1110 = 14
        
        /// ● -- ●
        /// |    |
        /// ● -- ●
        case all     // 1111 = 15
    }
    
    enum Edge: Int {
        case t, l, b, r
    }
    
    
    /// Assigns each `Corners` configuration to the set of Sample `Edge`s intersected by contour
    let mapping: [Corners: Set<Edge>] = [
        .bl:     Set<Edge>([.l, .b]),
        .br:     Set<Edge>([.r, .b]),
        .blbr:   Set<Edge>([.l, .r]),
        .tr:     Set<Edge>([.t, .r]),
        .trbl:   Set<Edge>([.t, .l, .b, .r]),
        .trbr:   Set<Edge>([.t, .b]),
        .trbrbl: Set<Edge>([.t, .l]),
        .tl:     Set<Edge>([.t, .l]),
        .tlbl:   Set<Edge>([.t, .b]),
        .tlbr:   Set<Edge>([.b, .r, .t, .l]),
        .tlbrbl: Set<Edge>([.t, .r]),
        .tltr:   Set<Edge>([.r, .l]),
        .trbltl: Set<Edge>([.r, .b]),
        .trbrtl: Set<Edge>([.b, .l])
    ]
    
    struct Sample: SimplyInitialisable {
        var kind: Corners
        var value: CGFloat
        var active: Bool
        
        public init() {
            kind = .none
            value = 0
            active = false
        }
    }
    
    // Input
    private let unit: CGFloat
    private let width: Int
    private let height: Int
    private let threshold: CGFloat
    
    private var grid: Matrix<Sample>
    
    
    public init(unit: CGFloat, width: Int, height: Int, threshold: CGFloat = 1) {
        self.unit = unit
        self.width = width
        self.height = height
        self.threshold = threshold
        
        self.grid = Matrix<Sample>(rows: height, columns: width)
    }
    
    public mutating func update(circles: [Circle]) -> [[CGPoint]] {
        var pairs = [(a: CGPoint, b: CGPoint)]()
        
        activateSamples(circles: circles)
        
        for i in 0..<grid.elements.count {
            let (row, col) = grid.rowAndColForIndex(i)
            
            /// Identify activated corners based on sample kind
            let corners = kindForSample(at: row, col: col)
            grid[row, col].kind = corners
            
            if corners == .all || corners == .none {
                /// In this case the sample is not intersected by "blob" edges.
                /// It either is:
                ///  - Inside the "blob" region: `corners == .all`
                ///  - Outside the "blob" region: `corners == .none`
                ///  This sample does not require any further processing
                continue
            }
            
            /// To compute Sample `value` in each corner we assign `value`s from neighbour samples
            ///
            ///        ○ -- ○ -- ○ -- ○
            ///        |    |    |    |
            ///        ○ -- ● -- ● -- ○
            ///        |    | tl | tr |
            ///        ○ -- ● -- ● -- ○
            ///        |    | bl | br |
            ///        ○ -- ○ -- ○ -- ○
            ///
            /// `tl` - Value assigned to Top Left corner
            /// `tr` - Value assigned to Top Right corner
            /// `br` - Value assigned to Bottom Right corner
            /// `bl` - Value assigned to Bottom Left corner
            let tl: CGFloat = grid[row, col].value
            var tr: CGFloat = 0
            var br: CGFloat = 0
            var bl: CGFloat = 0
            if col < width - 1 {
                tr = grid[row, col + 1].value
            }
            if col < width - 1 && row < height - 1 {
                br = grid[row + 1, col + 1].value
            }
            if row < height - 1 {
                bl = grid[row + 1, col].value
            }
            
            let sides = mapping[corners]!
            /// Find intersections with sample edges
            var intersections: [CGPoint] = []
            if sides.contains(.t) {
                let top = lerp(tl, tr, threshold)
                intersections.append(
                    CGPoint(
                        x: (CGFloat(col) + top) * unit,
                        y: CGFloat(row) * unit
                    )
                )
            }
            if sides.contains(.r) {
                let right = lerp(tr, br, threshold)
                intersections.append(
                    CGPoint(
                        x: CGFloat(col + 1) * unit,
                        y: (CGFloat(row) + right) * unit
                    )
                )
            }
            if sides.contains(.l) {
                let left = lerp(tl, bl, threshold)
                intersections.append(
                    CGPoint(
                        x: CGFloat(col) * unit,
                        y: (CGFloat(row) + left) * unit
                    )
                )
            }
            if sides.contains(.b) {
                let bottom = lerp(bl, br, threshold)
                intersections.append(
                    CGPoint(
                        x: (CGFloat(col) + bottom) * unit,
                        y: CGFloat(row + 1) * unit
                    )
                )
            }
            
            if intersections.count == 2 {
                pairs.append(
                    (a: intersections[0], b: intersections[1])
                )
            }
            if intersections.count == 4 {
                pairs.append(
                    (a: intersections[0], b: intersections[2])
                )
                pairs.append(
                    (a: intersections[1], b: intersections[3])
                )
            }
        }
        return contours(pairs)
    }
    
    
    /// Returns list of contours represented as ordered Array of `CGPoint`
    /// TODO: This is a naive implementation. Most likely, some kind of Sweep algorithm will yield better performance.
    ///
    /// - Parameter pairs: pairs of points describing a line cut received as a result of sample intersection by contour
    /// - Returns: list of Contours
    private func contours(_ pairs: [(a: CGPoint, b: CGPoint)]) -> [[CGPoint]] {
        guard !pairs.isEmpty else { return [] }
        
        var d = [CGPoint: (CGPoint, CGPoint?)](minimumCapacity: pairs.count)
        var visited = Set<CGPoint>()
        var notVisited = Set<CGPoint>()
        var result:[[CGPoint]] = [[]]
        
        pairs.forEach { (a, b) in
            notVisited.insert(a)
            notVisited.insert(b)
            
            if d[a] == nil {
                d[a] = (b, nil)
            } else {
                d[a]!.1 = b
            }
            if d[b] == nil {
                d[b] = (a, nil)
            } else {
                d[b]!.1 = a
            }
        }
        
        var p = notVisited.removeFirst()
        var polyline = [CGPoint]()
        
        while notVisited.count > 0 {
            visited.insert(p)
            
            if !visited.contains(d[p]!.0) {
                p = d[p]!.0
                polyline.append(p)
            } else if !visited.contains(d[p]!.1!) {
                p = d[p]!.1!
                polyline.append(p)
            } else {
                p = notVisited.removeFirst()
                result.append(polyline)
                polyline = []
            }
        }

        return result
    }
    
    
    mutating func activateSamples(circles: [Circle]) {
        for i in 0..<grid.elements.count {
            let (row, col) = grid.rowAndColForIndex(i)
            if row == 0 || col == 0 {
                /// Prevents metaballs to be crossed by the edge of the simulation
                continue
            }
            /// For each Sample we calculate an activation value with respect to the threshold
            /// The larger is the threshold - the less likely sample will be activated
            /// It means that blob area will be smaller with larget threshold
            ///
            /// Time complexity is `O( M * N )` where:
            /// `M` is number of samples in the grid (width * height)
            /// `N` is number of circles
            var val: CGFloat = 0
            circles.forEach {
                let dx = CGFloat(col) * unit - $0.center.x
                let dy = CGFloat(row) * unit - $0.center.y
                
                val += ($0.r * $0.r) / (dx * dx + dy * dy)
            }
            grid[row, col].value = val
            grid[row, col].active = (val > threshold)
        }
    }
    
    private func kindForSample(at row: Int, col: Int) -> Corners {
        /// Check activation of the samples adjacent to it's corners
        ///
        /// ```
        ///        ○ -- ○ -- ○ -- ○
        ///        |    |    |    |
        ///        ○ -- ● -- ● -- ○
        ///        |    | tl | tr |
        ///        ○ -- ● -- ● -- ○
        ///        |    | bl | br |
        ///        ○ -- ○ -- ○ -- ○
        ///
        ///```
        ///
        /// `tl` - Value assigned to Top Left corner
        /// `tr` - Value assigned to Top Right corner
        /// `br` - Value assigned to Bottom Right corner
        /// `bl` - Value assigned to Bottom Left corner
        
        let tl = grid[row, col].active.toInt()
        var tr = 0
        var bl = 0
        var br = 0
        if col < width - 1 {
            tr = grid[row, col + 1].active.toInt()
        }
        if row < height - 1 {
            bl = grid[row + 1, col].active.toInt()
        }
        if col < width - 1 && row < height - 1 {
            br = grid[row + 1, col + 1].active.toInt()
        }
        
        return Corners(
            rawValue: (bl << 0) + (br << 1) + (tr << 2) + (tl << 3)
        )!
    }
    
    
    /// Linear interpolation of two values
    /// - Parameters:
    ///   - start: start value
    ///   - finish: finish value
    ///   - alpha: shows how far the result will be from `start`
    /// - Returns: interpolated result
    func lerp(_ start: CGFloat, _ finish: CGFloat, _ alpha: CGFloat) -> CGFloat {
        if start == finish { return 0 }
        return (alpha - start) / (finish - start)
    }
}

// MARK: - Cicrle -
public struct Circle {
    var center: CGPoint
    var r: CGFloat
}

// MARK: - Bool -
public extension Bool {
    func toInt() -> Int { self ? 1 : 0 }
}

// MARK: - CGPoint -
extension CGPoint: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(x)
        hasher.combine(y)
    }
}

// MARK: - Matrix -
public protocol SimplyInitialisable {
    init()
}

public struct Matrix<T: SimplyInitialisable> {
    let rows: Int, columns: Int
    private(set) var elements: ContiguousArray<T>
    
    init(rows: Int, columns: Int) {
        self.rows = rows
        self.columns = columns
        elements = ContiguousArray<T>(
            (0..<rows*columns).map { _ in T.init() }
        )
    }
    
    func indexIsValid(row: Int, column: Int) -> Bool {
        return row >= 0 && row < rows && column >= 0 && column < columns
    }
    
    subscript(row: Int, column: Int) -> T {
        get {
            assert(indexIsValid(row: row, column: column), "Index out of range")
            return elements[(row * columns) + column]
        }
        set {
            assert(indexIsValid(row: row, column: column), "Index out of range")
            elements[(row * columns) + column] = newValue
        }
    }
    
    func rowAndColForIndex(_ index: Int) -> (row: Int, col: Int) {
        assert(index < elements.count, "Index out of range")
        return (row: index / columns, col: index % columns)
    }
}
