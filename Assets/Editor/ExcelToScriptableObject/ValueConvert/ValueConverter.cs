using System;

/// <summary>
/// 要自定义值转换器继承这个
/// </summary>
public abstract class ValueConverter
{
  public abstract object ToValue(Type type, string stringValue);

  public string ClearEndEmpty(string s)
  {
    return s.TrimEnd(new char[] { ' ', '\r', '\n' });
  }
}