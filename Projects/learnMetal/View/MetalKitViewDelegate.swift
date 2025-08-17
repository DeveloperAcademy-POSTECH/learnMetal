//
//  MetalKitViewDelegate.swift
//  learnMetal
//
//  Created by Hyeok Cho on 8/16/25.
//
import MetalKit

class MetalKitViewDelegate : NSObject, MTKViewDelegate {
    private var renderer: Renderer
    private weak var metalKitView: MTKView? //약한 참조 하는 이유?
    
    init?(metalKitView: MTKView) {
        guard let renderer = MetalRenderer(metalKitView: metalKitView) else { return nil }
        self.renderer = renderer
        self.metalKitView = metalKitView
        super.init()
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        //함수의 인자로 들어온 view와 metalKitView가 동일한 대상인지 확인
        //===은 ==의 인스턴스 비교 버전
        //값이 false면 함수 바로 종료. 아니면 다음 코드 실행
        guard self.metalKitView === view else { return }
        renderer.updateViewportSize(size)
    }
    
    func draw(in view: MTKView) {
        guard self.metalKitView === view else { return }
        renderer.renderFrame(to: view)
    }
}
