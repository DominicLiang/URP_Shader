using UnityEngine;

namespace WriteShader
{
  [RequireComponent(typeof(MeshRenderer))]
  public class MatPropCtrl : MonoBehaviour
  {
    public bool switcher;
    public Color color;
    public bool isSharedMat = true;

    private void OnValidate()
    {
      if (!switcher) return;

      // var mr = GetComponent<MeshRenderer>();

      // ! material 在编辑模式下不能使用 用这个来改变材质的属性之对脚本所在物体游戏 对材质的修改是暂时的
      // var mat = mr.material;

      // ! sharedMaterial 在编辑模式下可用 用这个的话 会对所有使用这个材质的物体同时生效 这和在面板上面修改材质属性是一样的 对材质的修改是永久的
      // var sharedMat = mr.sharedMaterial;

      // var targetMat = isSharedMat ? sharedMat : mat;

      // targetMat.SetColor("_MainColor", color);

      // ! Shader.SetGlobalFloat("_SomeProp", 10);
      // ! 全局修改所有shader的属性 必须是shader本身属性块没有定义才能生效 等于往shader里强塞一个本身没有的属性 同样修改的永久的

      // ! 数组传入数值
      Shader.SetGlobalFloatArray("_FloatArray", new[] { color.r, color.g, color.b, color.a });
      Shader.SetGlobalVectorArray("_VectorArray", new[]{
      new Vector4(1,1,1,1),
      new Vector4(2,2,2,2),
    });

      // ! 2d贴图数组传参
      // ! 用c#传贴图数组 index同样要用c#传 而且shader内 这些变量都不能写在CBUFFER内
      // Shader.SetGlobalFloat("_TextureIndex", index);
      // texArray = CreateTextureArray();
      // if (texArray == null) Debug.Log("TextureArray Create Fail");
      // Shader.SetGlobalTexture("_MutTextures", texArray);
    }

    public Texture2D[] ordinaryTextures;
    public Texture2DArray texArray;
    [Range(0, 3)]
    public int index;

    // ! 代码生成贴图数组
    // ! 注意 ordinaryTextures 使用到的贴图必须在贴图面板的高级选项上面开启读写
    private Texture2DArray CreateTextureArray()
    {
      if (ordinaryTextures.Length <= 0) return null;

      var texture2DArray = new Texture2DArray(ordinaryTextures[0].width,
                                           ordinaryTextures[0].height,
                                           ordinaryTextures.Length,
                                           TextureFormat.RGBA32,
                                           true,
                                           false);

      texture2DArray.filterMode = FilterMode.Bilinear;
      texture2DArray.wrapMode = TextureWrapMode.Repeat;

      for (int i = 0; i < ordinaryTextures.Length; i++)
      {
        texture2DArray.SetPixels(ordinaryTextures[i].GetPixels(0),
                                 i,
                                 0);
      }

      texture2DArray.Apply();

      return texture2DArray;
    }
  }
}
