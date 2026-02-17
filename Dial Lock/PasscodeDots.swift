import ScrechKit

struct PasscodeDots: View {
    let count: Int
    let filled: Int
    
    var body: some View {
        HStack(spacing: 12) {
            ForEach(0..<count, id: \.self) { i in
                Circle()
                    .fill(.white.opacity(i < filled ? 0.95 : 0.35))
                    .frame(10)
            }
        }
    }
}
