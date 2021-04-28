using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class BubbleMovementScript : MonoBehaviour
{
    [Header("Bobbing")]
    [SerializeField] [Range(0.5f, 2.0f)] [InspectorName("Bob Height")] float startingBobHeight;
    [SerializeField] [Range(0.0f, 1.0f)] float bobSpeed;
    float currentBobPosOffset;
    Vector3 startingPos;
    [Header("Rotation")]
    [SerializeField] [Range(0.0f, 0.5f)] [InspectorName("X Rotation Speed")] float xRotationAmount;
    [SerializeField] [Range(0.0f, 0.5f)] [InspectorName("Y Rotation Speed")] float yRotationAmount;
    [SerializeField] [Range(0.0f, 0.5f)] [InspectorName("Z Rotation Speed")] float zRotationAmount;

    // Start is called before the first frame update
    void Start()
    {

    }

    // Update is called once per frame
    void Update()
    {
        UpdateBobHeight();
        UpdateRotation();
    }

    void UpdateBobHeight()
    {
        currentBobPosOffset = (Mathf.Sin(Time.time * bobSpeed * 5f) + 1.0f) * startingBobHeight;
        transform.position = startingPos;
        transform.position = transform.position + new Vector3(0.0f, currentBobPosOffset, 0.0f);
    }

    void UpdateRotation()
    {
        transform.Rotate(xRotationAmount, yRotationAmount, zRotationAmount);
    }
}
