//
//  MetalView.swift
//  learnMetal
//
//  Created by Hyeok Cho on 8/13/25.
//

// MetalView wraps MTKView for SwiftUI

import SwiftUI
import MetalKit

//MetalView는 UIKit 기반이라 UIViewRepresentable 프로토콜 준수해야 함.
struct MetalView: UIViewRepresentable {
    //UIViewRepresentable 준수를 위한 메서드(선택사항)
    //Coordinator(조율자): 뷰와 위임자(Delegate) 사이의 조율
    //Coordinator라는 클래스를 정의했을 때는 무조건 구현해야 함
    //UIKit은 이벤트를 직접 반환하는 함수 호출 방식이 아니라,
    //뷰나 객체에서 발생하는 이벤트를 다른 객체에 위임(delegate)해서 처리하는 구조를 씀.
    func makeCoordinator() -> Coordinator {
        return Coordinator()
    }
    
    //UIViewRepresentable 준수를 위한 메서드 1
    func makeUIView(context: Context) -> MTKView {
        let mtkView = MTKView()
        mtkView.device = MTLCreateSystemDefaultDevice()
        
        let delegate = MetalKitViewDelegate(metalKitView: mtkView)
        //뷰와 코디네이터에 동일한 딜리게이트 참조
        mtkView.delegate = delegate
        context.coordinator.delegate = delegate
        return mtkView
    }
    //UIViewRepresentable 준수를 위한 메서드 2
    //하지만 뷰 업데이트는 딜리게이트가 이미 기능을 하므로 구현할 필요까지는 없음
    func updateUIView(_ uiView: MTKView, context: Context) {}
    
    class Coordinator {
        var delegate:MetalKitViewDelegate?
    }
}



#Preview {
    MetalView()
}
