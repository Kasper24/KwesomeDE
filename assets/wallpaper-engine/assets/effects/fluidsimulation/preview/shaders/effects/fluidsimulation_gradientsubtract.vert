
uniform vec4 g_Texture0Resolution;

attribute vec3 a_Position;
attribute vec2 a_TexCoord;

varying vec2 v_TexCoord;
varying vec4 v_TexCoordLeftTop;
varying vec4 v_TexCoordRightBottom;

void main() {
	gl_Position = vec4(a_Position, 1.0);
	v_TexCoord = a_TexCoord.xy;
	
	vec2 texelSize = CAST2(1.0) / g_Texture0Resolution.xy;
	v_TexCoordLeftTop = v_TexCoord.xyxy;
	v_TexCoordRightBottom = v_TexCoord.xyxy;
	
	v_TexCoordLeftTop.x -= texelSize.x;
	v_TexCoordLeftTop.w += texelSize.y;
	v_TexCoordRightBottom.x += texelSize.x;
	v_TexCoordRightBottom.w -= texelSize.y;
}
