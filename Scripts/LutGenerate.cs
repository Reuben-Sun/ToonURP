using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace ToonURP
{
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
            
            double ans = MonteCarlo.Integration(cosFunction, 0, 1, 1000);
            Debug.Log($"monte carlo count 1000 ans: {ans}");
        }
    }
}
