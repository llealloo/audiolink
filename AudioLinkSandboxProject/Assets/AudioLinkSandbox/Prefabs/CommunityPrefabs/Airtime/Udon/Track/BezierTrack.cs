
using System;
using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;

#if !COMPILER_UDONSHARP && UNITY_EDITOR
using UnityEditor;
using UdonSharpEditor;
#endif

namespace Airtime.Track
{
    // BezierTrack
    // credit: catlike coding for guide on bezier curves in Unity, which this class is built on
    [UdonBehaviourSyncMode(BehaviourSyncMode.None)]
    public class BezierTrack : UdonSharpBehaviour
    {
        public const int MODE_FREE = 0;
        public const int MODE_ALIGNED = 1;
        public const int MODE_MIRRORED = 2;

        [SerializeField]
        [HideInInspector]
        private Vector3[] points = new Vector3[]
        {
            new Vector3(1f, 0f, 0f),
            new Vector3(2f, 0f, 0f),
            new Vector3(3f, 0f, 0f),
            new Vector3(4f, 0f, 0f)
        };
        [SerializeField][HideInInspector] private int[] modes = new int[] { MODE_FREE, MODE_FREE };
        [SerializeField][HideInInspector] private bool loop = false;

#if !COMPILER_UDON // we don't need any of this in-game
        [SerializeField][HideInInspector] public float samplePointDistance = 0.35f;
        [SerializeField][HideInInspector] public float samplePointSize = 0.3f;
        [SerializeField][HideInInspector] public int samplePointLayer = 0;
        [SerializeField][HideInInspector] public bool samplePointStatic = false;
        [SerializeField][HideInInspector] public GameObject[] samplePoints;
#endif
        [SerializeField][HideInInspector] public float[] samplePointsT;

        [SerializeField][HideInInspector] public float cachedDistance = 0.0f;

        public void Reset()
        {
            points = new Vector3[]
            {
                new Vector3(1f, 0f, 0f),
                new Vector3(2f, 0f, 0f),
                new Vector3(3f, 0f, 0f),
                new Vector3(4f, 0f, 0f)
            };

            modes = new int[] { 0, 0 };
        }

        public void AddCurve()
        {
            Vector3 point = points[points.Length - 1];

            // resize array with Array.Copy -- seems like Array.Resize isn't supported in udon
            Vector3[] resized = new Vector3[points.Length + 3];
            Array.Copy(points, resized, points.Length);
            points = resized;

            point.x += 1f;
            points[points.Length - 3] = point;
            point.x += 1f;
            points[points.Length - 2] = point;
            point.x += 1f;
            points[points.Length - 1] = point;

            // resize array with Array.Copy -- seems like Array.Resize isn't supported in udon
            int[] resizedModes = new int[modes.Length + 1];
            Array.Copy(modes, resizedModes, modes.Length);
            modes = resizedModes;

            EnforceControlPointMode(points.Length - 4);

            // enforce loop
            if (loop)
            {
                EnforceControlPointLoop();
            }
        }

        public void AddCurveAt(int curve)
        {
            if (curve >= GetCurveCount())
            {
                AddCurve();
            }
            else if (curve < 0)
            {
                Debug.LogError("Tried to add a curve before 0");
            }
            else
            {
                int index = (curve * 3) + 1;

                // resize up to index then leave a gap
                Vector3[] resized = new Vector3[points.Length + 3];
                Array.Copy(points, resized, index);
                Array.Copy(points, index, resized, index + 3, points.Length - index);
                points = resized;

                points[index] = Vector3.Lerp(points[index - 1], points[index + 3], 0.25f);
                points[index + 1] = Vector3.Lerp(points[index - 1], points[index + 3], 0.5f);
                points[index + 2] = Vector3.Lerp(points[index - 1], points[index + 3], 0.75f);

                // resize modes
                int[] resizedModes = new int[modes.Length + 1];
                Array.Copy(modes, resizedModes, curve);
                Array.Copy(modes, curve, resizedModes, curve + 1, modes.Length - curve);
                modes = resizedModes;
            }
        }

