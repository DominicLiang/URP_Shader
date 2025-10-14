using System.Collections.Generic;
using System.Linq;
using UnityEditor;
using UnityEditor.UIElements;
using UnityEngine;
using UnityEngine.UIElements;

public class SceneObjectWindow : EditorWindow
{
  private ObjectField objectField;
  private Button createBtn;
  private Button refreshBtn;
  private TextField objName;
  private Vector3Field objPosition;
  private IntegerField intTemp;
  private List<GameObject> gameObjects;
  private ListView leftListView;

  [SerializeField]
  private VisualTreeAsset m_VisualTreeAsset = default;

  [MenuItem("自定义工具/SceneObjectWindow")]
  public static void ShowExample()
  {
    SceneObjectWindow wnd = GetWindow<SceneObjectWindow>();
    wnd.titleContent = new GUIContent("SceneObjectWindow");
  }

  public void CreateGUI()
  {
    // Each editor window contains a root VisualElement object
    var root = rootVisualElement;

    // Instantiate UXML
    var labelFromUXML = m_VisualTreeAsset.Instantiate();
    root.Add(labelFromUXML);

    var helpBox1 = new HelpBox("This is a HelpBox", HelpBoxMessageType.None);
    var helpBox2 = new HelpBox("This is a HelpBox", HelpBoxMessageType.Info);
    var helpBox3 = new HelpBox("This is a HelpBox", HelpBoxMessageType.Warning);
    var helpBox4 = new HelpBox("This is a HelpBox", HelpBoxMessageType.Error);

    var foldout = root.Q<VisualElement>("Right").Q<Foldout>();
    foldout.Add(helpBox1);
    foldout.Add(helpBox2);
    foldout.Add(helpBox3);
    foldout.Add(helpBox4);
    // foldout.style.backgroundColor = new Color(0.302f, 0.302f, 0.302f, 1.000f);

    objectField = root.Q<ObjectField>("ObjectField");
    objectField.objectType = typeof(GameObject);
    objectField.allowSceneObjects = false;

    objName = root.Q<TextField>("ObjName");
    objName.bindingPath = "m_Name";

    objPosition = root.Q<Vector3Field>("ObjPosition");
    objPosition.bindingPath = "m_LocalPosition";

    intTemp = root.Q<IntegerField>("IntTemp");
    intTemp.bindingPath = "temp";

    leftListView = root.Q<ListView>("Left");
    leftListView.itemsSource = gameObjects;
    leftListView.makeItem = () =>
    {
      var label = new Label();
      return label;
    };
    leftListView.bindItem = (item, index) =>
    {
      var label = item as Label;
      var go = gameObjects[index];
      label.text = $"{go.name}";
    };
    leftListView.selectionChanged += (objs) =>
    {
      var go = objs.FirstOrDefault() as GameObject;
      Selection.activeObject = go;
      // objName.value = go.name;
      // objPosition.value = go.transform.position;

      var soName = new SerializedObject(go);
      objName.Bind(soName);

      var soPosition = new SerializedObject(go.transform);
      objPosition.Bind(soPosition);

      if (!go.TryGetComponent<MyCube>(out var myCube)) return;
      var soTemp = new SerializedObject(myCube);
      intTemp.Bind(soTemp);
    };

    createBtn = root.Q<Button>("CreateBtn");
    createBtn.clicked += () =>
    {
      gameObjects ??= new List<GameObject>();
      var go = Instantiate(objectField.value as GameObject);
      go.transform.position = new Vector3(Random.Range(-100, 100) / 100f, 0, 0);
      gameObjects.Add(go);
      leftListView.RefreshItems();
    };

    refreshBtn = root.Q<Button>("RefreshBtn");
    refreshBtn.clicked += () =>
    {
      gameObjects.ForEach(go => DestroyImmediate(go));
      gameObjects.Clear();
      leftListView.RefreshItems();
    };

    var so2 = new SerializedObject(this);

    var p = root.Q<PropertyField>("P");
    p.BindProperty(so2.FindProperty("gradients"));
    gradients.Add(new Gradient());

  }

  public List<Gradient> gradients = new List<Gradient>();
}
