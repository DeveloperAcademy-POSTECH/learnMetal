//
//  Renderer.swift
//  learnMetal
//
//  Created by Hyeok Cho on 8/13/25.
//

import MetalKit

class Renderer: NSObject, MTKViewDelegate {
    
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
        let vertices: [Float] = [
            0.0, 0.5, 0.0,
            -0.5, -0.5, 0.0,
            0.0, 0.0, 0.0
        ]

        let vertexBuffer = device.makeBuffer(bytes: vertices, length: vertices.count * MemoryLayout<Float>.size, options: [])
        
        guard let library = device.makeDefaultLibrary() else{
            return
        }
        let vertexFunction = library.makeFunction(name: "vertexShader")
        let fragmentFunction = library.makeFunction(name: "fragmentShader")
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat
        
        let pipelineState = try! device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        
        guard let renderPassDescriptor = view.currentRenderPassDescriptor, let drawable = view.currentDrawable else {
            return
        }
        let commandBuffer = commandQueue.makeCommandBuffer()!
        if let commandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) {
            commandEncoder.setRenderPipelineState(pipelineState)
            commandEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
            commandEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
            commandEncoder.endEncoding()
        }
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}
