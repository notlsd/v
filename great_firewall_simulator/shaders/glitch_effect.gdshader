shader_type canvas_item;

// Glitch 效果 Shader - 数字故障风格
// 使用屏幕纹理

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

// 控制参数
uniform float intensity : hint_range(0.0, 1.0) = 0.0;
uniform float time_scale : hint_range(0.1, 10.0) = 5.0;

void fragment() {
    vec2 uv = SCREEN_UV;
    vec3 color = texture(screen_texture, uv).rgb;
    
    if (intensity > 0.01) {
        // 时间随机种子
        float time_seed = TIME * time_scale;
        
        // 水平撕裂 - 随机 UV 偏移
        float tear_strength = intensity * 0.1;
        float tear_random = fract(sin(floor(uv.y * 20.0 + time_seed) * 43758.5453));
        if (tear_random > 0.8) {
            uv.x += (tear_random - 0.8) * tear_strength * 2.0;
        }
        
        // 颜色通道错位
        float channel_offset = intensity * 0.02;
        float r = texture(screen_texture, uv + vec2(channel_offset, 0.0)).r;
        float g = texture(screen_texture, uv).g;
        float b = texture(screen_texture, uv - vec2(channel_offset, 0.0)).b;
        color = vec3(r, g, b);
        
        // 噪点干扰
        float noise = fract(sin(dot(uv + time_seed, vec2(12.9898, 78.233))) * 43758.5453);
        if (noise > 0.95) {
            color = mix(color, vec3(1.0), intensity * 0.5);
        }
        
        // 偶尔的完全黑块
        float block_noise = fract(sin(floor(uv.y * 10.0 + time_seed * 2.0) * 12345.6789));
        if (block_noise > 0.97 && intensity > 0.5) {
            color = vec3(0.0);
        }
    }
    
    COLOR = vec4(color, 1.0);
}
