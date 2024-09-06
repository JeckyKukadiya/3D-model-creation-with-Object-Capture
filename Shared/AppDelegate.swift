//
//  AppDelegate.swift
//  ObjectCapture
//
//  Created by Eryus Tech on 05/09/24.
//

import FirebaseCore
import FirebaseFirestore
import FirebaseStorage
import Foundation
import Foundation

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
    
    func setupFirebaseLocalEmulator() {
        var host = "127.0.0.1"
    #if !targetEnvironment(simulator)
        host = "192.168.50.73"
    #endif
    let setting = Firestore.firestore().settings
    setting.host = "\(host):8080"
    setting.cacheSettings = MemoryCacheSettings()
        setting.isSSLEnabled = false
        Firestore.firestore().settings = setting
        Storage.storage().useEmulator(withHost: host, port: 9199)
    }
    
}
