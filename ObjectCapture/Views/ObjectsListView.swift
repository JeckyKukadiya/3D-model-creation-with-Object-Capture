//
//  ObjectsListView.swift
//  ObjectCapture
//
//  Created by Eryus Tech on 05/09/24.
//

import SwiftUI

struct ObjectsListView: View {
    @StateObject private var vm = ObjectListViewModel()
    @State var formType: FormType?
    var body: some View {
        List {
            ForEach(vm.objects) { obj in
                ObjectListView(item: obj)
                    .listRowSeparator(.hidden)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        formType = .edit(obj)
                    }
            }
        }
        .navigationTitle("AR Objects")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("+ Item") {
                    formType = .add
                }
            }
        }
        .sheet(item: $formType) { type in
            NavigationStack {
                ObjectFormView(vm: .init(formType: type))
            }
            .presentationDetents([.fraction(0.85)])
            .interactiveDismissDisabled()
        }
        
        .onAppear {
            vm.listToItems()
        }
    }
}

struct ObjectListView: View {
    
    var item: ObjectItems
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .foregroundStyle(Color.gray.opacity(0.3))
                
                if let thumbnailURL = item.thumbnailURL {
                    AsyncImage(url: thumbnailURL) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable()
                                .aspectRatio(contentMode: .fit)
                        default:
                            ProgressView()
                            
                        }
                    }
                }
            }
            .overlay(RoundedRectangle(cornerRadius: 8.0)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
            .frame(width: 150, height: 150)
            VStack {
                Text(item.name)
                    .font(.headline)
                Text("Quantity: \(item.quantity)")
                    .font(.subheadline)
            }
        }
    }
}

#Preview {
    NavigationStack {
        ObjectsListView()
    }
}
