//
//  Shaders.metal
//  learnMetal
//
//  Created by Hyeok Cho on 8/15/25.
//

#include <metal_stdlib>
using namespace metal;

#include "ShaderTypes.h"

struct RasterizerData {
    float4 position [[position]];
    float4 color;
};

vertex RasterizerData
//여기서는 각각의 점들을 처리. 이 점들이 무엇의 일부인지는 알 수 없음
//memcpy(buffer.contents(), &triangleData, MemoryLayout<TriangleData>.stride)
//constant VertexData *vertexData는 이걸 배열처럼 받음
//첫 번째 호출: vertexID = 0 → vertexData[0] (== triangleData.vertex0)
vertexShader(//내부적으로 알아서 처리하는 매개변수 Metal이 알아서 호출 시마다 값 +1. 초기 값 0.
             uint vertexID [[vertex_id]],
             //버퍼 0번에는 버텍스 데이터 있을거야~ 메탈렌더러에서 그렇게 보냈으니깐.
             //renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: InputBufferIndex.vertexData.rawValue)
             constant VertexData *vertexData [[buffer(InputBufferIndexForVertexData)]],
             constant simd_uint2 *viewportSizePointer [[buffer(InputBufferIndexForViewportSize)]])
{
    RasterizerData out;
    
    //vetexID번째 정점 정보를 가져와
    simd_float2 pixelSpacePosition = vertexData[vertexID].position.xy;
    simd_float2 viewportSize = simd_float2(*viewportSizePointer);
    
    //픽셀을 NDC 좌표로 변환. Metal은 NDC 좌표계를 쓰기 때문
    //NDC 좌표란 -1 ~ 1 사이 값으로 정규화된 좌표계임
    //화면 중심이 0,0이므로 반으로 나눈거
    out.position.xy = pixelSpacePosition / (viewportSize / 2.0);
    out.position.z = 0.0;
    out.position.w = 1.0;
    
    out.color = vertexData[vertexID].color;
    
    return out;
}

fragment float4 fragmentShader(RasterizerData in [[stage_in]]) {
    return in.color;
}
