//
//  Renderer.swift
//  learnMetal
//
//  Created by Hyeok Cho on 8/13/25.
//

import MetalKit

class AAPLRenderer: NSObject, MTKViewDelegate {
    let device: MTLDevice
    let commandQueue: MTLCommandQueue

    init(metalKitView: MTKView) {
        self.device = metalKitView.device ?? MTLCreateSystemDefaultDevice()!
        self.commandQueue = self.device.makeCommandQueue()!
        super.init()
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // Resize handling if needed
    }
    
    func draw(in view: MTKView) {
        guard let renderPassDescriptor = view.currentRenderPassDescriptor, let drawable = view.currentDrawable else {
            return
        }
        let commandBuffer = commandQueue.makeCommandBuffer()!
        if let commandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) {
            commandEncoder.endEncoding()
        }
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}
