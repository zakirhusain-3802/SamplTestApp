//
//  SamplTestAppApp.swift
//  SamplTestApp
//
//  Created by mac2 on 15/10/25.
//

import SwiftUI
internal import CoreData
import GoogleSignIn

@main
struct SamplTestAppApp: App {
    let persistenceController = PersistenceController.shared
      @StateObject private var authViewModel = AuthViewModel()
      
      var body: some Scene {
          WindowGroup {
              ContentView()
                  .environment(\.managedObjectContext, persistenceController.container.viewContext)
                  .environmentObject(authViewModel)
                  .onOpenURL { url in
                      GIDSignIn.sharedInstance.handle(url)
                  }
          }
      }
}
