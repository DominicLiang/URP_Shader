using UnityEngine;
using UnityEditor;
using System.Collections.Generic;

[CustomEditor(typeof(ShadowCasterController))]
public class ShadowCasterControllerEditor : Editor
{
  private ShadowCasterController controller;

  // 只需要Renderer级别的折叠状态
  private Dictionary<int, bool> rendererFoldouts = new Dictionary<int, bool>();

  private void OnEnable()
  {
    controller = (ShadowCasterController)target;
  }
  public override void OnInspectorGUI()
  {
    // 绘制默认的Inspector内容
    DrawDefaultInspector();

    EditorGUILayout.Space(10);

    // 添加更新按钮
    if (GUILayout.Button("更新 Renderers"))
    {
      controller.UpdateRenderers();
    }

    EditorGUILayout.Space(10);

    // 标题
    EditorGUILayout.LabelField("Renderer列表", EditorStyles.boldLabel);

    // 获取当前的渲染器列表
    var renderers = controller.Renderers;

    if (renderers != null && renderers.Length > 0)
    {
      // 计数框
      EditorGUILayout.LabelField($"数量: {renderers.Length}", EditorStyles.helpBox);
      EditorGUILayout.Space(5);

      // 显示每个Renderer
      GUI.enabled = false;
      for (int i = 0; i < renderers.Length; i++)
      {
        var renderer = renderers[i];

        // 为每个Renderer创建一个背景框
        EditorGUILayout.BeginVertical("box");

        EditorGUILayout.ObjectField($"Renderer {i}", renderer, typeof(Renderer), true);

        if (renderer != null)
        {
          // 初始化折叠状态 - 默认折叠
          if (!rendererFoldouts.ContainsKey(i))
            rendererFoldouts[i] = false;

          // 为折叠组添加缩进
          EditorGUI.indentLevel++;

          // 创建折叠组 - SubMesh信息
          rendererFoldouts[i] = EditorGUILayout.Foldout(
              rendererFoldouts[i],
              $"SubMesh信息 ({renderer.sharedMaterials?.Length ?? 0})"
          );

          if (rendererFoldouts[i])
          {
            EditorGUI.indentLevel++;

            var materials = renderer.sharedMaterials;
            if (materials != null && materials.Length > 0)
            {
              for (int j = 0; j < materials.Length; j++)
              {
                var material = materials[j];

                // 为每个SubMesh创建背景
                EditorGUILayout.BeginVertical("box");

                // SubMesh标题
                string materialName = material != null ? material.name : "null";
                EditorGUILayout.LabelField($"SubMesh {j}: {materialName}", EditorStyles.boldLabel);

                EditorGUI.indentLevel++;

                // 材质
                EditorGUILayout.LabelField("材质:");
                EditorGUILayout.ObjectField("", material, typeof(Material), false);

                // Shader
                EditorGUILayout.LabelField("Shader:");
                if (material != null && material.shader != null)
                {
                  EditorGUILayout.ObjectField("", material.shader, typeof(Shader), false);
                }
                else
                {
                  EditorGUILayout.ObjectField("", null, typeof(Shader), false);
                }

                EditorGUI.indentLevel--;
                EditorGUILayout.EndVertical();
                EditorGUILayout.Space(2);
              }
            }
            else
            {
              EditorGUILayout.LabelField("无材质", EditorStyles.label);
            }

            EditorGUI.indentLevel--;
          }

          // 减少折叠组的缩进
          EditorGUI.indentLevel--;
        }

        EditorGUILayout.EndVertical();
        EditorGUILayout.Space(5);
      }
      GUI.enabled = true;
    }
    else
    {
      EditorGUILayout.LabelField("No Renderers Found", EditorStyles.helpBox);
    }
  }
}