        public void RemoveCurve()
        {
            if (GetCurveCount() > 1)
            {
                // resize array with Array.Copy -- seems like Array.Resize isn't supported in udon
                Vector3[] resized = new Vector3[points.Length - 3];
                Array.Copy(points, resized, resized.Length);
                points = resized;

                // resize array with Array.Copy -- seems like Array.Resize isn't supported in udon
                int[] resizedModes = new int[modes.Length - 1];
                Array.Copy(modes, resizedModes, resizedModes.Length);
                modes = resizedModes;

                EnforceControlPointMode(points.Length - 4);

                // enforce loop
                if (loop)
                {
                    EnforceControlPointLoop();
                }
            }
            else
            {
                Debug.LogWarning("Cannot remove first and only curve in a BezierTrack");
            }
        }

        public void RemoveCurveAt(int curve)
        {
            if (curve >= GetCurveCount())
            {
                RemoveCurve();
            }
            else if (curve < 0)
            {
                Debug.LogError("Tried to remove a curve before 0");
            }
            else
            {
                int index = Mathf.Max((curve * 3) - 1, 0);

                // manual resize
                Vector3[] resized = new Vector3[points.Length - 3];
                Array.Copy(points, resized, index);
                Array.Copy(points, index + 3, resized, index, points.Length - index - 3);
                points = resized;

                // resize modes
                int[] resizedModes = new int[modes.Length - 1];
                Array.Copy(modes, resizedModes, curve);
                Array.Copy(modes, curve + 1, resizedModes, curve, modes.Length - curve - 1);
                modes = resizedModes;

                // enforce loop
                if (loop)
                {
                    EnforceControlPointLoop();
                }
            }
        }

        public Vector3 GetPoint(float t)
        {
            int index = GetCurveIndex(t);
            return transform.TransformPoint(ComputePoint(points[index], points[index + 1], points[index + 2], points[index + 3], GetCurveValue(t)));
        }

        public Vector3 GetPointByDistance(float d)
        {
            if (cachedDistance <= 0.0f)
            {
                Debug.LogError(string.Format("BezierTrack {0} does not have a cached distance or BezierTrack is zero length", gameObject.name));
                return Vector3.zero;
            }
            else
            {
                return GetPoint(d / cachedDistance);
            }
        }

        public Vector3 GetVelocity(float t)
        {
            int index = GetCurveIndex(t);
            return transform.TransformPoint(ComputeTangent(points[index], points[index + 1], points[index + 2], points[index + 3], GetCurveValue(t))) - transform.position;
        }

        public Vector3 GetVelocityByDistance(float d)
        {
            if (cachedDistance <= 0.0f)
            {
                Debug.LogError(string.Format("BezierTrack {0} does not have a cached distance or BezierTrack is zero length", gameObject.name));
                return Vector3.zero;
            }
            else
            {
                return GetVelocity(d / cachedDistance);
            }
        }

        public float GetDistanceByTime(float t)
        {
            if (cachedDistance <= 0.0f)
            {
                Debug.LogError(string.Format("BezierTrack {0} does not have a cached distance or BezierTrack is zero length", gameObject.name));
                return 0.0f;
            }
            return t * cachedDistance;
        }

        public float GetTimeByDistance(float d)
        {
            if (cachedDistance <= 0.0f)
            {
                Debug.LogError(string.Format("BezierTrack {0} does not have a cached distance or BezierTrack is zero length", gameObject.name));
                return 0.0f;
            }
            else if (d <= 0.0f)
            {
                return 0.0f;
            }

            return d / cachedDistance;
        }

        public Quaternion GetOrientation(float t)
        {
            return Quaternion.LookRotation(GetVelocity(t));
        }

        public Quaternion GetOrientationByDistance(float d)
        {
            if (cachedDistance <= 0.0f)
            {
                Debug.LogError(string.Format("BezierTrack {0} does not have a cached distance or BezierTrack is zero length", gameObject.name));
                return Quaternion.identity;
            }
            else
            {
                return Quaternion.LookRotation(GetVelocityByDistance(d));
            }
        }

        public int GetControlPointCount()
        {
            return points.Length;
        }

        public Vector3 GetControlPoint(int index)
        {
            return points[index];
        }

