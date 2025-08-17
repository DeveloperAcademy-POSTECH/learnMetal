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
        
        //버텍스 버퍼가 있는지 확인~~
        guard let vertexBuffer = triangleVertexBuffers[frameIndex] else { return }
        
        //버퍼 있으면 버텍스버퍼의 내부를 채움
        configureVertexData(for: vertexBuffer)
        
        /*
         //InputBufferIndex의 vertexData의 rawValue는 0임.
         //즉, 버텍스 버퍼의 0번 슬롯에 할당하는 것임
         //Shaders.metal의 InputBufferIndexForVertexData에 해당
         */
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: InputBufferIndex.vertexData.rawValue)
        /*
         //InputBufferIndex의 viewportSize의 rawValue는 1임.
         //버텍스 버퍼의 1번 슬롯에 할당
         //ShaderTypes.h에서도 enum으로 선언된 친구가 있음.
         //InputBufferIndexForViewportSize에 해당. 이 값도 0임.
         //그리고 이게 Shaders.metal에서 buffer(InputBufferIndexForViewportSize)라고 되어 있는데, InputBufferIndexForViewportSize = 1 이니깐 사실상 buffer(1)
         */
        renderEncoder.setVertexBuffer(viewportSizeBuffer, offset: 0, index: InputBufferIndex.viewportSize.rawValue)
        
        /*
         //type: 형태
         //vertexStart: 시작 정점
         //vertexCount: 몇 개의 정점 쓸 지
         //vertexBuffer에 존재하는 3개의 정점을 삼각형으로 해석하여 그려라.
         //버텍스버퍼에 10개의 점이 있어도 0 ~ (vertexCount - 1)번까지의 점만 사용
         //shaders.metal에는
         */
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
        
        //RenderCommandEncoder(...)와 endEncoding()은 짝꿍임.
        renderEncoder.endEncoding()
        if let drawable = view.currentDrawable {
            commandBuffer.present(drawable)
        }
        commandBuffer.commit()
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
        //[]안의 숫자는 컬러 버퍼 슬롯. 기본값은 일단 0
        renderPipelineDescriptor.colorAttachments[0].pixelFormat = pixelFormat
        
        do {
            renderPipelineState = try device.makeRenderPipelineState(descriptor: renderPipelineDescriptor)
        } catch { }
    }
    
    //버텍스 버퍼 내부 채우기
    func configureVertexData(for buffer: MTLBuffer) {
        let radius: Float = 350.0
        
        //처음엔 다 0,0,0에 색상도 0,0,0임
        var triangleData = TriangleData(
            vertex0: VertexData(position:.zero, color: .zero),
            vertex1: VertexData(position:.zero, color: .zero),
            vertex2: VertexData(position:.zero, color: .zero))
        //여기서 위치와 색상이 결정됨
        triangleRedGreenBlue(radius: radius, triangleData: &triangleData)
        
        //삼각형 버텍스 구조체 데이터가 버텍스 단위로 메모리에 저장됨
        //이를테면 ..., vertex0, vertex1, vertex2, ...로
        //그리고 buffer는 상위 코드에서 vertexBuffer를 받아 왔으니, 여기에 채워지겠져?
        memcpy(buffer.contents(), &triangleData, MemoryLayout<TriangleData>.stride)
    }
}


#Preview {
    ContentView()
}
