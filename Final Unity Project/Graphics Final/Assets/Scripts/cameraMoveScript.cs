using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class cameraMoveScript : MonoBehaviour
{

    //credits to carceloroca at https://answers.unity.com/questions/666905/in-game-camera-movement-like-editor.html for these basic camera movements

    [SerializeField]
    float lookSpeedH = 2f;

    [SerializeField]
    float lookSpeedV = 2f;

    [SerializeField]
    float zoomSpeed = 2f;

    [SerializeField]
    float baseWasdMoveSpeed;
    [SerializeField]
    float shiftWASDSpeedMultiplier;

    float wasdZoomSpeed;

    [SerializeField]
    float dragSpeed = 3f;

    float yaw = 0f;
    float pitch = 0f;

    private void Start()
    {
        // Initialize the correct initial rotation
        yaw = transform.eulerAngles.y;
        pitch = transform.eulerAngles.x;
    }

    private void Update()
    {
        if (Input.GetKey(KeyCode.LeftShift))
        {
            wasdZoomSpeed = baseWasdMoveSpeed * shiftWASDSpeedMultiplier;
        }
        else
            wasdZoomSpeed = baseWasdMoveSpeed;


        //Look around with Left Mouse
        if (Input.GetMouseButton(0))
        {
            yaw += lookSpeedH * Input.GetAxis("Mouse X");
            pitch -= lookSpeedV * Input.GetAxis("Mouse Y");

            transform.eulerAngles = new Vector3(pitch, yaw, 0f);
        }

        //drag camera around with Middle Mouse
        if (Input.GetMouseButton(2))
        {
            transform.Translate(-Input.GetAxisRaw("Mouse X") * Time.deltaTime * dragSpeed, -Input.GetAxisRaw("Mouse Y") * Time.deltaTime * dragSpeed, 0);
        }

        if (Input.GetMouseButton(1))
        {
            //Zoom in and out with Right Mouse
            transform.Translate(0, 0, Input.GetAxisRaw("Mouse X") * zoomSpeed * .07f, Space.Self);
        }

        //Zoom in and out with Mouse Wheel
        transform.Translate(0, 0, Input.GetAxis("Mouse ScrollWheel") * zoomSpeed, Space.Self);

        transform.Translate(Input.GetAxis("Horizontal") * wasdZoomSpeed, 0.0f, 0.0f, Space.Self);
        transform.Translate(0.0f, 0.0f, Input.GetAxis("Vertical") * wasdZoomSpeed, Space.Self);

        if (Input.GetKey(KeyCode.E))
        {
            transform.Translate(0.0f, wasdZoomSpeed, 0.0f, Space.Self);
        }

        if (Input.GetKey(KeyCode.Q))
        {
            transform.Translate(0.0f, -wasdZoomSpeed, 0.0f, Space.Self);
        }

    }
}
