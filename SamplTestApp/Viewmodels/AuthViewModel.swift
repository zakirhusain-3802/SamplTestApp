//
//  AuthViewModel.swift
//  SamplTestApp
//
//  Created by mac2 on 15/10/25.
//  Updated with persistent authentication
//

import Foundation
import GoogleSignIn
import SwiftUI
import Combine

class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var userProfile: UserProfile?
    @Published var errorMessage: String?
    
    private let defaults = UserDefaults.standard
    private let isAuthenticatedKey = "isAuthenticated"
    private let userNameKey = "userName"
    private let userEmailKey = "userEmail"
    private let userImageURLKey = "userImageURL"
    
    init() {
        checkAuthStatus()
    }
    
    func checkAuthStatus() {
        // First check UserDefaults for persistent login
        let savedAuthStatus = defaults.bool(forKey: isAuthenticatedKey)
        
        if savedAuthStatus {
            // Load saved user profile
            loadSavedUserProfile()
            isAuthenticated = true
            print("✅ User already authenticated (loaded from storage)")
        } else if GIDSignIn.sharedInstance.currentUser != nil {
            // Fallback to Google Sign-In session
            isAuthenticated = true
            loadUserProfile()
            print("✅ User authenticated via Google session")
        } else {
            print("❌ No authentication found")
        }
    }
    
    func signInWithGoogle() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            errorMessage = "Unable to find window"
            return
        }
        
        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { [weak self] result, error in
            if let error = error {
                self?.errorMessage = error.localizedDescription
                print("❌ Sign in error: \(error.localizedDescription)")
                return
            }
            
            guard let user = result?.user else {
                self?.errorMessage = "Failed to get user information"
                return
            }
            
            print("✅ Sign in successful")
            self?.isAuthenticated = true
            self?.loadUserProfile()
            self?.saveAuthStatus() // Save to UserDefaults
        }
    }
    
    func signOut() {
        GIDSignIn.sharedInstance.signOut()
        isAuthenticated = false
        userProfile = nil
        clearAuthStatus() // Clear from UserDefaults
        print("👋 User signed out")
    }
    
    private func loadUserProfile() {
        guard let user = GIDSignIn.sharedInstance.currentUser else { return }
        
        let profile = UserProfile(
            name: user.profile?.name ?? "Unknown",
            email: user.profile?.email ?? "No email",
            imageURL: user.profile?.imageURL(withDimension: 200)
        )
        
        self.userProfile = profile
        saveUserProfile(profile) // Save profile to UserDefaults
    }
    
    // MARK: - Persistent Storage
    
    private func saveAuthStatus() {
        defaults.set(true, forKey: isAuthenticatedKey)
        print("💾 Auth status saved")
    }
    
    private func saveUserProfile(_ profile: UserProfile) {
        defaults.set(profile.name, forKey: userNameKey)
        defaults.set(profile.email, forKey: userEmailKey)
        if let imageURL = profile.imageURL {
            defaults.set(imageURL.absoluteString, forKey: userImageURLKey)
        }
        print("💾 User profile saved: \(profile.name)")
    }
    
    private func loadSavedUserProfile() {
        let name = defaults.string(forKey: userNameKey) ?? "Unknown"
        let email = defaults.string(forKey: userEmailKey) ?? "No email"
        let imageURLString = defaults.string(forKey: userImageURLKey)
        let imageURL = imageURLString != nil ? URL(string: imageURLString!) : nil
        
        userProfile = UserProfile(
            name: name,
            email: email,
            imageURL: imageURL
        )
        print("📱 Loaded saved profile: \(name)")
    }
    
    private func clearAuthStatus() {
        defaults.removeObject(forKey: isAuthenticatedKey)
        defaults.removeObject(forKey: userNameKey)
        defaults.removeObject(forKey: userEmailKey)
        defaults.removeObject(forKey: userImageURLKey)
        print("🗑️ Auth status cleared")
    }
}

struct UserProfile {
    let name: String
    let email: String
    let imageURL: URL?
}
