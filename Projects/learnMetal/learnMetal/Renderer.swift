//
//  Renderer.swift
//  learnMetal
//
//  Created by Hyeok Cho on 8/13/25.
//

import MetalKit

//지금 렌더러는 실제로는 아무 기능을 하지 않습니다. 형식 상 필요합니다.
//렌더러는 MTKViewDelegate 프로토콜을 따라야 합니다.
class Renderer: NSObject, MTKViewDelegate {
    let device: MTLDevice
    let commandQueue: MTLCommandQueue

    init(metalKitView: MTKView) {
        self.device = metalKitView.device ?? MTLCreateSystemDefaultDevice()!
        self.commandQueue = self.device.makeCommandQueue()!
        super.init()
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // 화면 크기 조정 기능 필요하면 구현
    }
    
    func draw(in view: MTKView) {
        //렌더 패스 디스크립터와 해당 렌더 패스 디스크립터를 관리하는 드로어블을 생성합니다.
        guard let renderPassDescriptor = view.currentRenderPassDescriptor, let drawable = view.currentDrawable else {
            return
        }
        //커맨드버퍼를 생성합니다.
        let commandBuffer = commandQueue.makeCommandBuffer()!
        //커맨드버퍼 내의 커맨드인코더에 렌더 패스 디스크립터를 인자로 넘겨줌으로써 렌더 패스를 구성합니다.
        if let commandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) {
            //마지막에는 endEncoding()메서드로 인코딩 명령을 마칩니다.
            commandEncoder.endEncoding()
        }
        //드로어블 표시 명령을 커맨드버퍼에 전달합니다.
        commandBuffer.present(drawable)
        //지금가지의 속성 설정이 된 커맨드버퍼를 실행합니다.
        commandBuffer.commit()
    }
}