        public void SetControlPoint(int index, Vector3 point)
        {
            // if we have a main control point selected move its handles as well
            if (index % 3 == 0)
            {
                Vector3 delta = point - points[index];
                if (loop && index == 0)
                {
                    points[points.Length - 2] += delta;
                }
                else if (index > 0)
                {
                    points[index - 1] += delta;
                }

                if (loop && index + 1 == points.Length)
                {
                    points[1] += delta;
                }
                else if (index + 1 < points.Length)
                {
                    points[index + 1] += delta;
                }
            }

            points[index] = point;

            // enforce a loop
            if (loop)
            {
                if (index <= 0)
                {
                    points[points.Length - 1] = points[0];
                }
                else if (index >= points.Length - 1)
                {
                    points[0] = points[points.Length - 1];
                }
            }

            EnforceControlPointMode(index);
        }

        public int GetControlPointMode(int index)
        {
            return modes[(index + 1) / 3];
        }

        public void SetControlPointMode(int index, int mode)
        {
            int modeIndex = (index + 1) / 3;
            modes[modeIndex] = mode;

            if (loop)
            {
                if (modeIndex <= 0)
                {
                    modes[modes.Length - 1] = mode;
                }
                else if (modeIndex >= modes.Length - 1)
                {
                    modes[0] = mode;
                }
            }

            EnforceControlPointMode(index);
        }

        private void EnforceControlPointMode(int index)
        {
            int modeIndex = (index + 1) / 3;

            if (modes[modeIndex] != MODE_FREE && (loop || (modeIndex > 0 && modeIndex < modes.Length - 1)))
            {
                int control = modeIndex * 3;
                int moved;
                int enforced;

                if (index <= control)
                {
                    moved = control - 1;
                    if (moved < 0)
                    {
                        moved = points.Length - 2;
                    }
                    enforced = control + 1;
                    if (enforced >= points.Length)
                    {
                        enforced = 1;
                    }
                }
                else
                {
                    moved = control + 1;
                    if (moved >= points.Length)
                    {
                        moved = 1;
                    }
                    enforced = control - 1;
                    if (enforced < 0)
                    {
                        enforced = points.Length - 2;
                    }
                }

                if (modes[modeIndex] == MODE_ALIGNED)
                {
                    points[enforced] = points[control] + (points[control] - points[moved]).normalized * Vector3.Distance(points[control], points[enforced]);
                }
                else if (modes[modeIndex] == MODE_MIRRORED)
                {
                    points[enforced] = points[control] + (points[control] - points[moved]);
                }
            }
        }

        private void EnforceControlPointLoop()
        {
            points[points.Length - 1] = points[0];
            modes[modes.Length - 1] = modes[0];
            EnforceControlPointMode(0);
        }

        public void SetIsLoop(bool value)
        {
            loop = value;

            // enforce loop
            if (loop)
            {
                EnforceControlPointLoop();
            }
        }

        public bool GetIsLoop()
        {
            return loop;
        }

#if !COMPILER_UDON
        public Transform GetSamplePoint(int index)
        {
            return samplePoints[index].transform;
        }
#endif

        public float GetSamplePointValue(int index)
        {
            return samplePointsT[index];
        }

        public float GetSamplePointDistance(int index)
        {
            return GetDistanceByTime(samplePointsT[index]);
        }

        public int GetCurveIndex(float t)
        {
            if (t >= 1.0f)
            {
                return points.Length - 4;
            }

            t = Mathf.Clamp01(t) * GetCurveCount();

            return Mathf.FloorToInt(t) * 3;
        }

        public float GetCurveValue(float t)
        {
            if (t >= 1.0f)
            {
                return 1.0f;
            }

            t = Mathf.Clamp01(t) * GetCurveCount();

            return t - Mathf.Floor(t);
        }

        public int GetCurveCount()
        {
            return (points.Length - 1) / 3;
        }

        private Vector3 ComputePoint(Vector3 p0, Vector3 p1, Vector3 p2, Vector3 p3, float t)
        {
            t = Mathf.Clamp01(t);
            float t1 = 1f - t;
            return t1 * t1 * t1 * p0 +
                   3f * t1 * t1 * t * p1 +
                   3f * t1 * t * t * p2 +
                   t * t * t * p3;
        }

