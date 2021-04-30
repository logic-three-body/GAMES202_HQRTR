class PRTMaterial extends Material{
    constructor(precomputeL, vertexShader, fragmentShader)
    {
        console.log('precomputeL ' + precomputeL);
        let lightColor = getMat3ValueFromRGB(precomputeL);
        super({
            'aPrecomputeLR': { type: 'matrix3fv', value: lightColor[0] },
            'aPrecomputeLG': { type: 'matrix3fv', value: lightColor[1] },
            'aPrecomputeLB': { type: 'matrix3fv', value:  lightColor[2] },
            
        }, ['aPrecomputeLT'], vertexShader, fragmentShader, null);
    }
}

async function buildPRTMaterial(precomputeL,vertexPath,fragmentPath)
{
    let vertexShader = await getShaderString(vertexPath);
    let fragmentShader = await getShaderString(fragmentPath);
    console.log(precomputeL);
    return new PRTMaterial(precomputeL,vertexShader,fragmentShader);
}