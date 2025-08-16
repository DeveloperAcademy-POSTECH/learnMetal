import MetalKit

protocol Renderer {
    func updateViewportSize(_ size: CGSize)
    func renderFrame(to: MTKView)
}
