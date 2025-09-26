using UnityEditor;
using UnityEditor.SceneManagement;

/// <summary>
/// 在编辑器中运行项目时自动保存场景
/// </summary>
[InitializeOnLoad]
public class AutoSave
{
  static AutoSave()
  {
    EditorApplication.playModeStateChanged += (state) =>
    {
      if (state != PlayModeStateChange.ExitingEditMode) return;
      EditorSceneManager.SaveOpenScenes();
      AssetDatabase.SaveAssets();
    };
  }
}
