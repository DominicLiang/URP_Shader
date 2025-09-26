using Unity.Mathematics;
using UnityEngine;


public class LightDirectionTest : MonoBehaviour
{
  public float3 casterUpVector = new float3(0, 1, 0);
  private Light mainLight;
  private void Awake()
  {
    mainLight = GetComponent<Light>();
  }

  void Update()
  {
    GetLightDirection();
    Debug.Log(mainLight.transform.rotation);
  }

  [ExecuteAlways]
  void GetLightDirection()
  {
    float3 cameraPosition = Camera.main.transform.position;
    float3 cameraUp = Camera.main.transform.up;


    float3 viewForward = Camera.main.transform.forward;
    float3 lightFroward = mainLight.transform.forward;
    float3 forward = math.normalize(math.lerp(viewForward, lightFroward, 0.2f));

    float cosAngle = math.dot(forward, casterUpVector);
    float cosAngleClamped = math.clamp(cosAngle, -0.866f, 0f);
    forward = math.normalize(forward + (cosAngleClamped - cosAngle) * casterUpVector);

    mainLight.transform.rotation = quaternion.LookRotation(forward, cameraUp);

  }
}
