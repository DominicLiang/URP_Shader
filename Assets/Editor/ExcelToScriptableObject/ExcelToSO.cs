using System;
using System.Collections;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using OfficeOpenXml;
using UnityEditor;
using UnityEngine;


public struct EditorUIData
{
  public MonoScript script;
  public int gridId;
  public string fieldNameRow;
  public string dataStartRow;
  public int converterId;
  public string soNameField;
  public string soFileName;
}

public struct SheetConvertData
{
  public Type dataClassType;
  public Type collectionGenericType;
  public string collectionName;
  public int fieldNameRow;
  public int dataStartRow;
  public string soNameField;
  public string soFileName;
  public ValueConverter customConverter;
  public string saveFolder;
  public ExcelWorksheets sheets;
}

public class ExcelToSO : EditorWindow
{
  private Dictionary<string, EditorUIData> uiData = new();
  private Dictionary<string, SheetConvertData> sheetConvertData = new();

  private string pathExcel = string.Empty;
  private string saveFullFolder = string.Empty;
  private string saveFolder = string.Empty;
  private ExportOptions options = ExportOptions.RowToList;
  private ExcelPackage excelPackage;
  private bool isSerializable = false;
  private bool isScriptableObject = false;
  private bool isFieldNameRowIsNumber = false;
  private bool isDataStartRowIsNumber = false;
  private Type dataClassType = null;
  private Type collectionGenericType = null;
  private string collectionName = string.Empty;


  [MenuItem("自定义工具/Excel转换ScriptableObject")]
  public static void ShowWindows()
  {
    var window = GetWindow<ExcelToSO>("Excel转换ScriptableObject");
    window.minSize = new Vector2(1470, 500);
    window.Show();
  }

