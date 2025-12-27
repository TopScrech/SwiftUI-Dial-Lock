import SwiftUI
import UIKit

struct RotaryPasscodeLock: View {
    var codeLength: Int = 4
    var dialRange: Int = 40
    
    @State private var entered: [Int] = []
    @State private var dialValue: Int = 0
    
    var body: some View {
        ZStack {
            BackgroundBlur()
            
            VStack(spacing: 16) {
                VStack(spacing: 10) {
                    Text("Enter Passcode")
                        .font(.system(.title3, design: .rounded).weight(.semibold))
                        .foregroundStyle(.white.opacity(0.92))
                    
                    PasscodeDots(count: codeLength, filled: entered.count)
                    
                    Text(entered.isEmpty ? "Entered: -" : "Entered: \(entered.map(String.init).joined(separator: " "))")
                        .font(.system(.caption, design: .monospaced).weight(.semibold))
                        .foregroundStyle(.white.opacity(0.75))
                }
                .padding(.top, 42)
                
                Spacer()
                
                RotaryDial(value: $dialValue, range: dialRange, showsNumbers: true, snap: true) { picked in
                    guard entered.count < codeLength else { return }
                    entered.append(picked)
                }
                .frame(maxWidth: 320)
                .padding(.bottom, 52)
                
                HStack(spacing: 16) {
                    Button {
                        if !entered.isEmpty { entered.removeLast() }
                    } label: {
                        Image(systemName: "delete.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.9))
                            .frame(width: 52, height: 52)
                            .background(.white.opacity(0.12))
                            .clipShape(Circle())
                    }
                    
                    Button {
                        entered.removeAll()
                        dialValue = 0
                    } label: {
                        Text("Reset")
                            .font(.system(.headline, design: .rounded).weight(.semibold))
                            .foregroundStyle(.white.opacity(0.92))
                            .frame(height: 52)
                            .padding(.horizontal, 18)
                            .background(.white.opacity(0.12))
                            .clipShape(Capsule())
                    }
                }
                .padding(.bottom, 24)
            }
            .padding(.horizontal, 24)
        }
    }
}

private struct PasscodeDots: View {
    let count: Int
    let filled: Int
    
    var body: some View {
        HStack(spacing: 12) {
            ForEach(0..<count, id: \.self) { i in
                Circle()
                    .fill(.white.opacity(i < filled ? 0.95 : 0.35))
                    .frame(width: 10, height: 10)
            }
        }
    }
}

struct RotaryDial: View {
    @Binding var value: Int
    
    var range: Int = 40
    var showsNumbers: Bool = true
    var snap: Bool = true
    var onPick: ((Int) -> Void)? = nil
    
    @State private var dialRotationCW: Double = 0
    @State private var lastTouchAngleCW: Double?
    @State private var feedback = UISelectionFeedbackGenerator()
    @State private var lastEmittedValue: Int?
    
    var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)
            let center = CGPoint(x: proxy.size.width / 2, y: proxy.size.height / 2)
            let radius = size * 0.48
            let stepAngle = 360.0 / Double(max(range, 1))
            
            ZStack {
                Circle()
                    .fill(Color.black.opacity(0.18))
                    .overlay(
                        Circle()
                            .strokeBorder(.white.opacity(0.22), lineWidth: size * 0.01)
                    )
                
                tickRing(size: size, radius: radius * 0.98)
                
                if showsNumbers {
                    numbers(size: size, radius: radius * 0.72)
                }
                
                Circle()
                    .fill(Color.black.opacity(0.35))
                    .frame(width: size * 0.34, height: size * 0.34)
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
                    .rotationEffect(.degrees(Double(i) * 360.0 / Double(tickCount)))
            }
        }
    }
    
    private func numbers(size: CGFloat, radius: CGFloat) -> some View {
        let every = 5
        return ZStack {
            ForEach(stride(from: 0, to: range, by: every).map { $0 }, id: \.self) { n in
                let a = Double(n) * 360.0 / Double(range)
                let p = pointOnCircle(radius: radius, angleCW: a)
                Text("\(n)")
                    .font(.system(size: size * 0.075, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.85))
                    .position(x: size / 2 + p.x, y: size / 2 + p.y)
            }
        }
    }
    
    private func indicator(size: CGFloat) -> some View {
        Triangle()
            .fill(.white.opacity(0.9))
            .frame(width: size * 0.10, height: size * 0.07)
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
        let step = 360.0 / Double(r)
        var v = Int((dialRotationCW / step).rounded())
        v %= r
        if v < 0 { v += r }
        return v
    }
    
    private func angleCW(from center: CGPoint, to point: CGPoint) -> Double {
        let dx = Double(point.x - center.x)
        let dy = Double(point.y - center.y)
        let radians = atan2(dy, dx)
        
        var deg = radians * 180.0 / .pi
        deg = deg + 90.0
        deg = deg.truncatingRemainder(dividingBy: 360.0)
        if deg < 0 { deg += 360.0 }
        let cw = (360.0 - deg).truncatingRemainder(dividingBy: 360.0)
        return cw
    }
    
    private func shortestDeltaDegrees(from a: Double, to b: Double) -> Double {
        var d = b - a
        if d > 180 { d -= 360 }
        if d < -180 { d += 360 }
        return d
    }
    
    private func pointOnCircle(radius: CGFloat, angleCW: Double) -> CGPoint {
        let rad = (angleCW - 90.0) * .pi / 180.0
        return CGPoint(x: CGFloat(cos(rad)) * radius, y: CGFloat(sin(rad)) * radius)
    }
}

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

private struct BackgroundBlur: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.08, green: 0.20, blue: 0.45),
                    Color(red: 0.15, green: 0.42, blue: 0.42),
                    Color(red: 0.55, green: 0.40, blue: 0.10)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
        }
    }
}

struct RotaryPasscodeLockDemo: View {
    var body: some View {
        RotaryPasscodeLock()
    }
}
