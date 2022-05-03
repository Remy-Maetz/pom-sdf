using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
using System.Linq;
using System;

public class HeightSDFTextureProcessor : AssetPostprocessor
{
    const string k_label = "HeightSDF";

    const float  k_scaler = 0.1f;

    void OnPostprocessTexture(Texture2D texture)
    {

        Debug.Log("Check " + texture.name);

        if (!texture.name.Contains(k_label))
            return;

        Debug.Log(texture.name + " has the tag, process it");

        var minSize = Mathf.Min(texture.width, texture.height);
        var wd = 1.0f / texture.width;
        var hd = 1.0f / texture.height;

        var c = texture.GetPixels(0);

        var maxSearchOffset = minSize * k_scaler;

        var currentDistance = (float)maxSearchOffset;
        var currentSearchOffset = 0;
        var i = 0;

        for (int x=0; x<texture.width; x++)
        {
            for (int y=0; y<texture.height; y++)
            {
                i = x + y * texture.width;

                currentDistance = (1.0f - c[i].r) * maxSearchOffset;
                
                currentSearchOffset = 1;
                while( currentSearchOffset <= maxSearchOffset && currentSearchOffset < currentDistance)
                {
                    currentDistance = MinDistanceArround(c, x, y, texture.height, texture.width, currentSearchOffset, maxSearchOffset, currentDistance);
                    currentSearchOffset++;
                }

                c[i].g = currentDistance / maxSearchOffset;
            }
        }

        texture.SetPixels(c);

        texture.Apply();
    }

    float MinDistanceArround( Color[] c, int x, int y, int width, int height, int distance, float maxDepthValue, float startDistance)
    {
        var o = startDistance;
        float v = 0f;

        int xv = 0;
        int yv = 0;

        Vector3 offset = Vector3.zero;

        for (int xo = -distance; xo <= distance; xo++)
        {
            offset.x = xo;
            offset.y = distance;
            offset.z = 0;

            if (offset.magnitude > (maxDepthValue * o)) continue;

            xv = (x + xo + width) % width;

            yv = (y - distance + height) % height;
            offset.z = (1.0f - c[xv + yv * width].r ) * maxDepthValue;
            o = Mathf.Min(offset.magnitude, o);

            yv = (y + distance + height) % height;
            offset.z = (1.0f - c[xv + yv * width].r) * maxDepthValue;
            o = Mathf.Min(offset.magnitude, o);
        }


        for (int yo = -distance+1; yo < distance; yo++)
        {
            offset.x = distance;
            offset.y = yo;
            offset.z = 0;

            if (offset.magnitude > (maxDepthValue * o)) continue;

            yv = (y + yo + height) % height;

            xv = (x - distance + width) % width;
            offset.z = (1.0f - c[xv + yv * width].r) * maxDepthValue;
            o = Mathf.Min(offset.magnitude, o);

            xv = (x + distance + width) % width;
            offset.z = (1.0f - c[xv + yv * width].r) * maxDepthValue;
            o = Mathf.Min(offset.magnitude, o);
        }

        return o;
    }
}

[CustomEditor(typeof(TextureImporter))]
public class HeightSDFTextureImporterAddition : Editor
{
    Editor defaultEditor;

    private void OnEnable()
    {
        defaultEditor = Editor.CreateEditor(targets, Type.GetType("UnityEditor.TextureImporterInspector, UnityEditor"));
    }

    private void OnDisable()
    {
        DestroyImmediate(defaultEditor);
    }

    public override void OnInspectorGUI()
    {
        serializedObject.Update();

        defaultEditor.OnInspectorGUI();

        EditorGUILayout.Toggle("Generate SDF from heightmap", false);

        serializedObject.ApplyModifiedProperties();
    }
}
