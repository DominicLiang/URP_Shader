using System.Collections;
using System.Collections.Generic;
using System.Reflection;
using System.Text;
using UnityEngine;

public abstract class ConvertType
{
  public abstract void Execute(Dictionary<string, SheetConvertData> sheetConvertData);

  // 判断两个object是否相等
  public bool ObjectEquals(object objOne, object objTwo)
  {
    if (objOne == null || objTwo == null) return false;

    var flag = BindingFlags.Public | BindingFlags.IgnoreCase | BindingFlags.Instance;

    var objOneFields = objOne.GetType().GetFields(flag);

    // 遍历object所有字段
    foreach (var objOneField in objOneFields)
    {
      var objOneValue = objOneField.GetValue(objOne);
      var objTwoField = objTwo.GetType().GetField(objOneField.Name, flag);
      if (objTwoField == null) return false;
      var objTwoValue = objTwoField.GetValue(objTwo);

      // 如果是值类型或者字符串直接判断equal
      if (objOneValue.GetType().IsValueType || objOneValue.GetType().Equals(typeof(string)))
      {
        if (!objOneValue.Equals(objTwoValue)) return false;
      }// 如果是列表, 遍历递归判断是否equal
      else if (typeof(IEnumerable).IsAssignableFrom(objOneValue.GetType()))
      {
        var objOneCollectionCount = (int)objOneValue.GetType().GetProperty("Count").GetValue(objOneValue);
        var objTwoCollectionCount = (int)objTwoValue.GetType().GetProperty("Count").GetValue(objTwoValue);
        if (objOneCollectionCount != objTwoCollectionCount) return false;

        var oneCollection = objOneValue as IEnumerable;
        var twoCollection = objTwoValue as IEnumerable;

        var enumeratorOne = oneCollection.GetEnumerator();
        var enumeratorTwo = twoCollection.GetEnumerator();

        while (enumeratorOne.MoveNext() && enumeratorTwo.MoveNext())
        {
          if (!ObjectEquals(enumeratorOne.Current, enumeratorTwo.Current)) return false;
        }
      }// 其他递归遍历是否equal
      else
      {
        if (!ObjectEquals(objOneValue, objTwoValue)) return false;
      }
    }

    return true;
  }

  // 判断比较两个列表
  public void CollectionComparer(IEnumerable oldCollection, IEnumerable newCollection)
  {
    var newAddId = new List<object>();
    var deleteId = new List<object>();
    var changedId = new List<object>();

    foreach (var oldItem in oldCollection)
    {
      var flag = BindingFlags.Public | BindingFlags.IgnoreCase | BindingFlags.Instance;
      var oldId = oldItem.GetType().GetField("id", flag).GetValue(oldItem);
      var oldIdMatchNewId = false;
      foreach (var newItem in newCollection)
      {
        var newId = newItem.GetType().GetField("id", flag).GetValue(newItem);
        if (oldId.Equals(newId))
        {
          oldIdMatchNewId = true;
          // 如果id相同, 判断内容是否相同, 内容不相同加入修改列表
          if (ObjectEquals(oldItem, newItem))
          {
            break;
          }
          else
          {
            changedId.Add(newId);
          }
        }
      }

      // 如果旧id找不到对应的新id, 加入删除列表
      if (!oldIdMatchNewId)
      {
        deleteId.Add(oldId);
      }
    }

    foreach (var newItem in newCollection)
    {
      var flag = BindingFlags.Public | BindingFlags.IgnoreCase | BindingFlags.Instance;
      var newId = newItem.GetType().GetField("id", flag).GetValue(newItem);
      var newIdMatchOldId = false;
      foreach (var oldItem in oldCollection)
      {
        var oldId = oldItem.GetType().GetField("id", flag).GetValue(oldItem);
        if (oldId.Equals(newId))
        {
          newIdMatchOldId = true;
        }
      }
      // 如果新id找不到对应的旧id, 加入新增列表
      if (!newIdMatchOldId)
      {
        newAddId.Add(newId);
      }
    }

    Display(newAddId, deleteId, changedId);
  }

  // 输出增删改
  private void Display(List<object> newAddId, List<object> deleteId, List<object> changedId)
  {
    var newAddSB = new StringBuilder();
    for (int i = 0; i < newAddId.Count; i++)
    {
      newAddSB.Append($"{newAddId[i]}, ");
    }
    var newAddIdString = newAddId.Count > 0 ? newAddSB.ToString().Remove(newAddSB.ToString().Length - 2) : string.Empty;

    var deleteSB = new StringBuilder();
    for (int i = 0; i < deleteId.Count; i++)
    {
      deleteSB.Append($"{deleteId[i]}, ");
    }
    var deleteIdString = deleteId.Count > 0 ? deleteSB.ToString().Remove(deleteSB.ToString().Length - 2) : string.Empty;

    var changedSB = new StringBuilder();
    for (int i = 0; i < changedId.Count; i++)
    {
      changedSB.Append($"{changedId[i]}, ");
    }
    var changedIdString = changedId.Count > 0 ? changedSB.ToString().Remove(changedSB.ToString().Length - 2) : string.Empty;

    if (newAddId.Count > 0)
    {
      Debug.Log($"共新增 {newAddId.Count} 条数据");
      Debug.Log($"新增数据id为: {newAddIdString}");
    }

    if (deleteId.Count > 0)
    {
      Debug.Log($"共删除 {deleteId.Count} 条数据");
      Debug.Log($"删除数据id为: {deleteIdString}");
    }

    if (changedId.Count > 0)
    {
      Debug.Log($"共更改 {changedId.Count} 条数据");
      Debug.Log($"更改数据id为: {changedIdString}");
    }
  }
}