#version 410

uniform vec4 fs_params[1];
uniform sampler2D tex0_smp;

layout(location = 0) out vec4 fragColor;

void main()
{
    fragColor = texture(tex0_smp, gl_FragCoord.xy / fs_params[0].xy);
}

