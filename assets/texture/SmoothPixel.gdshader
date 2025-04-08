shader_type canvas_item;
render_mode unshaded;

// Controlli HSV
uniform float hue_target : hint_range(0, 1) = 0.95; // 342° (carminio)
uniform float saturation_power : hint_range(1, 5) = 3.5;
uniform float value_corruption : hint_range(0.3, 1.5) = 0.7;
uniform float blood_dominance : hint_range(0, 1) = 0.98; 

// Texture must have 'Filter'-flag enabled!

// Automatic smoothing
// independent of geometry and perspective
vec4 texturePointSmooth(sampler2D smp, vec2 uv, vec2 pixel_size)
{
	vec2 ddx = dFdx(uv);
	vec2 ddy = dFdy(uv);
	vec2 lxy = sqrt(ddx * ddx + ddy * ddy);
	
	vec2 uv_pixels = uv / pixel_size;
	
	vec2 uv_pixels_floor = round(uv_pixels) - vec2(0.5f);
	vec2 uv_dxy_pixels = uv_pixels - uv_pixels_floor;
	
	uv_dxy_pixels = clamp((uv_dxy_pixels - vec2(0.5f)) * pixel_size / lxy + vec2(0.5f), 0.0f, 1.0f);
	
	uv = uv_pixels_floor * pixel_size;
	
	return textureGrad(smp, uv + uv_dxy_pixels * pixel_size, ddx, ddy);
}

// RGB to HSV conversion
vec3 rgb2hsv(vec3 c) {
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

// HSV to RGB conversion
vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

void fragment() {
    COLOR = texturePointSmooth(TEXTURE, UV, TEXTURE_PIXEL_SIZE);
    
    // Converti a HSV
    vec3 hsv = rgb2hsv(COLOR.rgb);
    
    // Distorsione Malvagia
    float hue_distortion = mix(
        hsv.x, 
        hue_target + sin(TIME * 5.0 + UV.x * 50.0) * 0.02, // Effetto sangue pulsante
        blood_dominance
    );
    
    // Applica modifiche HSV
    hsv.x = hue_distortion;
    hsv.y = pow(hsv.y, 1.0/saturation_power); // Inversione curva saturazione
    hsv.z = clamp(hsv.z * value_corruption, 0.1, 0.9); // Limiti drammatici
    
    // Converti a RGB
    vec3 evil_rgb = hsv2rgb(hsv);
    
    // Aumenta il rosso selettivamente
    float red_power = smoothstep(0.3, 0.9, hsv.z);
    evil_rgb.r += red_power * 0.3;
    
    COLOR.rgb = mix(COLOR.rgb, evil_rgb, blood_dominance);
    
    // Effetto finale "Sangue Vecchio"
    COLOR.rgb *= vec3(1.1, 0.85, 0.85); // Tinta seppia-rossastra
    COLOR.rgb = clamp(COLOR.rgb, 0.0, 1.0);
}