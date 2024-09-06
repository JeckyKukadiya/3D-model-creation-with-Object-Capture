//
//  ObjectCaptureApp.swift
//  ObjectCapture
//
//  Created by Eryus Tech on 05/09/24.
//

import SwiftUI

@main
struct ObjectCaptureApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                ObjectsListView()
            }
        }
    }
}
