//
//  InputBufferIndex.swift
//  learnMetal
//
//  Created by Hyeok Cho on 8/17/25.
//
import simd

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
//    let angle0 = 0 * Float.pi / 180.0
//    let angle1 = 120 * Float.pi / 180.0
//    let angle2 = 240 * Float.pi / 180.0
//    
//    let p0 = simd_float2(cos(angle0), sin(angle0)) * radius
//    let p1 = simd_float2(cos(angle1), sin(angle1)) * radius
//    let p2 = simd_float2(cos(angle2), sin(angle2)) * radius
    
    let p0 = simd_float2(0, 300)
    let p1 = simd_float2(300, -300)
    let p2 = simd_float2(-300, -300)
    
//    let red = simd_float4(1, 0, 0, 1)
    
    triangleData.vertex0 = VertexData(position: p0, color: simd_float4(1, 0, 0, 1))
    triangleData.vertex1 = VertexData(position: p1, color: simd_float4(1, 1, 0, 1))
    triangleData.vertex2 = VertexData(position: p2, color: simd_float4(1, 0, 0, 1))
}
