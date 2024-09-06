//
//  ObjectFormVM.swift
//  ObjectCapture
//
//  Created by Eryus Tech on 05/09/24.
//

import FirebaseFirestore
import FirebaseStorage
import Foundation
import SwiftUI
import QuickLookThumbnailing

class ObjectFormViewModel: ObservableObject {
    let db = Firestore.firestore()
    let formType: FormType
    
    let id : String
    @Published var name = ""
    @Published var quantity = 0
    @Published var usdzURL: URL?
    @Published var thumbnailURL: URL?
    
    @Published var loadingState = LoadingType.none
    @Published var error: String?
    
    @Published var uploadProgress: uploadProgress?
    @Published var showUSDZSource = false
    @Published var selectedUSDZSource: USDZSourceType?
    
    let byCountFormatter: ByteCountFormatter = {
       let f = ByteCountFormatter()
        f.countStyle = .file
        return f
    }()
    
    var navigationTitle: String {
        switch formType {
        case .add:
            return "Add Item"
        case .edit(let objectItems):
            return "Edit Item"
        }
    }
    
    init(formType: FormType = .add) {
        self.formType = formType
        switch formType {
        case .add:
            id = UUID().uuidString
        case .edit(let obj):
            id = obj.id
            name = obj.name
            quantity = obj.quantity
            if let usdzURL = obj.usdzURL {
                self.usdzURL = usdzURL
            }
            if let thumbnailURL = obj.thumbnailURL {
                self.thumbnailURL = thumbnailURL
            }
        }
    }
    
    func save() throws {
        loadingState = .savingObject
        error = nil
        defer { loadingState = .none }
        var item: ObjectItems
        
        switch formType {
        case .add:
            item = .init(name: name, quantity: quantity)
        case .edit(let objectItems):
            item = objectItems
            item.name = name
            item.quantity = quantity
        }
        item.usdzLink = usdzURL?.absoluteString
        item.thumbnailLink = thumbnailURL?.absoluteString
        
        do {
            try db.document("items/\(item.id)")
                .setData(from:item)
        } catch {
            self.error = error.localizedDescription
            throw error
        }
    }
    
    @MainActor
    func deleteUSDZ() async {
        let storageRef = Storage.storage().reference()
        let usdzRef = storageRef.child("\(id).usdz")
        let thumbnailRef = storageRef.child("\(id).jpg")
        loadingState = .deleting(.usdzWithThumbnail)
        defer { loadingState = .none }
        do {
            try await usdzRef.delete()
            try? await thumbnailRef.delete()
            self.usdzURL = nil
            self.thumbnailURL = nil
        } catch {
            self.error = error.localizedDescription
        }
    }

    @MainActor
    func deleteObject() async throws {
        loadingState = .deleting(.item)
        do {
            try await db.document("items/\(id).usdz").delete()
            try? await Storage.storage().reference().child("\(id).usdz").delete()
            try? await Storage.storage().reference().child("\(id).jpg").delete()
        } catch {
            loadingState = .none
            throw error
        }
    }
    
    
    @MainActor
    func uploadUSDZ(fileURL: URL, isSecurity: Bool = false) async {
        if isSecurity, !fileURL.startAccessingSecurityScopedResource() {
            return
        }
        guard let data = try? Data(contentsOf: fileURL) else { return }
        if isSecurity {
            fileURL.stopAccessingSecurityScopedResource()
        }
        uploadProgress = .init(fractionCompleted: 0, totalUnitCount: 0, completedUnitCount: 0)
        loadingState = .uploading(.usdz)
        defer { loadingState = .none }
        do {
            //Upload USDZ to Firebase Storage
            let storageRef = Storage.storage().reference()
            let usdzRef = storageRef.child("\(id).usdz")
           _ = try await usdzRef.putDataAsync(data, metadata: .init(dictionary: ["contentType": "model/vnd.usd+zip"])) { [weak self] progress in
                guard let self, let progress else { return }
                self.uploadProgress = .init(fractionCompleted: progress.fractionCompleted, totalUnitCount: progress.totalUnitCount, completedUnitCount: progress.completedUnitCount)
            }
            let downloadURL = try await usdzRef.downloadURL()
            /// Generate Thumbnail
            let cacheDirURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
            let fileCacheURL = cacheDirURL.appending(path: "temp_\(id).usdz")
            try? data.write(to: fileCacheURL)
            let thumbReq = QLThumbnailGenerator.Request(fileAt: fileCacheURL, size: .init(width: 300, height: 300), scale: UIScreen.main.scale, representationTypes: .all)
            if let thumbnail = try? await QLThumbnailGenerator.shared.generateBestRepresentation(for: thumbReq),
               let jpgData = thumbnail.uiImage.jpegData(compressionQuality: 0.5) {
                loadingState = .uploading(.thumbnail)
                let thumbnailRef = storageRef.child("\(id).jpg")
                _ = try? await thumbnailRef.putDataAsync(jpgData, metadata: .init(dictionary: ["contentType":"image/jpeg"]), onProgress: { [weak self] progress in
                    guard let self, let progress else { return }
                    self.uploadProgress = .init(fractionCompleted: progress.fractionCompleted, totalUnitCount: progress.totalUnitCount, completedUnitCount: progress.completedUnitCount)
                })
                if let thumbnailURL = try? await thumbnailRef.downloadURL() {
                    self.thumbnailURL = thumbnailURL
                }
            }
            self.usdzURL = downloadURL
        } catch {
            self.error = error.localizedDescription
        }
    }
}

enum FormType: Identifiable {
    case add
    case edit(ObjectItems)
    
    var id: String {
        switch self {
        case .add:
            return "add"
        case .edit(let obj):
            return "edit-\(obj.id)"
        }
    }
}

enum LoadingType: Equatable {
    case none
    case savingObject
    case uploading(UploadType)
    case deleting(DeleteType)
}

enum USDZSourceType {
    case fileImporter, ObjectCapture
}

enum UploadType: Equatable {
    case usdz, thumbnail
}

enum DeleteType {
    case usdzWithThumbnail, item
}

struct uploadProgress {
    var fractionCompleted: Double
    var totalUnitCount: Int64
    var completedUnitCount: Int64
}

