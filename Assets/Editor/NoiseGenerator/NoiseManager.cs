using System.IO;
using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;

namespace Noise
{
  public class NoiseManager
  {
    private static NoiseManager instance;
    public static NoiseManager Instance
    {
      get
      {
        instance ??= new NoiseManager();
        return instance;
      }
    }

    #region Shader变量
    public int mainTex = Shader.PropertyToID("_MainTex");
    public int brightness = Shader.PropertyToID("_Brightness");
    public int contrast = Shader.PropertyToID("_Contrast");
    public int outputR = Shader.PropertyToID("_OutputR");
    public int outputG = Shader.PropertyToID("_OutputG");
    public int outputB = Shader.PropertyToID("_OutputB");
    public int seed = Shader.PropertyToID("_Seed");
    public int baseNoiseType = Shader.PropertyToID("_BaseType");
    public int tiled = Shader.PropertyToID("_Tiled");
    public int resolution = Shader.PropertyToID("_Resolution");
    public int frequency = Shader.PropertyToID("_Frequency");
    public int octaves = Shader.PropertyToID("_Octaves");
    public int persistence = Shader.PropertyToID("_Persistence");
    public int lacunarity = Shader.PropertyToID("_Lacunarity");
    #endregion

    #region 材质
    private Material previewRMaterial;
    private Material previewGMaterial;
    private Material previewBMaterial;
    private Material previewOutputMaterial;
    private Material valueMaterial;
    private Material perlinMaterial;
    private Material cellularMaterial;
    private Material fbmMaterial;
    #endregion

    #region CRT
    public CustomRenderTexture noiseRT;
    public CustomRenderTexture previewRRT;
    public CustomRenderTexture previewGRT;
    public CustomRenderTexture previewBRT;
    public CustomRenderTexture previewOutputRT;
    #endregion

    public void InitMaterial()
    {
      previewRMaterial = new Material(Shader.Find("CustomRTNoise/Preview"));
      previewGMaterial = new Material(Shader.Find("CustomRTNoise/Preview"));
      previewBMaterial = new Material(Shader.Find("CustomRTNoise/Preview"));
      previewOutputMaterial = new Material(Shader.Find("CustomRTNoise/Preview"));
      valueMaterial = new Material(Shader.Find("CustomRTNoise/Value2D"));
      perlinMaterial = new Material(Shader.Find("CustomRTNoise/Perlin2D"));
      cellularMaterial = new Material(Shader.Find("CustomRTNoise/Cellular2D"));
      fbmMaterial = new Material(Shader.Find("CustomRTNoise/FBM2D"));
    }

    public void InitCRT(int outputSize, NoiseType type, NoiseData noiseData, PreviewData previewData)
    {
      noiseRT = CreateCRT("Noise", outputSize, outputSize, GetNoiseMaterial(type));
      previewRRT = CreateCRT("PreviewR", 100, 100, previewRMaterial);
      previewGRT = CreateCRT("PreviewG", 100, 100, previewGMaterial);
      previewBRT = CreateCRT("PreviewB", 100, 100, previewBMaterial);
      previewOutputRT = CreateCRT("PreviewOutput", outputSize, outputSize, previewOutputMaterial);

      previewRRT.material.SetTexture(mainTex, noiseRT);
      previewGRT.material.SetTexture(mainTex, noiseRT);
      previewBRT.material.SetTexture(mainTex, noiseRT);
      previewOutputRT.material.SetTexture(mainTex, noiseRT);

      UpdateNoiseCRT(noiseRT, noiseData);

      var outputRData = new PreviewData()
      {
        outputR = ColorChannel.R,
        outputG = ColorChannel.R,
        outputB = ColorChannel.R
      };

      var outputGData = new PreviewData()
      {
        outputR = ColorChannel.G,
        outputG = ColorChannel.G,
        outputB = ColorChannel.G
      };

      var outputBData = new PreviewData()
      {
        outputR = ColorChannel.B,
        outputG = ColorChannel.B,
        outputB = ColorChannel.B
      };

      UpdatePreviewCRT(previewRRT, outputRData);
      UpdatePreviewCRT(previewGRT, outputGData);
      UpdatePreviewCRT(previewBRT, outputBData);
      UpdatePreviewCRT(previewOutputRT, previewData);

      noiseRT.Update();
      previewRRT.Update();
      previewGRT.Update();
      previewBRT.Update();
      previewOutputRT.Update();
    }

    public Material GetNoiseMaterial(NoiseType type)
    {
      var material = type switch
      {
        NoiseType.Value => valueMaterial,
        NoiseType.Perlin => perlinMaterial,
        NoiseType.Cellular => cellularMaterial,
        NoiseType.FBM => fbmMaterial,
        _ => null
      };
      return material;
    }

    private CustomRenderTexture CreateCRT(string name, int width, int height, Material material)
    {
      var crt = new CustomRenderTexture(width, height, RenderTextureFormat.ARGB32);
      crt.dimension = TextureDimension.Tex2D;
      crt.name = name;
      crt.wrapMode = TextureWrapMode.Repeat;
      crt.filterMode = FilterMode.Bilinear;
      crt.useMipMap = false;

      crt.material = material;
      crt.initializationMode = CustomRenderTextureUpdateMode.OnDemand;
      crt.updateMode = CustomRenderTextureUpdateMode.Realtime;
      crt.doubleBuffered = true;

      crt.Create();
      crt.Initialize();

      return crt;
    }

    public void UpdatePreviewCRT(CustomRenderTexture crt, PreviewData data)
    {
      var mat = crt.material;
      mat.SetFloat(brightness, data.brightness);
      mat.SetFloat(contrast, data.contrast);
      mat.SetFloat(outputR, (int)data.outputR);
      mat.SetFloat(outputG, (int)data.outputG);
      mat.SetFloat(outputB, (int)data.outputB);
    }

    public void UpdateNoiseCRT(CustomRenderTexture crt, NoiseData data)
    {
      var mat = crt.material;
      mat.SetFloat(seed, data.seed);
      mat.SetFloat(baseNoiseType, (int)data.baseNoiseType);
      // mat.SetFloat(tiled, data.tiled ? 1 : 0);
      if (data.tiled)
      {
        mat.EnableKeyword("_TILED");
      }
      else
      {
        mat.DisableKeyword("_TILED");
      }
      mat.SetVector(resolution, data.resolution);
      mat.SetVector(frequency, data.frequency);
      mat.SetFloat(octaves, data.octaves);
      mat.SetFloat(persistence, data.persistence);
      mat.SetFloat(lacunarity, data.lacunarity);
    }

    public void UpdateNoiseType(NoiseType type)
    {
      var material = GetNoiseMaterial(type);
      noiseRT.material = material;
    }

    public void SaveTexture(int width, int height, string path, SaveFormat format)
    {
      RenderTexture.active = previewOutputRT;

      var texture = new Texture2D(width, height, TextureFormat.ARGB32, false);
      texture.ReadPixels(new Rect(0, 0, width, height), 0, 0);
      texture.Apply();

      RenderTexture.active = null;

      var bytes = format switch
      {
        SaveFormat.JPG => texture.EncodeToJPG(),
        SaveFormat.PNG => texture.EncodeToPNG(),
        SaveFormat.TGA => texture.EncodeToTGA(),
        _ => throw new System.NotImplementedException(),
      };

      File.WriteAllBytes(path, bytes);
      AssetDatabase.Refresh();
    }

    public void Release()
    {
      previewRRT.Release();
      previewGRT.Release();
      previewBRT.Release();
      previewOutputRT.Release();
      noiseRT.Release();
    }
  }
}
