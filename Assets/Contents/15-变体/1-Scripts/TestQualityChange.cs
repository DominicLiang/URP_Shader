using System;
using System.Collections.Generic;
using TMPro;
using UnityEngine;


public class TestQualityChange : MonoBehaviour
{
  public TMP_Dropdown dropdown;
  private List<string> options = new()
  {
    "Low",
    "Medium",
    "High",
    "Best",
  };

  private List<string> dataOptions = new()
  {
    "_QUALITY_LOW",
    "_QUALITY_MEDIUM",
    "_QUALITY_HIGH",
    "_QUALITY_BEST",
  };

  private void OnEnable()
  {
    dropdown.options.Clear();
    dropdown.AddOptions(options);
    dropdown.onValueChanged.AddListener(OnDropdownValueChange);
  }

  private void OnDropdownValueChange(int index)
  {
    for (int i = 0; i < dataOptions.Count; i++)
    {
      if (i != index)
      {
        Shader.DisableKeyword(dataOptions[i]);
      }
      else
      {
        Shader.EnableKeyword(dataOptions[i]);
      }
    }
  }

  private void OnDisable()
  {
    dropdown.options.Clear();
  }
}
