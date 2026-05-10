double clampD(double value, double min, double max) =>
    value < min ? min : (value > max ? max : value);

double lerpD(double a, double b, double t) => a + (b - a) * t;
