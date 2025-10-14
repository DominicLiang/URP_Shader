using System.IO;
using System.Text.RegularExpressions;
using UnityEditor;
using UnityEngine;

// Simple editor utility to help debug why Shader.passCount might be 1.
// Usage: select a Shader asset in Project view and run the menu: HSR/Debug/Inspect Selected Shader
public static class HSRShaderInspector
{
  [MenuItem("HSR/Debug/Inspect Selected Shader")]
  public static void InspectSelectedShader()
  {
    Shader s = Selection.activeObject as Shader;
    if (s == null)
    {
      Debug.LogWarning("Please select a Shader asset in the Project window before running this.");
      return;
    }

    string assetPath = AssetDatabase.GetAssetPath(s);
    Debug.Log($"Inspecting shader asset: {assetPath}");

    int filePassCount = -1;
    try
    {
      if (File.Exists(assetPath))
      {
        string text = File.ReadAllText(assetPath);
        // Count occurrences of 'Pass' followed by a '{' (simple heuristic)
        filePassCount = Regex.Matches(text, "\\bPass\\b\\s*\\{", RegexOptions.Multiline).Count;
      }
      else
      {
        Debug.Log("Shader asset is not a plain text .shader file (could be a compiled or built-in shader)");
      }
    }
    catch (System.Exception ex)
    {
      Debug.LogError("Failed to read shader file: " + ex.Message);
    }

    Debug.Log($"Shader.name: {s.name}\nshader.passCount (API): {s.passCount}\nisSupported: {s.isSupported}\nfile Pass occurrences (text): {filePassCount}");

    // Also list materials in the project that reference this shader (helpful to see if a material was re-assigned)
    string[] guids = AssetDatabase.FindAssets("t:Material");
    int found = 0;
    for (int i = 0; i < guids.Length; i++)
    {
      string matPath = AssetDatabase.GUIDToAssetPath(guids[i]);
      Material m = AssetDatabase.LoadAssetAtPath<Material>(matPath);
      if (m != null && m.shader == s)
      {
        Debug.Log($"Material using shader: {matPath}");
        found++;
        if (found > 20) break; // avoid spamming too many results
      }
    }
    if (found == 0) Debug.Log("No Materials in the project currently reference this shader asset.");
  }

  [MenuItem("HSR/Debug/Inspect Selected Shader (Detailed)")]
  public static void InspectSelectedShaderDetailed()
  {
    Shader s = Selection.activeObject as Shader;
    if (s == null)
    {
      Debug.LogWarning("Please select a Shader asset in the Project window before running this.");
      return;
    }

    Debug.Log($"Detailed inspect for shader: {s.name}");

    // Search all shader assets and print any whose .name matches
    string[] guids = AssetDatabase.FindAssets("t:Shader");
    int matches = 0;
    for (int i = 0; i < guids.Length; i++)
    {
      string path = AssetDatabase.GUIDToAssetPath(guids[i]);
      Shader candidate = AssetDatabase.LoadAssetAtPath<Shader>(path);
      if (candidate != null && candidate.name == s.name)
      {
        Debug.Log($"Found shader asset with same name: {path}");
        matches++;
      }
    }
    if (matches == 0)
    {
      Debug.Log("No shader asset file in the project has the exact same shader.name. The material might reference a compiled/built-in shader or a different asset.");
    }
  }
}
