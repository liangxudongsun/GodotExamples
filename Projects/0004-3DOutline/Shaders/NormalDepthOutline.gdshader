shader_type spatial;
render_mode unshaded;

uniform sampler2D screen_texture : hint_screen_texture;
uniform sampler2D depth_texture  : hint_depth_texture;
uniform sampler2D normal_texture : hint_normal_roughness_texture;

uniform vec4 edge_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float normal_threshold = 0.25;
uniform float depth_threshold  = 0.02;

const float kX[9] = float[9](
    -1.0, 0.0, 1.0,
    -2.0, 0.0, 2.0,
    -1.0, 0.0, 1.0
);
const float kY[9] = float[9](
    -1.0, -2.0, -1.0,
     0.0,  0.0,  0.0,
     1.0,  2.0,  1.0
);

void fragment()
{
    vec2 texel_size = vec2(1.0) / vec2(textureSize(screen_texture, 0));
    
    // Initialize accumulators for Sobel convolution
    float depth_gx = 0.0;
    float depth_gy = 0.0;
    vec3 normal_gx = vec3(0.0);
    vec3 normal_gy = vec3(0.0);
    
    // Apply 3x3 Sobel kernel
    int idx = 0;
    for (int y = -1; y <= 1; y++) {
        for (int x = -1; x <= 1; x++) {
            vec2 offset = vec2(float(x), float(y)) * texel_size;
            vec2 sample_uv = SCREEN_UV + offset;
            
            // Sample depth (linear depth)
            float depth_sample = texture(depth_texture, sample_uv).r;
            
            // Sample normal (RGB contains normal, A contains roughness)
            vec3 normal_sample = texture(normal_texture, sample_uv).rgb * 2.0 - 1.0;
            
            // Accumulate weighted samples
            depth_gx += depth_sample * kX[idx];
            depth_gy += depth_sample * kY[idx];
            normal_gx += normal_sample * kX[idx];
            normal_gy += normal_sample * kY[idx];
            
            idx++;
        }
    }
    
    // Compute gradient magnitudes
    float depth_gradient = sqrt(depth_gx * depth_gx + depth_gy * depth_gy);
    float normal_gradient = length(normal_gx) + length(normal_gy); // Sum of magnitudes for XYZ
    
    // Determine if pixel is an edge
    bool is_edge = (depth_gradient > depth_threshold) || (normal_gradient > normal_threshold);
    
    // Sample original screen color
    vec4 screen_color = texture(screen_texture, SCREEN_UV);
    
    // Output: edge color for edges, screen color otherwise
    //ALBEDO = texture(depth_texture, SCREEN_UV).rgb * 50.0;
    //ALBEDO = texture(normal_texture, SCREEN_UV).rgb;
    ALBEDO = is_edge ? edge_color.rgb : screen_color.rgb;
    ALPHA = is_edge ? edge_color.a : screen_color.a;
}
