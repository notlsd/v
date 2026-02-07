shader_type canvas_item;

// CRT 效果 Shader - 赛博朋克复古显示器风格
// 使用屏幕纹理进行后处理

// 屏幕纹理
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

// 控制参数
uniform float scanline_opacity : hint_range(0.0, 1.0) = 0.3;
uniform float scanline_frequency : hint_range(100.0, 500.0) = 240.0;
uniform float barrel_distortion : hint_range(0.0, 0.5) = 0.1;
uniform float chromatic_aberration : hint_range(0.0, 10.0) = 2.0;
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.3;

// 桶形畸变
vec2 barrel_distort(vec2 uv) {
    vec2 centered = uv - 0.5;
    float dist = dot(centered, centered);
    vec2 distorted = centered * (1.0 + barrel_distortion * dist);
    return distorted + 0.5;
}

void fragment() {
    vec2 uv = barrel_distort(SCREEN_UV);
    
    // 边界检查 - 使用 clamp
    uv = clamp(uv, vec2(0.0), vec2(1.0));
    
    // 色差偏移
    float ca_offset = chromatic_aberration / 1000.0;
    float r = texture(screen_texture, uv + vec2(ca_offset, 0.0)).r;
    float g = texture(screen_texture, uv).g;
    float b = texture(screen_texture, uv - vec2(ca_offset, 0.0)).b;
    vec3 color = vec3(r, g, b);
    
    // 扫描线
    float scanline = sin(uv.y * scanline_frequency * 3.14159) * 0.5 + 0.5;
    scanline = mix(1.0, scanline, scanline_opacity);
    color *= scanline;
    
    // 暗角
    vec2 vignette_uv = uv * (1.0 - uv);
    float vignette = vignette_uv.x * vignette_uv.y * 15.0;
    vignette = pow(vignette, vignette_strength);
    color *= vignette;
    
    COLOR = vec4(color, 1.0);
}
