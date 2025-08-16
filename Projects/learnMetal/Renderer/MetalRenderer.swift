//
//  MetalRenderer.swift
//  learnMetal
//
//  Created by Hyeok Cho on 8/16/25.
//
import SwiftUI
import MetalKit

class MetalRenderer: Renderer {
    
    /*
     //updateViewportSize 함수와 직접적인 관련이 있는 건 아니지만,
     //MTLBuffer를 생성하기 위해 디바이스 객체 필요
     //createDataBuffers() 참고
     */
    private var device: MTLDevice
    
//MARK: updateViewportSize 관련 멤버
    
    /*
     //simd_uint2() -> (0, 0)을 반환
     //아직 실제 화면 크기를 전달 받기 전이므로,
     //우선 "뷰포트 크기"라는 값이 있음을 표현하기 위함.
     //사실 그냥 정수 (0, 0)으로도 가능하지만 굳이 simd_uint2를 쓰는 이유는 GPU 호환성 때문이라고 함
     */
    private var viewportSize = simd_uint2()
    private var viewportSizeBuffer: MTLBuffer!
    
//MARK: renderFrame 관련 멤버
    private var commandQueue: MTLCommandQueue
    private var renderPipelineState: MTLRenderPipelineState!
    
    private var triangleVertexBuffers: [MTLBuffer?] = Array(repeating: nil, count: kMaxFramesInFlight)
    private var frameNumber: UInt64 = 0
    
//MARK: 초기화
    init?(metalKitView: MTKView) {
        self.device = metalKitView.device ?? MTLCreateSystemDefaultDevice()!
        
        self.commandQueue = self.device.makeCommandQueue()!
        
        //메서드는 모든 멤버가 초기화 된 후에 작성해야 함.
        self.createRenderPipeline(pixelFormat: metalKitView.colorPixelFormat)
        /*
         //이거 해줘야 데이터 버퍼가 생성됨.
         //memcpy(viewportSizeBuffer.contents(), &viewportSize, MemoryLayout.size(ofValue: viewportSize))를 오류 없이 실행시키기 위함
         */
        self.createDataBuffers()
    }
    
//MARK: 버퍼 생성
    //버퍼란 사실상 메모리 공간을 의미함. 시작점(주소)과 끝점(주소)이 있음.
    private func createDataBuffers() {
        /*
         //simd_uint2길이만큼. 근데 sind_uint2는 UInt32 두개짜리
         //stride는 어떤 타입이든 안전하게, 패딩 여부 상관없이 공간을 확보하기 위해 사용. 사실 simd_uint2 정도의 작은 구조에는 굳이 이긴 함.
         //하지만 안전 관습적으로 stride를 쓰는 거 권장한다고 함.
         //options: .storageModeShared -> CPU랑 GPU가 모두 접근 가능한 메모리로
         //같은 데이터를 cpu gpu가 같이 써야 해서 shared로 설정
         //ex) CPU가 화면 크기(viewportSize)를 갱신하면, GPU가 그 값을 바로 셰이더에서 사용
         */
        viewportSizeBuffer = device.makeBuffer(length: MemoryLayout<simd_uint2>.stride, options: .storageModeShared)
        
        for bufferNumber in 0 ..< kMaxFramesInFlight {
            let buffer = device.makeBuffer(length: MemoryLayout<TriangleData>.stride, options: .storageModeShared)
            triangleVertexBuffers[bufferNumber] = buffer!
        }
    }
    
//MARK: 프로토콜 함수 구현
    func updateViewportSize(_ size: CGSize) {
        
        /*
         //CGFloat 타입을 UInt32타입으로 캐스팅
         //왜냐? simd_uint2()는 (UInt32, UI~t32) 타입으로 구성되어 있기 때문~
         //좀 더 근본적인 이유는, Swift(애플 CPU)에서는 64비트 정수를 쓰는데, Metal(애플 GPU)에서는 32비트 정수를 쓴다고 함
         */
        viewportSize.x = UInt32(size.width)
        viewportSize.y = UInt32(size.height)
        
        //셰이더용 화면 크기 포맷
        /*
         //viewportSize(simd_uint2)값을 viewportSizeBuffer(MTLBuffer)에 메모리 단위로 복사. 그래야 GPU가 바로 읽을 수 있음
         //memcpy는 memory copy하는 C 함수
         //viewportSizeBuffer.contents(): 버퍼가 가리키는 메모리 주소
         //&viewportSize: 복사할 데이터 값의 주소
         //MemoryLayout.size(ofValue: viewportSize): 복사 데이터의 바이트 크기
         // &viewportSize ~ (&viewportSize + MemoryLayout.size(ofValue: viewportSize) - 1) 사이의 비트를 모두 복사해서
         //viewportSizeBuffer.contents ~ (viewportSizeBuffer.contents + MemoryLayout.size(ofValue: viewportSize) - 1)에 붙여넣기
         */
        memcpy(viewportSizeBuffer.contents(), &viewportSize, MemoryLayout.size(ofValue: viewportSize))
    }
    
