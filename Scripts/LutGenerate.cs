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
    public class MonteCarlo
    {
        public static double Integration(Func<double, double> function, double begin, double end, int sampleCount)
        {
            System.Random random = new System.Random();
            double sum = 0.0;

            for (int i = 0; i < sampleCount; i++)
            {
                double x = begin + (end - begin) * random.NextDouble();
                sum += function(x);
            }

            double average = sum / sampleCount;
            return (end - begin) * average;
        }
    }
    
    public class LutGenerate : MonoBehaviour
    {
        void Start()
        {
            Func<double, double> cosFunction = x => -Math.Sqrt(1 - x * x);
            double ans = IntegralCalculator.Calculate(cosFunction, 0, 1, 100);
            Debug.Log($"calc ans: {ans}");
            double ans2 = MonteCarlo.Integration(cosFunction, 0, 1, 10);
            Debug.Log($"monte carlo count 10 ans: {ans2}");
            ans2 = MonteCarlo.Integration(cosFunction, 0, 1, 100);
            Debug.Log($"monte carlo count 100 ans: {ans2}");
            ans2 = MonteCarlo.Integration(cosFunction, 0, 1, 500);
            Debug.Log($"monte carlo count 500 ans: {ans2}");
            ans2 = MonteCarlo.Integration(cosFunction, 0, 1, 1000);
            Debug.Log($"monte carlo count 1000 ans: {ans2}");
        }
    }
}
