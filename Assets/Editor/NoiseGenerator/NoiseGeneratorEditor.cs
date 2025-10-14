using UnityEditor;
using UnityEditor.UIElements;
using UnityEngine.UIElements;
using UnityEngine;
using System.IO;

namespace Noise
{
  public class NoiseGeneratorEditor : EditorWindow
  {

    #region 变量
    // 信息
    public int seed = 54321;
    public bool tiled = true;
    public Vector2 resolution = new Vector2(10, 10);

    // fbm信息
    public BaseNoiseType baseNoiseType = BaseNoiseType.Perlin;
    public Vector2 frequency = new Vector2(2, 2);
    public int octaves = 10;
    public float persistence = 0.5f;
    public float lacunarity = 2;

    // 输出信息
    public NoiseType noiseType = NoiseType.FBM;
    public float brightness = 0.5f;
    public float contrast = 0.5f;
    public int outputSize = 512;
    public SaveFormat saveFormat = SaveFormat.PNG;
    public ColorChannel outputR = ColorChannel.R;
    public ColorChannel outputG = ColorChannel.R;
    public ColorChannel outputB = ColorChannel.R;

    // 保存
    public string outputPath = "Assets/Textures";
    public string fileName = "Noise";
    #endregion

    [SerializeField]
    private VisualTreeAsset m_VisualTreeAsset = default;

    #region 控件
    // 预览
    private VisualElement previewR;
    private VisualElement previewG;
    private VisualElement previewB;
    private VisualElement previewOutput;

    // 信息
    private IntegerField seedField;
    private BaseBoolField tiledField;
    private Vector2Field resolutionField;

    // fbm信息
    private EnumField baseNoiseTypeField;
    private Vector2Field frequencyField;
    private IntegerField octavesField;
    private Slider persistenceField;
    private FloatField lacunarityField;

    // 输出信息
    private EnumField noiseTypeField;
    public FloatField brightnessField;
    public FloatField contrastField;
    private IntegerField outputSizeField;
    private EnumField saveFormatField;
    private EnumField outputRField;
    private EnumField outputGField;
    private EnumField outputBField;

    // 保存
    private Label outputPathField;
    private Button changePathBtn;
    private TextField fileNameField;
    private Button saveBtn;
    #endregion

    #region CRT
    private CustomRenderTexture noiseRT;
    private CustomRenderTexture previewRRT;
    private CustomRenderTexture previewGRT;
    private CustomRenderTexture previewBRT;
    private CustomRenderTexture previewOutputRT;
    #endregion

    [MenuItem("自定义工具/噪声图生成器")]
    public static void ShowWindow()
    {
      var wnd = GetWindow<NoiseGeneratorEditor>();
      wnd.titleContent = new GUIContent("噪声图生成器");
      wnd.maxSize = new Vector2(450, 700);
      wnd.minSize = new Vector2(450, 700);
    }

    public void CreateGUI()
    {
      VisualElement root = rootVisualElement;

      VisualElement labelFromUXML = m_VisualTreeAsset.Instantiate();
      root.Add(labelFromUXML);

      // 序列化对象
      var so = new SerializedObject(this);

      InitUI(root, so);
      InitFBM(root, so);
      InitPreview();

    }

    private void InitPreview()
    {
      var noiseData = new NoiseData
      {
        seed = seed,
        tiled = tiled,
        resolution = resolution,
        baseNoiseType = baseNoiseType,
        frequency = frequency,
        octaves = octaves,
        persistence = persistence,
        lacunarity = lacunarity,
      };
      var previewData = new PreviewData
      {
        outputR = outputR,
        outputG = outputG,
        outputB = outputB,
      };

      NoiseManager.Instance.InitMaterial();
      NoiseManager.Instance.InitCRT(outputSize,
                                    noiseType,
                                    noiseData,
                                    previewData);

      noiseRT = NoiseManager.Instance.noiseRT;
      previewRRT = NoiseManager.Instance.previewRRT;
      previewGRT = NoiseManager.Instance.previewGRT;
      previewBRT = NoiseManager.Instance.previewBRT;
      previewOutputRT = NoiseManager.Instance.previewOutputRT;

      previewR.style.backgroundImage = Background.FromRenderTexture(previewRRT);
      previewG.style.backgroundImage = Background.FromRenderTexture(previewGRT);
      previewB.style.backgroundImage = Background.FromRenderTexture(previewBRT);
      previewOutput.style.backgroundImage = Background.FromRenderTexture(previewOutputRT);
    }

