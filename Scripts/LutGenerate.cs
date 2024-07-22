using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace ToonURP
{
    public class IntegralCalculator
    {
        public static double Calculate(Func<double, double> function, double begin, double end, int sampleCount)
        {
            double h = (end - begin) / sampleCount;
            double sum = 0.5 * (function(begin) + function(end));

            for (int i = 1; i < sampleCount; i++)
            {
                double x = begin + h * i;
                sum += function(x);
            }

            return h * sum;
        }
    }
    public class LutGenerate : MonoBehaviour
    {
        void Start()
        {
            Func<double, double> cosFunction = x => -Math.Sqrt(1 - x * x);
            double ans = IntegralCalculator.Calculate(cosFunction, 0, 1, 100);
            Debug.Log(ans);
        }
    }
}
