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
        //MTKView 생성
        let mtkView = MTKView()
        //기기 정보 가져오기
        mtkView.device = MTLCreateSystemDefaultDevice()
        //배경색 설정
        mtkView.clearColor = MTLClearColorMake(0.0, 0.5, 1.0, 1.0)
        //SetNeedsDisplay()가 호출될 때만 화면을 새로 그립니다.
        mtkView.enableSetNeedsDisplay = true
        //렌더러를 생성합니다. MTKViewDelegate 프로토콜을 따라야 합니다.
        let renderer = Renderer(metalKitView: mtkView)
        //딜리게이트에 렌더러를 위임합니다.
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
