import SwiftUI

// MARK: - Steam Login Screen
struct LoginView: View {
    @EnvironmentObject var appState: AppState
    @State private var username = ""
    @State private var password = ""
    @State private var isLoggingIn = false
    @State private var showError = false
    @State private var logoScale: CGFloat = 0.8
    @State private var logoOpacity: Double = 0

    var body: some View {
        ZStack {
            // Animated background
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.05, blue: 0.15),
                    Color(red: 0.02, green: 0.02, blue: 0.06)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Subtle grid pattern overlay
            GeometryReader { geo in
                Canvas { context, size in
                    for x in stride(from: 0, to: size.width, by: 40) {
                        var path = Path()
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x, y: size.height))
                        context.stroke(path, with: .color(.white.opacity(0.02)), lineWidth: 0.5)
                    }
                    for y in stride(from: 0, to: size.height, by: 40) {
                        var path = Path()
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: size.width, y: y))
                        context.stroke(path, with: .color(.white.opacity(0.02)), lineWidth: 0.5)
                    }
                }
            }
            .ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                // Logo
                VStack(spacing: 16) {
                    ZStack {
                        // Glow
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [Color.blue.opacity(0.3), Color.clear],
                                    center: .center,
                                    startRadius: 20,
                                    endRadius: 80
                                )
                            )
                            .frame(width: 160, height: 160)

                        Image(systemName: "gamecontroller.fill")
                            .font(.system(size: 56))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.white, Color(red: 0.6, green: 0.7, blue: 1.0)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    }
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)

                    Text("STEAMPAD")
                        .font(.system(size: 32, weight: .black, design: .rounded))
                        .tracking(6)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, Color(red: 0.7, green: 0.8, blue: 1.0)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .opacity(logoOpacity)

                    Text("PC Gaming on iPad — Pure Translation")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray)
                        .opacity(logoOpacity)
                }

                // Login form
                VStack(spacing: 16) {
                    // Username
                    HStack(spacing: 12) {
                        Image(systemName: "person.fill")
                            .foregroundColor(.gray)
                            .frame(width: 20)
                        TextField("Steam Username", text: $username)
                            .textFieldStyle(.plain)
                            .foregroundColor(.white)
                            .font(.system(size: 15))
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                    }
                    .padding(14)
                    .background(Color.white.opacity(0.06))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )

                    // Password
                    HStack(spacing: 12) {
                        Image(systemName: "lock.fill")
                            .foregroundColor(.gray)
                            .frame(width: 20)
                        SecureField("Password", text: $password)
                            .textFieldStyle(.plain)
                            .foregroundColor(.white)
                            .font(.system(size: 15))
                    }
                    .padding(14)
                    .background(Color.white.opacity(0.06))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )

                    // Error message
                    if showError {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.circle.fill")
                            Text("Login failed. Check your credentials.")
                        }
                        .font(.system(size: 13))
                        .foregroundColor(.red)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }

                    // Login button
                    Button {
                        performLogin()
                    } label: {
                        HStack(spacing: 8) {
                            if isLoggingIn {
                                ProgressView()
                                    .tint(.white)
                                    .scaleEffect(0.8)
                            }
                            Text(isLoggingIn ? "SIGNING IN..." : "SIGN IN")
                                .font(.system(size: 15, weight: .bold))
                                .tracking(1)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.2, green: 0.4, blue: 0.8),
                                    Color(red: 0.15, green: 0.3, blue: 0.7)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(10)
                        .shadow(color: Color.blue.opacity(0.3), radius: 12, y: 4)
                    }
                    .buttonStyle(.plain)
                    .disabled(isLoggingIn)
                    .padding(.top, 4)

                    // Skip login (demo mode)
                    Button {
                        appState.didLogin()
                    } label: {
                        Text("Continue without login (Demo Mode)")
                            .font(.system(size: 13))
                            .foregroundColor(.gray)
                    }
                    .buttonStyle(.plain)
                }
                .frame(width: 340)

                Spacer()

                // Footer
                Text("SteamPad v0.1.0 • ARM64 Translation Layer")
                    .font(.system(size: 11))
                    .foregroundColor(.gray.opacity(0.5))
                    .padding(.bottom, 20)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }
        }
    }

    private func performLogin() {
        guard !username.isEmpty else {
            withAnimation { showError = true }
            return
        }

        isLoggingIn = true
        showError = false

        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isLoggingIn = false
            appState.library.isAuthenticated = true
            appState.didLogin()
        }
    }
}
