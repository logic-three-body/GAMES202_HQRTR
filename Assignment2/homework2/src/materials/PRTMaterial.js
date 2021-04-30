class PRTMaterial extends Material{
    constructor(precomputeLR, precomputeLG, precomputeLB,precomputeL, vertexShader, fragmentShader)
    {
        console.log('precomputeLR '+precomputeLR);
        console.log('precomputeLG '+precomputeLG);
        console.log('precomputeLB ' + precomputeLB);
        console.log('precomputeL ' + precomputeL);
        let lightColor = getMat3ValueFromRGB(precomputeL);
        super({
            'aPrecomputeLR': { type: 'matrix3fv', value: lightColor[0] },
            'aPrecomputeLG': { type: 'matrix3fv', value: lightColor[1] },
            'aPrecomputeLB': { type: 'matrix3fv', value:  lightColor[2] },
            
        }, ['aPrecomputeLT'], vertexShader, fragmentShader, null);
    }
}

async function buildPRTMaterial(vertexPath,fragmentPath)
{
    let vertexShader = await getShaderString(vertexPath);
    let fragmentShader = await getShaderString(fragmentPath);

    let precomputeLR=[] ;
    let precomputeLB=[] ;
    let precomputeLG=[] ;
    console.log("v：" + vertexPath);
    console.log("f：" + fragmentPath);
    for (let i = 0; i < 3; ++i)
    {
        precomputeLR[i] = [];
        precomputeLB[i] = [];
        precomputeLG[i] = [];
        for (let j = 0; j < 3; ++j)
        {
            precomputeLR[i][j] = precomputeL[0][3 * i + j][0];
            precomputeLG[i][j] = precomputeL[0][3 * i + j][1];
            precomputeLB[i][j] = precomputeL[0][3 * i + j][2];
        }
    }
    console.log(precomputeL);
    return new PRTMaterial(precomputeLR,precomputeLG,precomputeLB,precomputeL,vertexShader,fragmentShader);
}