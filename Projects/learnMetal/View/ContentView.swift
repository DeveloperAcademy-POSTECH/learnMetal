//
//  ContentView.swift
//  learnMetal
//
//  Created by Hyeok Cho on 8/13/25.
//

//  ContentView.swift
//  SwiftUI view that presents the MetalKit-backed MetalView
import SwiftUI

struct ContentView: View {
    var body: some View {
        MetalView()
            .ignoresSafeArea()
    }
}

#Preview {
    ContentView()
}
