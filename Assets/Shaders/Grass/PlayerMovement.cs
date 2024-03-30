using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class PlayerMovement : MonoBehaviour
{
    public int GrassNum = 0;
    public float Speed = 5f;
    public GameObject GrassGo;
    
    // Start is called before the first frame update
    void Start()
    {
        for (var i = 0; i < GrassNum; ++i)
        {
            var grass = Instantiate(GrassGo);
            grass.transform.position = new Vector3(Random.Range(0, 100) / 10f, 0, Random.Range(0, 100) / 10f);
        }
    }

    // Update is called once per frame
    void Update()
    {
        Shader.SetGlobalVector("_PlayerPosition", transform.position);
        float horizontalInput = Input.GetAxis("Horizontal");
        float verticalInput = Input.GetAxis("Vertical");

        Vector3 movement = new Vector3(horizontalInput, 0f, verticalInput);
        MoveCharacter(movement);
    }

    void MoveCharacter(Vector3 direction)
    {
        if (direction.magnitude >= .1f)
        {
            transform.Translate(direction * Speed * Time.deltaTime, Space.World);
        }
    }
}
