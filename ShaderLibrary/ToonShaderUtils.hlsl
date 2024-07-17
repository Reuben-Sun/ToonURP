#ifndef TOON_SHADER_UTILS_INCLUDED
#define TOON_SHADER_UTILS_INCLUDED

half LinearStep(half minValue, half maxValue, half input)
{
    return saturate((input-minValue) / (maxValue - minValue));
}

#endif