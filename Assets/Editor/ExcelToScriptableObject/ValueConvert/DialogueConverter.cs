// using System;
// using System.Collections.Generic;
// using UnityEngine;

// /// <summary>
// /// 对话系统自定义值转换器
// /// </summary>
// public class DialogueConverter : ValueConverter
// {
//   public override object ToValue(Type type, string stringValue)
//   {
//     object obj = null;
//     var sValue = ClearEndEmpty(stringValue);


//     if (type.Equals(typeof(Actor)))
//     {
//       var actorValues = sValue.Split('|');
//       obj = new Actor
//       {
//         name = actorValues[0],
//         avatarAddress = actorValues[1]
//       };
//     }
//     else if (type.Equals(typeof(List<Content>)))
//     {
//       var contents = new List<Content>();
//       var contentValues = sValue.Split('*');
//       foreach (var contentValue in contentValues)
//       {
//         var values = contentValue.Split('|');
//         var content = new Content();
//         if (int.TryParse(values[0], out var intValue1))
//           content.nextId = intValue1;
//         else
//           Debug.LogError("无法转换nextId, nextId是必须的");
//         content.text = values[1];
//         if (int.TryParse(values[2], out var intValue2))
//           content.meta = intValue2;
//         contents.Add(content);
//       }
//       obj = contents;
//     }

//     return obj;
//   }
// }