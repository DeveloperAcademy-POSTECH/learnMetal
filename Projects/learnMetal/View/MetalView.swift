//
//  MetalView.swift
//  learnMetal
//
//  Created by Hyeok Cho on 8/13/25.
//

// MetalView wraps MTKView for SwiftUI

import SwiftUI
import MetalKit

struct MetalView: UIViewRepresentable {
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    func makeUIView(context: Context) -> MTKView {
        let mtkView = MTKView()
        mtkView.device = MTLCreateSystemDefaultDevice()
        
        let renderer = Renderer(metalKitView: mtkView)
        mtkView.delegate = renderer
        context.coordinator.renderer = renderer
        
        return mtkView
    }
    func updateUIView(_ uiView: MTKView, context: Context) {}
    class Coordinator {
        var renderer: Renderer?
    }
}


#Preview {
    MetalView()
}
