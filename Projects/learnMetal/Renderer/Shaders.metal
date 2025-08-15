//
//  Shaders.metal
//  learnMetal
//
//  Created by Hyeok Cho on 8/15/25.
//

#include <metal_stdlib>
using namespace metal;

vertex float4 vertexShader(const device float3* vertexArray [[buffer(0)]], uint vertexId [[vertex_id]]) {
    return float4(vertexArray[vertexId], 1.0);
}

fragment float4 fragmentShader() {
    return float4(1, 0, 0, 1);
}
