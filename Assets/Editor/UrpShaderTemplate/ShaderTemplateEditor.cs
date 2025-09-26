using System.IO;
using UnityEditor;

public class ShaderTemplateEditor : Editor
{
  private const string TemplateBasePath = "Assets/Editor/UrpShaderTemplate/Template";

  private static void CreateShaderTemplate(string templateName)
  {
    var path = AssetDatabase.GetAssetPath(Selection.activeObject);
    var templatePath = Path.Combine(TemplateBasePath, templateName);
    var newPath = Path.Combine(path, templateName);
    AssetDatabase.CopyAsset(templatePath, newPath);
    AssetDatabase.ImportAsset(newPath);
  }

  [MenuItem("Assets/Create/Shader/URP-无光照Shader")]
  private static void Unlit()
  {
    var templateName = "UnlitTemplate.shader";
    CreateShaderTemplate(templateName);
  }

  [MenuItem("Assets/Create/Shader/URP-PBRShader")]
  private static void PBR()
  {
    var templateName = "PBRTemplate.shader";
    CreateShaderTemplate(templateName);
  }

  [MenuItem("Assets/Create/Shader/URP-全屏后处理Shader")]
  private static void FullScreen()
  {
    var templateName = "FullScreenTemplate.shader";
    CreateShaderTemplate(templateName);
  }
}
