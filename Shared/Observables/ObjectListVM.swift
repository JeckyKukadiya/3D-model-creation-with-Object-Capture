//
//  ObjectListVM.swift
//  ObjectCapture
//
//  Created by Eryus Tech on 05/09/24.
//

import FirebaseFirestore
import Foundation
import SwiftUI

class ObjectListViewModel: ObservableObject {
    @Published var objects = [ObjectItems]()
    
    @MainActor
    func listToItems() {
        Firestore.firestore().collection("items")
            .order(by: "name")
            .limit(to: 100)
            .addSnapshotListener { snapshot, error in
                guard let snapshot else {
                    print("Error fetching snapshot: \(error?.localizedDescription ?? "error")")
                    return
                }
                let docs = snapshot.documents
                let items = docs.compactMap {
                    try? $0.data(as: ObjectItems.self)
                }
                withAnimation {
                    self.objects = items
                }
            }
    }
}
