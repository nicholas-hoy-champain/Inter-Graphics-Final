using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class DayNightCycle : MonoBehaviour
{
    [SerializeField] float sunSpeed;

    Vector3 CENTER = new Vector3(0.0f, 0.0f, 0.0f);

    bool isGoingFro = true;

    // Start is called before the first frame update
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        if (isGoingFro)
        {
            this.transform.RotateAround(CENTER, Vector3.right, sunSpeed);
            if (this.transform.rotation.eulerAngles.x < 5)
            {
                isGoingFro = false;
            }
        }
        else
        {
            this.transform.RotateAround(CENTER, Vector3.right, -sunSpeed);
            if (this.transform.rotation.eulerAngles.x < 5)
            {
                isGoingFro = true;
            }
        }

    }
}
