using System.Collections.Generic;
using System.IO;
using System.Linq;
using NUnit.Framework;
using UnityEditor;
using UnityEngine;

/// <summary>
/// 每一行excel都生成一个单独的so
/// </summary>
public class EveryRowToSingleFile : ConvertType
{
  public override void Execute(Dictionary<string, SheetConvertData> sheetConvertData)
  {
    // 遍历所有工作簿
    foreach (var keyValuePair in sheetConvertData)
    {
      // 提取数据
      var sheet = keyValuePair.Value.sheets.FirstOrDefault(x => x.Name == keyValuePair.Key);
      var dataClassType = keyValuePair.Value.dataClassType;
      var collectionGenericType = keyValuePair.Value.collectionGenericType;
      var collectionName = keyValuePair.Value.collectionName;
      var fieldNameRow = keyValuePair.Value.fieldNameRow;
      var dataStartRow = keyValuePair.Value.dataStartRow;
      var customConverter = keyValuePair.Value.customConverter;
      var saveFolder = keyValuePair.Value.saveFolder;
      var soNameField = keyValuePair.Value.soNameField;
      var soFileName = keyValuePair.Value.soFileName;

      var oldCollection = new List<object>();
      var newCollection = new List<object>();

      var soName = string.Empty;

      for (int i = dataStartRow; i <= sheet.Dimension.Rows; i++)
      {
        var firstColumnValue = sheet.Cells[i, 1].Value;
        if (firstColumnValue == null || string.IsNullOrEmpty(firstColumnValue.ToString())) continue;

        // 创建so实例
        var asset = ScriptableObject.CreateInstance(dataClassType);

        // 遍历excel取值
        for (int j = 1; j <= sheet.Dimension.Columns; j++)
        {
          var fieldNameValue = sheet.Cells[fieldNameRow, j].Value;
          if (fieldNameValue == null || string.IsNullOrEmpty(fieldNameValue.ToString())) continue;
          var fieldInfo = dataClassType.GetField(fieldNameValue.ToString());
          if (fieldInfo == null) continue;

          // 先使用通用值转换器, 转换不了的话尝试使用选择的自定义值转换器来转换
          var commonConverter = new CommonConverter();
          var value = commonConverter.ToValue(fieldInfo.FieldType, sheet.Cells[i, j].Value.ToString());
          if (value == null)
          {
            if (customConverter == null)
            {
              Debug.LogWarning($"第 {i} 行, 第 {j} 列, 值为 {sheet.Cells[i, j].Value} 的数据类型为 {fieldInfo.FieldType} 的数据转换失败, 如果需要转换该数据请自制自定义数据转换器");
            }
            else
            {
              value = customConverter.ToValue(fieldInfo.FieldType, sheet.Cells[i, j].Value.ToString());
            }
          }
          if (value == null) continue;

          // 赋值
          fieldInfo.SetValue(asset, value);

          // 获得so文件名
          if (fieldInfo.Name != soNameField) continue;
          soName = sheet.Cells[i, j].Value.ToString();
        }

        if (string.IsNullOrEmpty(soName)) continue;
        var saveAssetPath = Path.Combine(saveFolder, soName + ".asset");

        oldCollection.Add(AssetDatabase.LoadAssetAtPath<ScriptableObject>(saveAssetPath));
        newCollection.Add(asset);

        // 保存so
        AssetDatabase.CreateAsset(asset, saveAssetPath);
        AssetDatabase.ImportAsset(saveAssetPath);
        AssetDatabase.Refresh();
      }

      // 显示增删改
      CollectionComparer(oldCollection, newCollection);
    }
  }
}