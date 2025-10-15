//
//  LoginView.swift
//  SamplTestApp
//
//  Created by mac2 on 15/10/25.
//  Updated with debug mode and better UX
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showDebugMode = false
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "photo.stack.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundColor(.blue)
            
            Text("Gallery App")
                .font(.largeTitle)
                .bold()
            
            Text("Sign in to view amazing wallpapers")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer()
            
            // Google Sign In Button
            Button(action: {
                authViewModel.signInWithGoogle()
            }) {
                HStack {
                    Image(systemName: "g.circle.fill")
                        .font(.title2)
                    Text("Sign in with Google")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .padding(.horizontal, 40)
            
            // Debug/Test Mode Button (for testing offline)
            #if DEBUG
            Button(action: {
                // Skip login for testing
                authViewModel.isAuthenticated = true
                authViewModel.userProfile = UserProfile(
                    name: "Test User",
                    email: "test@example.com",
                    imageURL: nil
                )
                // Save to UserDefaults for persistence
                UserDefaults.standard.set(true, forKey: "isAuthenticated")
                UserDefaults.standard.set("Test User", forKey: "userName")
                UserDefaults.standard.set("test@example.com", forKey: "userEmail")
            }) {
                HStack {
                    Image(systemName: "hammer.fill")
                    Text("Skip Login (Debug)")
                        .font(.subheadline)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.gray.opacity(0.2))
                .foregroundColor(.secondary)
                .cornerRadius(10)
            }
            .padding(.horizontal, 40)
            #endif
            
            if let error = authViewModel.errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding()
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
            
            // Auth Status Indicator (for debugging)
            #if DEBUG
            Text("Auth Status: \(authViewModel.isAuthenticated ? "✅ Logged In" : "❌ Not Logged In")")
                .font(.caption2)
                .foregroundColor(.gray)
                .padding(.bottom, 8)
            #endif
        }
        .onAppear {
            print("🔍 LoginView appeared - Auth status: \(authViewModel.isAuthenticated)")
        }
    }
}

////#Preview {
//    LoginView()
//        .environmentObject(AuthViewModel())
//}
