using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

public class BubbleMovement : MonoBehaviour
{
    [SerializeField] AnimationCurve heightDisplaceCurve;
    [SerializeField] Material refMat;
    [SerializeField] Material oilMat;


    // Start is called before the first frame update
    void Start()
    {
    }

    // Update is called once per frame
    void Update()
    {
        refMat.SetFloat("_HeightDisplace", heightDisplaceCurve.Evaluate(Time.time));
        oilMat.SetFloat("_HeightDisplace", heightDisplaceCurve.Evaluate(Time.time));
    }
}
