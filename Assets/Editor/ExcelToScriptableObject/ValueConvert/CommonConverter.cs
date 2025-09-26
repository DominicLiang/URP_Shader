using System;

/// <summary>
/// 常见类型的值转换器
/// </summary>
public class CommonConverter : ValueConverter
{
  public override object ToValue(Type type, string stringValue)
  {
    object obj = null;
    var sValue = ClearEndEmpty(stringValue);

    if (typeof(string).Equals(type))
    {
      obj = sValue;
    }
    else if (typeof(bool).Equals(type))
    {
      if (bool.TryParse(sValue, out var boolRes))
        obj = boolRes;
    }
    else if (typeof(int).Equals(type))
    {
      if (int.TryParse(sValue, out var intRes))
        obj = intRes;
    }
    else if (typeof(float).Equals(type))
    {
      if (float.TryParse(sValue, out var floatRes))
        obj = floatRes;
    }
    else if (type.IsEnum)
    {
      if (Enum.TryParse(type, sValue, out var enumRes))
        obj = enumRes;
    }

    return obj;
  }
}
