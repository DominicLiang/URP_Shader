using UnityEditor;
using UnityEditor.UIElements;
using UnityEngine;
using UnityEngine.UIElements;

namespace Ramp
{
  public class RampGeneratorEditor : EditorWindow
  {
    [SerializeField]
    private VisualTreeAsset m_VisualTreeAsset = default;

    [MenuItem("自定义工具/Ramp图生成器")]
    public static void ShowExample()
    {
      RampGeneratorEditor wnd = GetWindow<RampGeneratorEditor>();
      wnd.titleContent = new GUIContent("RampGeneratorEditor");
      wnd.maxSize = new Vector2(450, int.MaxValue);
      wnd.minSize = new Vector2(450, 500);
    }

    public RampDataSO rampData;

    private SerializedObject so;
    private SerializedObject rampDataSO;
    private RampManager rampManager;

    public void CreateGUI()
    {
      rampManager = new RampManager();

      rampData ??= CreateInstance<RampDataSO>();
      if (rampData.gradients.Count <= 0)
      {
        rampData.gradients.Add(new Gradient());
      }

      VisualElement root = rootVisualElement;

      VisualElement labelFromUXML = m_VisualTreeAsset.Instantiate();
      root.Add(labelFromUXML);

      so = new SerializedObject(this);
      rampDataSO = new SerializedObject(rampData);

      InitUI(root);
    }

    private void InitUI(VisualElement root)
    {
      var rampDataField = root.Q<ObjectField>("RampData");
      var previewMatField = root.Q<ObjectField>("PreviewMat");
      var previewPropField = root.Q<TextField>("PreviewProp");
      var gradientsField = root.Q<PropertyField>("Gradients");
      var sizeField = root.Q<IntegerField>("Size");
      var pathField = root.Q<Label>("Path");
      var changePathBtn = root.Q<Button>("ChangePath");
      var fileNameField = root.Q<TextField>("FileName");
      var saveBtn = root.Q<Button>("Save");

      rampDataField.Bind(so);
      previewMatField.Bind(rampDataSO);
      previewPropField.Bind(rampDataSO);
      gradientsField.Bind(rampDataSO);
      sizeField.Bind(rampDataSO);
      pathField.Bind(rampDataSO);
      fileNameField.Bind(rampDataSO);

      rampDataField.RegisterValueChangedCallback((e) =>
      {
        rampData = (RampDataSO)e.newValue;
        var newSO = new SerializedObject(rampData);
        previewMatField.Bind(newSO);
        previewPropField.Bind(newSO);
        gradientsField.Bind(newSO);
        sizeField.Bind(newSO);
        pathField.Bind(newSO);
        fileNameField.Bind(newSO);
      });

      changePathBtn.clicked += () =>
      {
        string path = EditorUtility.OpenFolderPanel("选择保存路径", rampData.outputPath, "");
        string subPath = path.Substring(Application.dataPath.Length - 6);
        rampData.outputPath = subPath;
      };

      saveBtn.clicked += () =>
      {
        var rampMap = rampManager.GenerateRamp(rampData);
        rampManager.SaveRampMapAndSO(rampMap, rampData);
      };
    }

    private void OnValidate()
    {
      if (rampData == null) return;
      rampManager?.PreviewRamp(rampData);
    }
  }
}