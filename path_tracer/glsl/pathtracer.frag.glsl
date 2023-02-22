
const float FOVY = 19.5f * PI / 180.0;


Ray rayCast() {
    vec2 offset = vec2(rng(), rng());
    vec2 ndc = (vec2(gl_FragCoord.xy) + offset) / vec2(u_ScreenDims);
    ndc = ndc * 2.f - vec2(1.f);

    float aspect = u_ScreenDims.x / u_ScreenDims.y;
    vec3 ref = u_Eye + u_Forward;
    vec3 V = u_Up * tan(FOVY * 0.5);
    vec3 H = u_Right * tan(FOVY * 0.5) * aspect;
    vec3 p = ref + H * ndc.x + V * ndc.y;

    return Ray(u_Eye, normalize(p - u_Eye));
}

vec3 Li_Direct(Ray ray) {
    Intersection isect = sceneIntersect(ray);
    if (dot(isect.Le, isect.Le) > 0.f) {
        return isect.Le;
    }
    vec3 wiW;
    float pdf;
    int chosenLightIdx, chosenLightID;
    vec3 direct_light = Sample_Li(ray.origin + isect.t * ray.direction, isect.nor, wiW, pdf, chosenLightIdx, chosenLightID);
    vec3 f = f(isect, -ray.direction, wiW);

    return f*direct_light*AbsDot(wiW, isect.nor)/pdf;
}

// TODO: Implement naive integration
vec3 Li_Naive(Ray ray) {
    vec3 throughput = vec3(1.f);
        for (int i = 0; i < MAX_DEPTH; ++i) {
            Intersection isect = sceneIntersect(ray);
            //if no intersection
            if (isect.t == INFINITY) {
                return vec3(0.);
            }
            //if le > 0
            if (dot(isect.Le, isect.Le) > 0.f) {
                return isect.Le * throughput;
            }
            vec2 xi = vec2(rng(), rng());
            vec3 woW = -ray.direction;
            vec3 wiW;
            float pdf;
            int sampledType;
            vec3 f = Sample_f(isect, woW, xi, wiW, pdf, sampledType);
            //check pdf == 0
            if (pdf == 0.f) {
                break;
            }
            ray = SpawnRay(ray.origin + isect.t * ray.direction, wiW);
            throughput *= f*AbsDot(wiW, isect.nor)/pdf;
        }
        //go through all iterations
        return vec3(0.f);
}

vec3 Li_DirectMIS(Ray ray) {
    //ray 1
    vec3 accumLight = vec3(0.f);
    Intersection isect = sceneIntersect(ray);
    if (dot(isect.Le, isect.Le) > 0.f) {
        return isect.Le;
    }

    vec3 wiW;
    vec3 woW = -ray.direction;
    float pdf;
    int chosenLightIdx, chosenLightID;
    vec3 directLight = Sample_Li(ray.origin + isect.t * ray.direction, isect.nor, wiW, pdf, chosenLightIdx, chosenLightID);
    vec3 f = f(isect, woW, wiW);

    Ray testRay = SpawnRay(ray.origin + isect.t * ray.direction, wiW);
    Intersection testIsect = sceneIntersect(testRay);

    if (testIsect.t != INFINITY) {
        if (pdf > 0.f) {
            float brdfPdf = Pdf(isect, ray.direction, wiW);
            float weight = PowerHeuristic(1, pdf, 1, brdfPdf);
            accumLight += weight*f*directLight*AbsDot(wiW, isect.nor)/pdf;
        }
    }

    //ray2
    vec2 xi = vec2(rng(), rng());
    wiW = vec3(0.);
    pdf = 0.;
    int sampledType;
    vec3 f2 = Sample_f(isect, woW, xi, wiW, pdf, sampledType);

    if(pdf == 0.0f) {
        return accumLight;
    }
    wiW = normalize(wiW);
    testRay = SpawnRay(ray.origin + isect.t * ray.direction, wiW);
    testIsect = sceneIntersect(testRay);

    float weight2 = 1.f;
    vec3 light2 = vec3(0.);
    float lightPdf = Pdf_Li(ray.origin + isect.t * ray.direction, isect.nor, wiW, chosenLightIdx);
    if (lightPdf > 0.f) {

        weight2 = PowerHeuristic(1, pdf, 1, lightPdf);
        if (testIsect.t != INFINITY) {
            if (dot(testIsect.Le, testIsect.Le) > 0.f) {
                light2 = testIsect.Le;
            }
        }
    }

    accumLight += weight2*f2*light2*AbsDot(wiW, isect.nor)/pdf;
    return accumLight;
}

void main()
{
    seed = uvec2(u_Iterations, u_Iterations + 1) * uvec2(gl_FragCoord.xy);

    Ray ray = rayCast();

    // TODO: Implement Li_Naive
    vec3 thisIterationColor = Li_DirectMIS(ray);
    //vec3 thisIterationColor = Li_Direct(ray);
    //vec3 thisIterationColor = Li_Naive(ray);

    // TODO: Set out_Col to the weighted sum of thisIterationColor
    // and all previous iterations' color values.
    // Refer to pathtracer.defines.glsl for what variables you may use
    // to acquire the needed values.
    //out_Col = vec4(thisIterationColor, 1.);
    out_Col = mix(texture(u_AccumImg,fs_UV), vec4(thisIterationColor,1.0f), 1.0f/u_Iterations);
}
