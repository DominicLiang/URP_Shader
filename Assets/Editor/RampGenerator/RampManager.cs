using System.IO;
using UnityEditor;
using UnityEngine;

namespace Ramp
{
  public class RampManager
  {
    public Texture2D GenerateRamp(RampDataSO rampData)
    {
      var width = rampData.outputSize;
      var height = rampData.gradients.Count * 2;
      var rampMap = new Texture2D(width, height, TextureFormat.ARGB32, false);
      rampMap.filterMode = FilterMode.Bilinear;
      rampMap.wrapMode = TextureWrapMode.Clamp;

      var gradientHeight = 2;

      for (int i = 0; i < height; i++)
      {
        var invertHeight = height - 1 - i;
        var gradient = rampData.gradients[invertHeight / gradientHeight];
        for (int j = 0; j < width; j++)
        {
          var color = gradient.Evaluate((float)j / width);
          rampMap.SetPixel(j, i, color);
        }
      }

      rampMap.Apply();
      return rampMap;
    }

    public void PreviewRamp(RampDataSO rampData)
    {
      if (rampData.previewMaterial == null) return;
      if (rampData.previewMaterial.HasProperty(rampData.previewPropertyName) == false)
      {
        Debug.LogWarning($"没有在预览材质找到预览属性: {rampData.previewPropertyName}");
        return;
      }
      var rampMap = GenerateRamp(rampData);
      var previewMat = rampData.previewMaterial;
      previewMat.SetTexture(rampData.previewPropertyName, rampMap);
    }

    public void SaveRampMapAndSO(Texture2D rampMap, RampDataSO rampData)
    {
      if (Directory.Exists(rampData.outputPath) == false)
      {
        Directory.CreateDirectory(rampData.outputPath);
      }

      var path = Path.Combine(rampData.outputPath, rampData.fileName);

      var bytes = rampMap.EncodeToPNG();
      File.WriteAllBytes(path + ".png", bytes);

      AssetDatabase.CreateAsset(rampData, path + ".asset");

      AssetDatabase.Refresh();
    }
  }
}