        private Vector3 ComputeTangent(Vector3 p0, Vector3 p1, Vector3 p2, Vector3 p3, float t)
        {
            t = Mathf.Clamp01(t);
            float t1 = 1f - t;
            return 3f * t1 * t1 * (p1 - p0) +
                   6f * t1 * t * (p2 - p1) +
                   3f * t * t * (p3 - p2);
        }
    }

#if !COMPILER_UDONSHARP && UNITY_EDITOR
    public enum BezierMode
    {
        Free,
        Aligned,
        Mirrored
    }

    [CustomEditor(typeof(BezierTrack))]
    public class BezierTrackEditor : Editor
    {
        private const int evenSampleCount = 2000;

        private const float controlPointSize = 0.08f;
        private const float handleSize = 0.06f;
        private const float selectionSize = 0.1f;

        private static int selected = -1;

        public override void OnInspectorGUI()
        {
            if (UdonSharpGUI.DrawDefaultUdonSharpBehaviourHeader(target)) return;

            BezierTrack track = target as BezierTrack;

            GUILayout.Label(string.Format("Track Setup (Number of Curves: {0})", track.GetControlPointCount() / 3), EditorStyles.boldLabel);

            // show selected point if a point is selected
            if (selected >= 0 && selected < track.GetControlPointCount())
            {
                // buttons to change selection
                GUILayout.BeginHorizontal();
                if (track.GetIsLoop() || selected > 0)
                {
                    if (GUILayout.Button("<- Select Previous"))
                    {
                        selected--;
                        if (selected < 0)
                        {
                            selected = track.GetControlPointCount() - (track.GetIsLoop() ? 2 : 1);
                        }
                    }
                }
                GUILayout.Label(string.Format("Selected Point: {0}", selected));
                if (track.GetIsLoop() || selected < track.GetControlPointCount() - 1)
                {
                    if (GUILayout.Button("Select Next ->"))
                    {
                        selected++;
                        if (selected >= track.GetControlPointCount() - 1)
                        {
                            selected = 0;
                        }
                    }
                }
                GUILayout.EndHorizontal();

                UdonSharpGUI.DrawUILine();

                EditorGUI.BeginChangeCheck();
                Vector3 newPoint = EditorGUILayout.Vector3Field("Position", track.GetControlPoint(selected));
                if (EditorGUI.EndChangeCheck())
                {
                    Undo.RecordObject(track, "Move Point");
                    track.SetControlPoint(selected, newPoint);
                    EditorUtility.SetDirty(track);
                }

                if (selected % 3 == 0)
                {
                    // enums in udon when
                    BezierMode mode = (BezierMode)track.GetControlPointMode(selected);
                    EditorGUI.BeginChangeCheck();
                    BezierMode newMode = (BezierMode)EditorGUILayout.EnumPopup("Mode", mode);
                    if (EditorGUI.EndChangeCheck())
                    {
                        Undo.RecordObject(track, "Change Point Mode");
                        track.SetControlPointMode(selected, (int)newMode);
                        EditorUtility.SetDirty(track);
                    }

                    UdonSharpGUI.DrawUILine();

                    // buttons to add curve at selected point
                    GUILayout.BeginHorizontal();
                    if (GUILayout.Button("Insert Curve Here"))
                    {
                        Undo.RecordObject(track, "Insert Curve");
                        track.AddCurveAt((selected + 1) / 3);
                        EditorUtility.SetDirty(track);
                    }
                    // button to remove selected curve
                    if (GUILayout.Button("Remove Selected Curve"))
                    {
                        Undo.RecordObject(track, "Remove Curve");
                        track.RemoveCurveAt((selected + 1) / 3);
                        EditorUtility.SetDirty(track);
                    }
                    GUILayout.EndHorizontal();
                }
            }

            UdonSharpGUI.DrawUILine();

            // set if track loops
            EditorGUI.BeginChangeCheck();
            bool newLoop = EditorGUILayout.Toggle("Loop", track.GetIsLoop());
            if (EditorGUI.EndChangeCheck())
            {
                Undo.RecordObject(track, "Set Loop");
                track.SetIsLoop(newLoop);
                EditorUtility.SetDirty(track);
            }

            GUILayout.BeginHorizontal();
            if (GUILayout.Button("Add Curve to End"))
            {
                Undo.RecordObject(track, "Add Curve");
                track.AddCurve();
                EditorUtility.SetDirty(track);
            }
            if (GUILayout.Button("Remove Curve from End"))
            {
                Undo.RecordObject(track, "Remove Curve");
                track.RemoveCurve();
                EditorUtility.SetDirty(track);
            }
            GUILayout.EndHorizontal();

            if (GUILayout.Button("Reset Track"))
            {
                Undo.RecordObject(track, "Reset Track");
                track.Reset();
                EditorUtility.SetDirty(track);

                // clear sample points that are no longer relevant
                if (track.samplePoints != null && track.samplePointsT != null)
                {
                    ClearSamplePoints(track);
                }
            }

            UdonSharpGUI.DrawUILine();

            GUILayout.Label("Track Preparation", EditorStyles.boldLabel);
            GUILayout.Label("(Required for BezierWalker or collision)", EditorStyles.boldLabel);
            if (track.samplePoints == null)
            {
                GUILayout.Label("Sample points not generated");
            }
            else
            {
                GUILayout.Label(string.Format("Generated Sample Points: {0}", track.samplePoints.Length));
            }

            GUILayout.Label(string.Format("Cached Approximate Distance: {0}", track.cachedDistance));

            EditorGUI.BeginChangeCheck();
            float newDistance = EditorGUILayout.FloatField("Distance Between Points", track.samplePointDistance);
            if (EditorGUI.EndChangeCheck())
            {
                Undo.RecordObject(track, "Change Sample Point Distance");
                track.samplePointDistance = newDistance;
                EditorUtility.SetDirty(track);
            }

            EditorGUI.BeginChangeCheck();
            float newSize = EditorGUILayout.FloatField("Sphere Collider Size", track.samplePointSize);
            if (EditorGUI.EndChangeCheck())
            {
                Undo.RecordObject(track, "Change Sample Point Size");
                track.samplePointSize = newSize;
                EditorUtility.SetDirty(track);
            }

            EditorGUI.BeginChangeCheck();
            int newLayer = EditorGUILayout.LayerField("Layer", track.samplePointLayer);
            if (EditorGUI.EndChangeCheck())
            {
                Undo.RecordObject(track, "Change Sample Point Layer");
                track.samplePointLayer = newLayer;
                EditorUtility.SetDirty(track);
            }

            EditorGUI.BeginChangeCheck();
            bool newStatic = EditorGUILayout.Toggle("Generate Static", track.samplePointStatic);
            if (EditorGUI.EndChangeCheck())
            {
                Undo.RecordObject(track, "Change Sample Points Static");
                track.samplePointStatic = newStatic;
                EditorUtility.SetDirty(track);
            }

            if (GUILayout.Button("1. Cache Distance"))
            {
                CacheApproximateDistance(track);
            }

            if (GUILayout.Button("2. Generate Sample Points"))
            {
                // clear sample points to be sure
                if (track.samplePoints != null && track.samplePointsT != null)
                {
                    ClearSamplePoints(track);
                }

                GenerateSamplePoints(track);
            }

            if (GUILayout.Button("Clear Sample Points"))
            {
                if (track.samplePoints == null || track.samplePointsT == null)
                {
                    Debug.LogWarning("There are no sample points.");
                }
                else
                {
                    ClearSamplePoints(track);
                }
            }
        }

