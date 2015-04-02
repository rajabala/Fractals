using UnityEngine;
using UnityEngine.UI;
using System.Collections;

public class MandelbulbEffect : MonoBehaviour {
    public Material fractal;
    public Light dirLight;
    public int iterations;
    public int rayMarchSteps;
    public int exponent;

    public float zoomSpeed;
    public float moveSpeed;
    public float rotateSpeed;
    public Text textZoomLevel;
    
    private Camera c;

    public bool autoplay;
    Vector2 startViewSize = new Vector2(3, 2);

	// Use this for initialization
	void Start () {
        // cartesian space c0.1oordinates of start screen
        Init();        
	}
	
	// Update is called once per frame
	void Update () {
        if (autoplay)
        {
            // rotate the camera about the origin (with the camera looking at it)
            c.transform.RotateAround(Vector3.zero, Vector3.up, Time.deltaTime * rotateSpeed);
        }

        if (Input.GetAxis("Mouse ScrollWheel") > 0 || Input.GetKey(KeyCode.Q))
        {
            c.fieldOfView -= Time.deltaTime * zoomSpeed;
            //c.transform.position += c.transform.forward * zoomSpeed * Time.deltaTime;
        }
        else if (Input.GetAxis("Mouse ScrollWheel") < 0 || Input.GetKey(KeyCode.E))
        {
            // zoomout
            c.fieldOfView += Time.deltaTime * zoomSpeed;
            //c.transform.position -= c.transform.forward * zoomSpeed * Time.deltaTime;
        }

        if (Input.GetKeyDown(KeyCode.R))
        {
            autoplay = !autoplay;
        }

        c.transform.position += c.transform.right * Input.GetAxis("Horizontal") * moveSpeed;
        c.transform.position += c.transform.up * Input.GetAxis("Vertical") * moveSpeed; // DX uses 0,0 in top left    
    
    }


    void OnRenderImage(RenderTexture src, RenderTexture dst)
    {
        fractal.SetInt("_Exponent", exponent);
        fractal.SetInt("_NumIterations", iterations);
        fractal.SetInt("_NumRayMarchSteps", rayMarchSteps);
        fractal.SetFloat("_Fov", Mathf.Deg2Rad * c.fieldOfView);
        fractal.SetVector("_LightDir", dirLight.transform.forward);

        // if you choose to pass the camera to world matrix, do NOT use camera.cameraToWorldMatrix
        // that one uses RHS (file:///C:/Program%20Files/Unity/Editor/Data/Documentation/en/ScriptReference/Camera-cameraToWorldMatrix.html)
        // Use camera.transform.localToWorldMatrix instead.		
        //fractal.SetMatrix("_CameraToWorldMatrix", c.transform.localToWorldMatrix);
        
        Graphics.Blit(src, dst, fractal);
    }


    void Init()
    {
        // set all public variables in the inspector (and in the UI elements)
        c = this.GetComponent<Camera>();
    }


    // GUI callbacks
    public void SetIterations(float n)
    {
        iterations = (int) n;
    }

    public void SetRayMarchSteps(float n)
    {
        rayMarchSteps = (int)n;
    }


    public void SetExponent(float e)
    {
        exponent = (int) e - 1;
    }
    
}
