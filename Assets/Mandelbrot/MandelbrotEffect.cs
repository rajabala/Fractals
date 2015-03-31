using UnityEngine;
using UnityEngine.UI;
using System.Collections;

public class MandelbrotEffect : MonoBehaviour {
    public Material fractal;
    public int iterations;
    public float zoomLevel;
    public float zoomSpeed;
    public float moveSpeed;
    public Text textZoomLevel;
    public Text textControls;
    
    private Vector2 center;
    private Vector2 viewSize;
    private int exponent;

    public bool autoplay;
    Vector2 startViewSize = new Vector2(3, 2);

	// Use this for initialization
	void Start () {
        // cartesian space c0.1oordinates of start screen
        Init();        
	}
	
	// Update is called once per frame
	void Update () {
        bool zoomed = false;

        if (Input.GetAxis("Mouse ScrollWheel") > 0 || Input.GetKey(KeyCode.Q))
        {
            zoomLevel += zoomSpeed;
            zoomed = true;
        }
        else if (Input.GetAxis("Mouse ScrollWheel") < 0 || Input.GetKey(KeyCode.E))
        {
            zoomLevel -= zoomSpeed;
            zoomed = true;
        }

        if (Input.GetKeyDown(KeyCode.R))
        {
            Init();
        }

        if (Input.GetKeyDown(KeyCode.H))
        {
            textControls.gameObject.SetActive(!textControls.gameObject.activeSelf);
        }

        // change view size depending on zoom level (smoothly)
        float zoomRatio = 1.0f / Mathf.Pow(2, zoomLevel);

        if (zoomed)
            viewSize = startViewSize * zoomRatio; // higher zoom = smaller view size

        center.x += Input.GetAxis("Horizontal") * moveSpeed * zoomRatio;
        center.y -= Input.GetAxis("Vertical") * moveSpeed * zoomRatio; // DX uses 0,0 in top left    

        textZoomLevel.text = "Zoomlevel: " + zoomLevel;
	}


    void OnRenderImage(RenderTexture src, RenderTexture dst)
    {
        fractal.SetFloat("_ZoomLevel", zoomLevel);
        fractal.SetInt("_NumIterations", iterations);
        fractal.SetInt("_Exponent", exponent);
        fractal.SetVector("_ScreenRes", new Vector2(Screen.width, Screen.height));        
        fractal.SetVector("_Center", center);
        fractal.SetVector("_ViewSize", viewSize);


        Graphics.Blit(src, dst, fractal);
    }


    void Init()
    {
        center = new Vector2(-0.5f, 0.0f);
        viewSize = startViewSize;
        autoplay = false;
        exponent = 1;
        zoomLevel = 0;
    }


    // GUI callbacks
    public void SetIterations(float n)
    {
        iterations = (int) n;
    }

    public void SetAutoplay(bool ap)
    {
        autoplay = ap;
    }

    public void SetExponent(float e)
    {
        exponent = (int) e - 1;
    }
    
}