        public void GenerateSamplePoints(BezierTrack track)
        {
            if (track.cachedDistance <= 0.0f)
            {
                Debug.LogWarning("BezierTrack has no cached distance or is 0 length, please cache distance first and/or edit curve");
            }
            else
            {
                Undo.RecordObject(track, "Generate Sample Points");

                int count = Mathf.RoundToInt(track.cachedDistance / track.samplePointDistance) + 1;
                track.samplePoints = new GameObject[count];
                track.samplePointsT = new float[count];

                float position = 0.0f;

                // sample points are gameobjects with a sphere collider so collisions can be detected along the spline
                for (int i = 0; i < count; i++)
                {
                    GameObject g = new GameObject(string.Format("{0}", i));

                    SphereCollider c = g.AddComponent(typeof(SphereCollider)) as SphereCollider;
                    c.radius = track.samplePointSize;
                    c.isTrigger = true;

                    g.transform.position = track.GetPointByDistance(position);
                    g.transform.rotation = track.GetOrientationByDistance(position);
                    g.layer = track.samplePointLayer;
                    if (track.samplePointStatic)
                    {
                        g.isStatic = true;
                    }

                    g.transform.SetParent(track.transform);
                    track.samplePoints[i] = g;
                    // store time value so a collision can also find the right point on the spline
                    track.samplePointsT[i] = Mathf.Clamp01(track.GetTimeByDistance(position));

                    float arcNextTrackPosition = position + track.samplePointDistance;
                    float multiplier = track.samplePointDistance / Vector3.Distance(track.GetPointByDistance(position), track.GetPointByDistance(arcNextTrackPosition));
                    position += track.samplePointDistance * multiplier;
                }

                EditorUtility.SetDirty(track);
            }
        }