  private void OnGUI()
  {
    EditorGUILayout.Space(20);

    // 标题
    EditorGUILayout.BeginHorizontal();
    {
      GUILayout.Label("Excel转ScriptableObject", new GUIStyle(EditorStyles.whiteLargeLabel)
      {
        fontSize = 25,
        alignment = TextAnchor.MiddleCenter,
      }, GUILayout.ExpandWidth(true));
    }
    EditorGUILayout.EndHorizontal();

    EditorGUILayout.Space(20);

    EditorGUILayout.BeginVertical(new GUIStyle()
    {
      padding = new RectOffset(10, 10, 0, 0),
    });
    {
      EditorGUILayout.BeginHorizontal();
      {
        // excel文件选择
        GUILayout.Label("Excel文件路径: ", GUILayout.Width(80));
        pathExcel = GUILayout.TextField(pathExcel, GUILayout.ExpandWidth(true));
        if (GUILayout.Button("浏览选择", GUILayout.Width(100)))
        {
          pathExcel = EditorUtility.OpenFilePanel("Import Excel Data", "", "xlsx");
        }
      }
      EditorGUILayout.EndHorizontal();

      EditorGUILayout.Separator();

      // 提示
      if (!pathExcel.ToLower().EndsWith(".xlsx"))
      {
        EditorGUILayout.BeginHorizontal();
        {
          EditorGUILayout.HelpBox("注意: 必须使用xlsx格式!", MessageType.Warning, true);
        }
        EditorGUILayout.EndHorizontal();
      }
      else
      {
        excelPackage = new ExcelPackage(new FileInfo(pathExcel));
      }

      EditorGUILayout.Separator();

      // 选择so保存路径
      EditorGUILayout.BeginHorizontal();
      {
        GUILayout.Label("SO保存路径: ", GUILayout.Width(80));
        saveFolder = GUILayout.TextField(saveFolder, GUILayout.ExpandWidth(true));
        if (GUILayout.Button("浏览选择", GUILayout.Width(100)))
        {
          saveFullFolder = EditorUtility.OpenFolderPanel("", Application.dataPath, "folder");
          saveFolder = "Assets" + saveFullFolder.Split("Assets")[1];
        }
      }
      EditorGUILayout.EndHorizontal();

      GUILayout.Space(30);

      EditorGUILayout.Separator();

      // 选择转换类型
      EditorGUILayout.BeginHorizontal();
      {
        var rowToList = "将excel所有行都保存到单个so里的列表中去";
        var SoWithSoCollection = "将excel所有行都生成单独so,并将所以有小so赋在一个大so里面, 并加入大so的列表";
        var everyRowToSingleFile = "每一行excel都生成一个单独的so";
        var isRowToList = options == ExportOptions.RowToList;
        var isSoWithSoCollection = options == ExportOptions.SoWithSoCollection;
        var note = isRowToList ? rowToList : isSoWithSoCollection ? SoWithSoCollection : everyRowToSingleFile;
        EditorGUILayout.HelpBox(note, MessageType.Info, true);
      }
      EditorGUILayout.EndHorizontal();

      EditorGUILayout.BeginHorizontal();
      {
        GUILayout.Label("转换选项: ", GUILayout.Width(80));
        options = (ExportOptions)EditorGUILayout.EnumPopup(options);
      }
      EditorGUILayout.EndHorizontal();

      EditorGUILayout.Space(20);

      // 遍历excel所有表格, 列出所有选项
      if (excelPackage != null)
      {
        foreach (var sheet in excelPackage.Workbook.Worksheets)
        {
          if (!uiData.ContainsKey(sheet.Name))
          {
            uiData.Add(sheet.Name, new EditorUIData()
            {
              script = null,
              gridId = 0,
              converterId = -1,
              fieldNameRow = "1",
              dataStartRow = "2",
              soNameField = string.Empty,
              soFileName = string.Empty,
            });
          }

          EditorGUILayout.BeginHorizontal();
          {
            GUILayout.Label(sheet.Name, GUILayout.Width(80));
            GUILayout.Label("选择SO类: ", GUILayout.Width(60));

            if (uiData.TryGetValue(sheet.Name, out var data))
            {
              // 选择要转换成什么so
              data.script = (MonoScript)EditorGUILayout.ObjectField(data.script, typeof(MonoScript), true, GUILayout.Width(160));
              if (data.script)
              {
                dataClassType = data.script.GetClass();
                if (dataClassType != null && dataClassType.BaseType != typeof(ScriptableObject))
                {
                  EditorGUILayout.BeginHorizontal();
                  {
                    EditorGUILayout.HelpBox("注意: 这个脚本必须继承自ScriptableObject!", MessageType.Warning, true);
                  }
                  EditorGUILayout.EndHorizontal();
                }
                else
                {
                  if (dataClassType != null)
                  {
                    if (options == ExportOptions.RowToList || options == ExportOptions.SoWithSoCollection)
                    {
                      var members = dataClassType.GetFields().Where(x => x.FieldType.GetInterfaces().FirstOrDefault(y => y == typeof(ICollection)) != null);

                      if (members != null && members.Count() > 0)
                      {
                        // 如果有多个集合, 选择转换到哪个集合
                        var memberNames = members.Select(x => x.Name).ToArray();

                        GUILayout.Label("     选择转换到那个集合： ", GUILayout.Width(140));

                        data.gridId = EditorGUILayout.Popup(data.gridId, memberNames, GUILayout.Width(100));

                        collectionName = memberNames[data.gridId];

                        // 检查选择的集合是否合规
                        var type = dataClassType.GetField(collectionName).FieldType;
                        if (type.IsGenericType)
                        {
                          var args = type.GetGenericArguments();
                          collectionGenericType = args[args.Length - 1];

                          isScriptableObject = collectionGenericType.BaseType == typeof(ScriptableObject);
                         // isSerializable = collectionGenericType.GetAttribute(typeof(SerializableAttribute)) != null;
                        }
                      }
                    }

                    // 选择字段名所在行和数据起始行, 字段名所在行默认为1, 数据起始行默认为2
                    GUILayout.Label("     字段名所在行： ", GUILayout.Width(100));
                    data.fieldNameRow = GUILayout.TextField(data.fieldNameRow, GUILayout.Width(30));
                    GUILayout.Label("     数据起始行： ", GUILayout.Width(90));
                    data.dataStartRow = GUILayout.TextField(data.dataStartRow, GUILayout.Width(30));

                    isFieldNameRowIsNumber = int.TryParse(data.fieldNameRow, out var fieldNameRow);
                    isDataStartRowIsNumber = int.TryParse(data.dataStartRow, out var dataStartRow);

                    if (options == ExportOptions.EveryRowToSingleFile)
                    {
                      GUILayout.Label("     SO命名所使用的字段： ", GUILayout.Width(150));
                      data.soNameField = GUILayout.TextField(data.soNameField, GUILayout.Width(100));
                    }
                    else
                    {
                      GUILayout.Label("     SO文件名,没有默认用工作簿名： ", GUILayout.Width(200));
                      data.soFileName = GUILayout.TextField(data.soFileName, GUILayout.Width(100));
                    }

                    // 获取所有值转换器, 要自定义值转换器继承ValueConverter就ok
                    // 原本支持所有常见类型, 但是有特殊类型(比如自定义类或者Sprite,Vector3什么的)就要自定义
                    var allValueConverter = new List<Type>();
                    foreach (var assembly in AppDomain.CurrentDomain.GetAssemblies())
                    {
                      var types = assembly.GetTypes();
                      foreach (var typeInAssembly in types)
                      {
                        if (typeInAssembly.IsSubclassOf(typeof(ValueConverter)) && typeInAssembly.Name != "CommonConverter")
                        {
                          allValueConverter.Add(typeInAssembly);
                        }
                      }
                    }

                    var allValueConverterName = allValueConverter.Select(x => x.Name).ToArray();

                    // 选择要使用的自定义值转换器, 没有不用选
                    GUILayout.Label("     自定义值转换器(!!!没有不用选!!!)： ", GUILayout.Width(210));
                    data.converterId = EditorGUILayout.Popup(data.converterId, allValueConverterName, GUILayout.Width(100));

                    // 保存数据以便后面转换使用
                    if (!sheetConvertData.TryGetValue(sheet.Name, out var convertData))
                    {
                      sheetConvertData.Add(sheet.Name, new SheetConvertData());
                    }

                    convertData.saveFolder = saveFolder;
                    convertData.sheets = excelPackage.Workbook.Worksheets;
                    convertData.dataClassType = dataClassType;
                    convertData.collectionGenericType = collectionGenericType;
                    convertData.collectionName = collectionName;
                    convertData.soNameField = data.soNameField;
                    convertData.soFileName = data.soFileName;
                    convertData.fieldNameRow = fieldNameRow;
                    convertData.dataStartRow = dataStartRow;
                    if (data.converterId >= 0)
                    {
                      convertData.customConverter = Activator.CreateInstance(allValueConverter[data.converterId]) as ValueConverter;
                    }
                    sheetConvertData[sheet.Name] = convertData;
                  }
                }
              }
              uiData[sheet.Name] = data;
            }
          }
          EditorGUILayout.EndHorizontal();
        }

        // 提示

        if (dataClassType != null && options == ExportOptions.RowToList && !isSerializable)
        {
          EditorGUILayout.BeginHorizontal();
          {
            EditorGUILayout.HelpBox("注意: 集合里类必须有Serializable特性!", MessageType.Warning, true);
          }
          EditorGUILayout.EndHorizontal();
        }

        if (dataClassType != null && options == ExportOptions.SoWithSoCollection && !isScriptableObject)
        {
          EditorGUILayout.BeginHorizontal();
          {
            EditorGUILayout.HelpBox("注意: 集合里类必须同样是ScriptableObject!", MessageType.Warning, true);
          }
          EditorGUILayout.EndHorizontal();
        }

        if (dataClassType != null && !isFieldNameRowIsNumber)
        {
          EditorGUILayout.BeginHorizontal();
          {
            EditorGUILayout.HelpBox("注意: 请输入字段名所在的行号, 必须填数字!", MessageType.Error, true);
          }
          EditorGUILayout.EndHorizontal();
        }

        if (dataClassType != null && !isDataStartRowIsNumber)
        {
          EditorGUILayout.BeginHorizontal();
          {
            EditorGUILayout.HelpBox("注意: 请输入数据起始行的行号, 必须填数字!", MessageType.Error, true);
          }
          EditorGUILayout.EndHorizontal();
        }

        GUILayout.Space(30);

        // 开始转换按钮
        EditorGUILayout.BeginHorizontal(GUILayout.ExpandWidth(true));
        {
          GUILayout.Label(string.Empty, GUILayout.ExpandWidth(true));

          if (GUILayout.Button("开始转换", GUILayout.Width(100)))
          {
            if (!string.IsNullOrEmpty(pathExcel)
            && !string.IsNullOrEmpty(saveFolder)
            && sheetConvertData.Count > 0)
            {
              Execute();
            }
          }

          GUILayout.Label(string.Empty, GUILayout.ExpandWidth(true));
        }
        EditorGUILayout.EndHorizontal();
      }
    }
    EditorGUILayout.EndVertical();
  }

  private void Execute()
  {
    switch (options)
    {
      case ExportOptions.RowToList:
        new RowToList().Execute(sheetConvertData);
        break;
      case ExportOptions.SoWithSoCollection:
        new SoWithSoCollection().Execute(sheetConvertData);
        break;
      case ExportOptions.EveryRowToSingleFile:
        new EveryRowToSingleFile().Execute(sheetConvertData);
        break;
    }

    excelPackage.Dispose();
  }
}
