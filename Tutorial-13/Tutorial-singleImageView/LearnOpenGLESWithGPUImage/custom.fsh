varying highp vec2 textureCoordinate;
uniform sampler2D inputImageTexture;

void main()
{
    lowp vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
    textureColor.b = textureColor.b * 0.5;
    
    gl_FragColor = textureColor;
}
