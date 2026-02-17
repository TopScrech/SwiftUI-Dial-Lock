import ScrechKit

struct RotaryDial: View {
    @Binding var value: Int
    
    var range = 40
    var showsNumbers = true
    var snap = true
    var onPick: ((Int) -> Void)? = nil
    
    @State private var dialRotationCW = 0.0
    @State private var lastTouchAngleCW: Double?
    @State private var feedback = UISelectionFeedbackGenerator()
    @State private var lastEmittedValue: Int?
    
    var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)
            let center = CGPoint(x: proxy.size.width / 2, y: proxy.size.height / 2)
            let radius = size * 0.48
            let stepAngle = 360 / Double(max(range, 1))
            
            ZStack {
                Circle()
                    .fill(.black.opacity(0.18))
                    .overlay(
                        Circle()
                            .strokeBorder(.white.opacity(0.22), lineWidth: size * 0.01)
                    )
                
                tickRing(size: size, radius: radius * 0.98)
                
                if showsNumbers {
                    numbers(size: size, radius: radius * 0.72)
                }
                
                Circle()
                    .fill(.black.opacity(0.35))
                    .frame(size * 0.34)
                    .overlay(
                        Circle()
                            .strokeBorder(.white.opacity(0.12), lineWidth: size * 0.01)
                    )
                
                indicator(size: size)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .rotationEffect(.degrees(-dialRotationCW))
            .contentShape(Circle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        let cw = angleCW(from: center, to: gesture.location)
                        
                        if lastTouchAngleCW == nil {
                            lastTouchAngleCW = cw
                            feedback.prepare()
                            emitValue(stepAngle: stepAngle, didEnd: false)
                            return
                        }
                        
                        let delta = shortestDeltaDegrees(from: lastTouchAngleCW!, to: cw)
                        dialRotationCW += delta
                        lastTouchAngleCW = cw
                        emitValue(stepAngle: stepAngle, didEnd: false)
                    }
                    .onEnded { _ in
                        lastTouchAngleCW = nil
                        
                        if snap {
                            let snapped = (dialRotationCW / stepAngle).rounded() * stepAngle
                            withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                                dialRotationCW = snapped
                            }
                        }
                        
                        emitValue(stepAngle: stepAngle, didEnd: true)
                    }
            )
            .onAppear {
                dialRotationCW = Double(value) * stepAngle
                lastEmittedValue = value
                feedback.prepare()
            }
            .onChange(of: value) { _, newValue in
                guard lastTouchAngleCW == nil else { return }
                let target = Double(newValue) * stepAngle
                
                if snap {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                        dialRotationCW = target
                    }
                } else {
                    dialRotationCW = target
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
    
    private func tickRing(size: CGFloat, radius: CGFloat) -> some View {
        let tickCount = 200
        let minorLen = size * 0.035
        let majorLen = size * 0.062
        let majorEvery = max(tickCount / max(range, 1), 1)
        
        return ZStack {
            ForEach(0..<tickCount, id: \.self) { i in
                let isMajor = i % majorEvery == 0
                let len = isMajor ? majorLen : minorLen
                Rectangle()
                    .fill(.white.opacity(isMajor ? 0.75 : 0.32))
                    .frame(width: size * 0.006, height: len)
                    .offset(y: -radius + len / 2)
                    .rotationEffect(.degrees(Double(i) * 360 / Double(tickCount)))
            }
        }
    }
    
    private func numbers(size: CGFloat, radius: CGFloat) -> some View {
        let every = 5
        let labelRadius = radius - size * 0.01
        let labelSize = size * 0.07
        
        return ZStack {
            ForEach(stride(from: 0, to: range, by: every).map { $0 }, id: \.self) { n in
                let a = Double(n) * 360 / Double(range)
                
                ZStack {
                    Text("\(n)")
                        .font(.system(size: labelSize, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.85))
                        .offset(y: -labelRadius)
                }
                .frame(width: size, height: size)
                .rotationEffect(.degrees(a))
            }
        }
    }
    
    private func indicator(size: CGFloat) -> some View {
        Triangle()
            .fill(.white.opacity(0.9))
            .frame(width: size * 0.1, height: size * 0.07)
            .offset(y: -size * 0.52)
            .rotationEffect(.degrees(dialRotationCW))
            .shadow(color: .black.opacity(0.25), radius: 6, y: 3)
    }
    
    private func emitValue(stepAngle: Double, didEnd: Bool) {
        let newValue = normalizedValue(range: range)
        if lastEmittedValue != newValue {
            feedback.selectionChanged()
            lastEmittedValue = newValue
        }
        value = newValue
        
        if didEnd {
            onPick?(newValue)
        }
    }
    
    private func normalizedValue(range: Int) -> Int {
        let r = max(range, 1)
        let step = 360 / Double(r)
        var v = Int((dialRotationCW / step).rounded())
        v %= r
        if v < 0 { v += r }
        return v
    }
    
    private func angleCW(from center: CGPoint, to point: CGPoint) -> Double {
        let dx = Double(point.x - center.x)
        let dy = Double(point.y - center.y)
        let radians = atan2(dy, dx)
        
        var deg = radians * 180 / .pi
        deg = deg + 90
        deg = deg.truncatingRemainder(dividingBy: 360)
        if deg < 0 { deg += 360 }
        let cw = (360 - deg).truncatingRemainder(dividingBy: 360)
        return cw
    }
    
    private func shortestDeltaDegrees(from a: Double, to b: Double) -> Double {
        var d = b - a
        if d > 180 { d -= 360 }
        if d < -180 { d += 360 }
        return d
    }
}