    func renderFrame(to view: MTKView) {
        guard let renderPassDescriptor = view.currentRenderPassDescriptor, view.device === commandQueue.device else { return }
        
        guard let commandBuffer = commandQueue.makeCommandBuffer(),
              //RenderCommandEncoder(...)와 endEncoding()은 짝꿍임.
              let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else { return }
        
        //출력 영역 범위 지정(0px, 0px)부터 (화면크기.x px, 화면크기.y px)까지
        let viewPort = MTLViewport(originX: 0, originY: 0, width: Double(viewportSize.x), height: Double(viewportSize.y), znear: 0.0, zfar: 1.0)
        renderEncoder.setViewport(viewPort)
        
        renderEncoder.setRenderPipelineState(renderPipelineState)
        
        frameNumber += 1
        
        let frameIndex = Int(frameNumber % UInt64(kMaxFramesInFlight))
        guard let vertexBuffer = triangleVertexBuffers[frameIndex] else { return }
        
        configureVertexData(for: vertexBuffer)
        
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: InputBufferIndex.vertexData.rawValue)
        renderEncoder.setVertexBuffer(viewportSizeBuffer, offset: 0, index: InputBufferIndex.viewportSize.rawValue)
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
        
        //RenderCommandEncoder(...)와 endEncoding()은 짝꿍임.
        renderEncoder.endEncoding()
        if let drawable = view.currentDrawable {
            commandBuffer.present(drawable)
        }
        commandBuffer.commit()
    }
    
//MARK: 렌더링 파이프라인 구성
    private func createRenderPipeline(pixelFormat: MTLPixelFormat) {
        guard let defaultLibrary = device.makeDefaultLibrary(),
              let vertexFunction = defaultLibrary.makeFunction(name: "vertexShader"),
              let fragmentFunction = defaultLibrary.makeFunction(name: "fragmentShader")
        else { return }
        
        let renderPipelineDescriptor = MTLRenderPipelineDescriptor()
        //아래 세 가지 속성은 필수속성. 없으면 에러남.
        renderPipelineDescriptor.vertexFunction = vertexFunction
        renderPipelineDescriptor.fragmentFunction = fragmentFunction
        //출력 타깃의 픽셀 포맷. 색상(color) 결과를 텍스쳐에 첨부한 것(attachment) 라는 의미
        renderPipelineDescriptor.colorAttachments[0].pixelFormat = pixelFormat
        
        do {
            renderPipelineState = try device.makeRenderPipelineState(descriptor: renderPipelineDescriptor)
        } catch { }
    }
    
    func configureVertexData(for buffer: MTLBuffer) {
        let radius: Float = 350.0
        
        var triangleData = TriangleData(
            vertex0: VertexData(position:.zero, color: .zero),
            vertex1: VertexData(position:.zero, color: .zero),
            vertex2: VertexData(position:.zero, color: .zero))
        
        triangleRedGreenBlue(radius: radius, triangleData: &triangleData)
        
        memcpy(buffer.contents(), &triangleData, MemoryLayout<TriangleData>.stride)
    }
}

//MARK: 인풋 데이터
let kMaxFramesInFlight = 3

enum InputBufferIndex: Int {
    case vertexData = 0
    case viewportSize = 1
}

struct TriangleData {
    var vertex0: VertexData
    var vertex1: VertexData
    var vertex2: VertexData
}

struct VertexData {
    var position: simd_float2
    var color: simd_float4
}

//inout: 참조 데이터 수정도 가능
func triangleRedGreenBlue(radius: Float, triangleData: inout TriangleData) {
    let angle0 = 0 * Float.pi / 180.0
    let angle1 = 120 * Float.pi / 180.0
    let angle2 = 240 * Float.pi / 180.0
    
//    let p0 = simd_float2(cos(angle0), sin(angle0)) * radius
//    let p1 = simd_float2(cos(angle1), sin(angle1)) * radius
//    let p2 = simd_float2(cos(angle2), sin(angle2)) * radius
    
    let p0 = simd_float2(0, 300)
    let p1 = simd_float2(300, -300)
    let p2 = simd_float2(-300, -300)
    
    let red = simd_float4(1, 0, 0, 1)
    
    triangleData.vertex0 = VertexData(position: p0, color: simd_float4(1, 0, 0, 1))
    triangleData.vertex1 = VertexData(position: p1, color: simd_float4(1, 1, 0, 1))
    triangleData.vertex2 = VertexData(position: p2, color: simd_float4(1, 0, 0, 1))
}

#Preview {
    ContentView()
}
