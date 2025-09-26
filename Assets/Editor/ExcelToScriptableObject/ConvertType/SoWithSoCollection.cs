using System;
using System.Collections;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using UnityEditor;
using UnityEngine;

/// <summary>
/// 将excel所有行都生成单独so,并将所以有小so赋在一个大so里面, 并加入大so的列表
/// </summary>
public class SoWithSoCollection : ConvertType
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

      // 创建so实例
      var asset = ScriptableObject.CreateInstance(dataClassType);

      var collectionFieldInfo = dataClassType.GetField(collectionName);
      var genericArgs = collectionFieldInfo.FieldType.GetGenericArguments();

      // 反射创建列表
      var newList = Activator.CreateInstance(typeof(List<>).MakeGenericType(genericArgs));
      // 将创建出来的列表赋值到so上面
      collectionFieldInfo.SetValue(asset, newList);
      // 获得add方法
      var addMethod = newList.GetType().GetMethod("Add");

      var fileName = string.IsNullOrEmpty(soFileName) ? sheet.Name : soFileName;
      var saveAssetPath = Path.Combine(saveFolder, fileName + ".asset");

      var oldSO = AssetDatabase.LoadAssetAtPath<ScriptableObject>(saveAssetPath);

      // 保存大so
      AssetDatabase.ImportAsset(saveAssetPath);
      AssetDatabase.Refresh();

      // 遍历excel取值
      for (int i = dataStartRow; i <= sheet.Dimension.Rows; i++)
      {
        var firstColumnValue = sheet.Cells[i, 1].Value;
        if (firstColumnValue == null || string.IsNullOrEmpty(firstColumnValue.ToString())) continue;

        // 创建小so
        var instance = ScriptableObject.CreateInstance(collectionGenericType);

        for (int j = 1; j <= sheet.Dimension.Columns; j++)
        {
          var fieldNameValue = sheet.Cells[fieldNameRow, j].Value;
          if (fieldNameValue == null || string.IsNullOrEmpty(fieldNameValue.ToString())) continue;
          var fieldInfo = collectionGenericType.GetField(fieldNameValue.ToString());
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
          fieldInfo.SetValue(instance, value);
        }

        var newSO = asset;

        // 将小so赋在一个大so里面
        AssetDatabase.AddObjectToAsset(instance, asset);
        AssetDatabase.SaveAssets();
        AssetDatabase.Refresh();

        // 将数据类加入so的列表里
        addMethod?.Invoke(newList, new[] { instance });

        // 显示增删改
        var oldCollection = oldSO.GetType().GetField(collectionName).GetValue(oldSO) as IEnumerable;
        var newCollection = newSO.GetType().GetField(collectionName).GetValue(newSO) as IEnumerable;
        CollectionComparer(oldCollection, newCollection);
      }
    }
  }
}