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
        mtkView.clearColor = MTLClearColorMake(0.0, 0.5, 1.0, 1.0)
        mtkView.enableSetNeedsDisplay = true
        let renderer = AAPLRenderer(metalKitView: mtkView)
        mtkView.delegate = renderer
        context.coordinator.renderer = renderer
        return mtkView
    }
    func updateUIView(_ uiView: MTKView, context: Context) {}
    class Coordinator {
        var renderer: AAPLRenderer?
    }
}


#Preview {
    MetalView()
}
