using UnityEditor;
using UnityEngine;

namespace ToonURP.Editor
{
    public static class MenuUtils
    {
        private static void PlacePrefabInHierarchy(GameObject prefab, MenuCommand parameter)
        {
            bool noInPlay = !Application.IsPlaying(UnityEditor.SceneManagement.StageUtility.GetCurrentStage());
            
            if (prefab != null)
            {
                GameObject go = noInPlay ? PrefabUtility.InstantiatePrefab(prefab) as GameObject : Object.Instantiate(prefab).gameObject;
                if(parameter.context is GameObject parent)
                {
                    GameObjectUtility.SetParentAndAlign(go, parent);
                }
                else
                {
                    UnityEditor.SceneManagement.StageUtility.PlaceGameObjectInCurrentStage(go);
                }

                Selection.activeObject = go;
            }
        }
        
        
        [MenuItem("GameObject/ToonURP/bg_cyclo", false, 112)]
        private static void PlaceBgCyclo(MenuCommand parameter)
        {
            GameObject prefab = AssetDatabase.LoadAssetAtPath<GameObject>("Packages/com.reubensun.toonurp/Samples/Prefabs/bg_cyclo.prefab");
            PlacePrefabInHierarchy(prefab, parameter);
        }
    }
}