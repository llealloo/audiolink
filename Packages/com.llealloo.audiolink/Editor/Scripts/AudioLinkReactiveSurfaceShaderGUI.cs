using UnityEditor;
using UnityEngine;

namespace AudioLink.Editor.Shaders
{
    public class AudioLinkReactiveSurfaceShaderGUI : ShaderGUI
    {
        private int _lastMode = -1;

        public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
        {
            Material mat = materialEditor.target as Material;
            Material[] materials = materialEditor.targets as Material[] ?? new Material[0];
            int currentMode = mat?.GetInt("_Surface") ?? -1;
            if (currentMode != _lastMode)
            {
                _lastMode = currentMode;
                ApplySurfaceSettings(mat, currentMode);
                foreach (Material material in materials)
                    ApplySurfaceSettings(material, currentMode);
            }

            base.OnGUI(materialEditor, properties);

            currentMode = mat?.GetInt("_Surface") ?? -1;
            if (currentMode != _lastMode)
            {
                _lastMode = currentMode;
                ApplySurfaceSettings(mat, currentMode);
                foreach (Material material in materials)
                    ApplySurfaceSettings(material, currentMode);
            }
        }

        private void ApplySurfaceSettings(Material material, int mode)
        {
            switch (mode)
            {
                case 0: SetupOpaque(material); break;
                case 1: SetupCutout(material); break;
                case 2: SetupTransparent(material); break;
            }
        }

        private void SetupOpaque(Material material)
        {
            Debug.Log("Setup Opaque");
            material.SetOverrideTag("RenderType", "Opaque");
            material.SetOverrideTag("IgnoreProjector", "False");
            material.renderQueue = (int)UnityEngine.Rendering.RenderQueue.Geometry;
            material.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.One);
            material.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.Zero);
            material.SetInt("_ZWrite", 1);
            material.SetInt("_CastShadows", 1);
        }

        private void SetupCutout(Material material)
        {
            Debug.Log("Setup Cutout");
            material.SetOverrideTag("RenderType", "TransparentCutout");
            material.SetOverrideTag("IgnoreProjector", "True");
            material.renderQueue = (int)UnityEngine.Rendering.RenderQueue.AlphaTest;
            material.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.One);
            material.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.Zero);
            material.SetInt("_ZWrite", 1);
            material.SetInt("_CastShadows", 1);
        }

        private void SetupTransparent(Material material)
        {
            Debug.Log("Setup Transparent");
            material.SetOverrideTag("RenderType", "Transparent");
            material.SetOverrideTag("IgnoreProjector", "True");
            material.renderQueue = (int)UnityEngine.Rendering.RenderQueue.Transparent;
            material.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.SrcAlpha);
            material.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.OneMinusSrcAlpha);
            material.SetInt("_ZWrite", 0);
            material.SetInt("_CastShadows", 0);
        }
    }
}