    private void InitUI(VisualElement root, SerializedObject so)
    {
      // 预览
      previewR = root.Q<VisualElement>("R");
      previewG = root.Q<VisualElement>("G");
      previewB = root.Q<VisualElement>("B");
      previewOutput = root.Q<VisualElement>("Output");

      // 信息
      seedField = root.Q<IntegerField>("Seed");
      tiledField = root.Q<BaseBoolField>("Tiled");
      resolutionField = root.Q<Vector2Field>("Resolution");
      seedField.Bind(so);
      tiledField.Bind(so);
      resolutionField.Bind(so);

      seedField.style.marginTop = 10;

      // 输出信息
      noiseTypeField = root.Q<EnumField>("NoiseType");
      brightnessField = root.Q<FloatField>("Brightness");
      contrastField = root.Q<FloatField>("Contrast");
      outputSizeField = root.Q<IntegerField>("OutputSize");
      saveFormatField = root.Q<EnumField>("SaveFormat");
      outputRField = root.Q<EnumField>("OutputR");
      outputGField = root.Q<EnumField>("OutputG");
      outputBField = root.Q<EnumField>("OutputB");
      noiseTypeField.Bind(so);
      brightnessField.Bind(so);
      contrastField.Bind(so);
      outputSizeField.Bind(so);
      saveFormatField.Bind(so);
      outputRField.Bind(so);
      outputGField.Bind(so);
      outputBField.Bind(so);

      var fbm = root.Q<VisualElement>("FBM");
      noiseTypeField.RegisterValueChangedCallback((e) =>
      {
        fbm.style.display = (NoiseType)e.newValue == NoiseType.FBM ? DisplayStyle.Flex : DisplayStyle.None;
      });

      // 保存
      outputPathField = root.Q<Label>("Path");
      fileNameField = root.Q<TextField>("FileName");
      changePathBtn = root.Q<Button>("ChangePath");
      saveBtn = root.Q<Button>("Save");
      outputPathField.Bind(so);
      fileNameField.Bind(so);
      changePathBtn.clicked += () =>
      {
        outputPath = EditorUtility.OpenFolderPanel("选择保存路径", outputPath, "");
        outputPathField.text = outputPath;
      };
      saveBtn.clicked += () =>
      {
        var suffix = saveFormat switch
        {
          SaveFormat.PNG => ".png",
          SaveFormat.JPG => ".jpg",
          SaveFormat.TGA => ".tga",
          _ => throw new System.NotImplementedException(),
        };
        var path = Path.Combine(outputPath, fileName) + suffix;
        NoiseManager.Instance.SaveTexture(outputSize, outputSize, path, saveFormat);
      };
    }

    private void InitFBM(VisualElement root, SerializedObject so)
    {
      var fbm = root.Q<VisualElement>("FBM");
      fbm.style.display = noiseType == NoiseType.FBM ? DisplayStyle.Flex : DisplayStyle.None;

      baseNoiseTypeField = new EnumField("基础类型");
      frequencyField = new Vector2Field("频率");
      octavesField = new IntegerField("迭代次数");
      persistenceField = new Slider("分型强度", 0, 1);
      lacunarityField = new FloatField(" 间隔");

      baseNoiseTypeField.style.marginTop = 5;
      frequencyField.style.marginTop = 2;
      octavesField.style.marginTop = 2;
      persistenceField.style.marginTop = 2;
      lacunarityField.style.marginTop = 2;

      baseNoiseTypeField.bindingPath = "baseNoiseType";
      frequencyField.bindingPath = "frequency";
      octavesField.bindingPath = "octaves";
      persistenceField.bindingPath = "persistence";
      lacunarityField.bindingPath = "lacunarity";

      baseNoiseTypeField.Bind(so);
      frequencyField.Bind(so);
      octavesField.Bind(so);
      persistenceField.Bind(so);
      lacunarityField.Bind(so);

      fbm.Add(baseNoiseTypeField);
      fbm.Add(frequencyField);
      fbm.Add(octavesField);
      fbm.Add(persistenceField);
      fbm.Add(lacunarityField);
    }

    private void OnValidate()
    {
      var noiseData = new NoiseData
      {
        seed = seed,
        tiled = tiled,
        resolution = resolution,
        baseNoiseType = baseNoiseType,
        frequency = frequency,
        octaves = octaves,
        persistence = persistence,
        lacunarity = lacunarity,
      };
      var previewData = new PreviewData
      {
        brightness = brightness,
        contrast = contrast,
        outputR = outputR,
        outputG = outputG,
        outputB = outputB,
      };

      NoiseManager.Instance.UpdateNoiseType(noiseType);
      NoiseManager.Instance.UpdateNoiseCRT(noiseRT, noiseData);
      NoiseManager.Instance.UpdatePreviewCRT(previewOutputRT, previewData);

      noiseRT.Update();
      previewRRT.Update();
      previewGRT.Update();
      previewBRT.Update();
      previewOutputRT.Update();
    }

    void OnDestroy()
    {
      NoiseManager.Instance.Release();
    }
  }
}


