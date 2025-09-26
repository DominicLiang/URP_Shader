using UnityEngine;

namespace WriteShader
{
  public class ComputeBufferCtrl : MonoBehaviour
  {
    struct BufferElement
    {
      public Vector3 f3;
      public float f;
    }

    private void Update()
    {
      // ! 创建computeBuffer 
      // 参数一: computeBuffer列表个数 看shader里面需要用index提取就知道
      // 参数二: 每个computeBuffer的字节数 sizeof可以拿到类型需要的字节数 用了float3加float 一共4个float 所以乘4
      var cb = new ComputeBuffer(1, sizeof(float) * 4);
      cb.SetData(new BufferElement[]
      {
      new()
      {
        f3 = Random.insideUnitSphere,
        f = 0.1f
      },
      });
      Shader.SetGlobalBuffer("_ComputeBuffer", cb);
    }
  }
}

