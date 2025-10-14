using System.Collections.Generic;
using UnityEngine;

namespace Ramp
{
  [CreateAssetMenu(fileName = "RampData", menuName = "Ramp/RampData")]
  public class RampDataSO : ScriptableObject
  {
    public Material previewMaterial;
    public string previewPropertyName;
    public List<Gradient> gradients = new List<Gradient>();
    public int outputSize = 256;
    public string outputPath = "Assets/Ramp/";
    public string fileName = "Ramp";
  }
}


