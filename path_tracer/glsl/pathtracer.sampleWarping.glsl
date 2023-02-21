
vec3 squareToDiskConcentric(vec2 xi) {
    // TODO
    float theta, r, u, v;
    float a = 2*xi.x-1;
    float b = 2*xi.y-1;

    if(a == 0 && b == 0) {
        return vec3(0, 0, 0);
    }

    if(abs(a) > abs(b)) {
        r = a;
        theta = PI/4 * (b/a);
    } else {
        r = b;
        theta = PI/2 - PI/4 * (a/b);
    }

    u = r*cos(theta);
    v = r*sin(theta);
    return vec3(u,v,0);
}

vec3 squareToHemisphereCosine(vec2 xi) {
    // TODO
    vec3 disk=squareToDiskConcentric(xi);
    float x=disk.x;
    float y=disk.y;
    float z=sqrt(max(0, 1-x*x-y*y));
    return vec3(x,y,z);
}

float squareToHemisphereCosinePDF(vec3 sample) {
    // TODO
    float cosTheta = dot(sample, vec3(0.f,0.f,1.f));
    return cosTheta/PI;
}

vec3 squareToSphereUniform(vec2 sample) {
    // TODO
    float z=1-2*sample.x;
    float x=cos(sample.y*PI*2)*sqrt(1-z*z);
    float y=sin(sample.y*PI*2)*sqrt(1-z*z);
    return vec3(x,y,z);
}

float squareToSphereUniformPDF(vec3 sample) {
    // TODO
    return 1/(4*PI);
}
