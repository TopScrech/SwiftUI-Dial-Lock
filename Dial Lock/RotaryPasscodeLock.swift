import ScrechKit

struct RotaryPasscodeLock: View {
    private let codeLength = 4
    private let dialRange = 40
    
    @State private var entered: [Int] = []
    @State private var dialValue = 0
    
    var body: some View {
        ZStack {
            BackgroundBlur()
            
            VStack(spacing: 16) {
                VStack(spacing: 10) {
                    Text("Enter Passcode")
                        .title3(.semibold, design: .rounded)
                        .foregroundStyle(.white.opacity(0.92))
                    
                    PasscodeDots(count: codeLength, filled: entered.count)
                    
                    Text(entered.isEmpty ? "Entered: -" : "Entered: \(entered.map(String.init).joined(separator: " "))")
                        .caption(.semibold, design: .rounded)
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
                        if !entered.isEmpty {
                            entered.removeLast()
                            if entered.isEmpty { dialValue = 0 }
                        }
                    } label: {
                        Image(systemName: "delete.left")
                            .title3(.semibold)
                            .foregroundStyle(.white.opacity(0.9))
                            .frame(52)
                            .background(.white.opacity(0.12))
                            .clipShape(.circle)
                    }
                    
                    Button {
                        entered.removeAll()
                        dialValue = 0
                    } label: {
                        Text("Reset")
                            .headline(.semibold, design: .rounded)
                            .foregroundStyle(.white.opacity(0.92))
                            .frame(height: 52)
                            .padding(.horizontal, 18)
                            .background(.white.opacity(0.12))
                            .clipShape(.capsule)
                    }
                }
                .padding(.bottom, 24)
            }
            .padding(.horizontal, 24)
        }
        .toolbar {
            NavigationLink {
                SettingsView()
            } label: {
                Image(systemName: "gear")
            }
        }
    }
}