        public void ClearSamplePoints(BezierTrack track)
        {
            Undo.RecordObject(track, "Clear Sample Points");

            for (int i = 0; i < track.samplePoints.Length; i++)
            {
                // delete all sample points
                if (track.samplePoints[i] != null)
                {
                    DestroyImmediate(track.samplePoints[i]);
                }
                else
                {
                    Debug.LogWarning(string.Format("Sample point {0} was manually deleted in editor. Do not do this.", i));
                }
            }

            track.samplePoints = null;
            track.samplePointsT = null;

            EditorUtility.SetDirty(track);
        }

        public void CacheApproximateDistance(BezierTrack track)
        {
            Undo.RecordObject(track, "Cache Approximate Distance");

            track.cachedDistance = 0.0f;

            // brute force sampling distances to calculate the length of the entire spline
            Vector3 position = track.GetPoint(0);
            for (int i = 1; i < evenSampleCount; i++)
            {
                float t = (float)i / (evenSampleCount - 1);
                Vector3 nextPosition = track.GetPoint(t);
                track.cachedDistance += Vector3.Distance(position, nextPosition);
                position = nextPosition;
            }

            EditorUtility.SetDirty(track);
        }

        public void OnSceneGUI()
        {
            BezierTrack track = target as BezierTrack;

            Quaternion orientation = Tools.pivotRotation == PivotRotation.Local ? track.transform.rotation : Quaternion.identity;

            Vector3 p0 = PointHandle(track, 0, track.transform, orientation, controlPointSize, Color.cyan);
            for (int i = 1; i < track.GetControlPointCount(); i += 3)
            {
                Vector3 p1 = PointHandle(track, i, track.transform, orientation, handleSize, Color.yellow);
                Vector3 p2 = PointHandle(track, i + 1, track.transform, orientation, handleSize, Color.yellow);
                Vector3 p3;
                // don't bother drawing a handle for point 3 if the track is a loop
                if (track.GetIsLoop() && i == track.GetControlPointCount() - 3)
                {
                    p3 = track.transform.TransformPoint(track.GetControlPoint(i + 2));
                }
                else
                {
                    p3 = PointHandle(track, i + 2, track.transform, orientation, controlPointSize, Color.white);
                }

                // draw bezier
                Handles.DrawBezier(p0, p3, p1, p2, Color.green, null, 2f);

                // draw handle lines
                Handles.color = Color.yellow;
                Handles.DrawLine(p0, p1);
                Handles.DrawLine(p2, p3);

                p0 = p3;
            }
        }

        public Vector3 PointHandle(BezierTrack track, int index, Transform t, Quaternion q, float size, Color color)
        {
            Vector3 point = t.TransformPoint(track.GetControlPoint(index));

            Handles.color = color;
            if (Handles.Button(point, q, size * HandleUtility.GetHandleSize(point), selectionSize * HandleUtility.GetHandleSize(point), Handles.DotHandleCap))
            {
                selected = index;
                Repaint();
            }

            if (selected == index)
            {
                PointPositionHandle(track, index, t, q);
            }

            return point;
        }

        public Vector3 PointPositionHandle(BezierTrack track, int index, Transform t, Quaternion q)
        {
            Vector3 point = t.TransformPoint(track.GetControlPoint(index));

            EditorGUI.BeginChangeCheck();
            point = Handles.PositionHandle(point, q);
            if (EditorGUI.EndChangeCheck())
            {
                Undo.RecordObject(track, "Move Point");
                EditorUtility.SetDirty(track);
                track.SetControlPoint(index, track.transform.InverseTransformPoint(point));
            }

            return point;
        }
    }
#endif
}
