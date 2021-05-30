// MIT License
// Copyright (c) 2021 Merlin

using UdonSharp;
using UnityEngine;

[DefaultExecutionOrder(-1000000000)]
public class GlobalProfileKickoff : UdonSharpBehaviour
{
    [System.NonSerialized]
    public System.Diagnostics.Stopwatch stopwatch;

    private void Start()
    {
        stopwatch = new System.Diagnostics.Stopwatch();
    }

    private void FixedUpdate()
    {
        stopwatch.Restart();
    }

    private void Update()
    {
        stopwatch.Restart();
    }

    private void LateUpdate()
    {
        stopwatch.Restart();
    }
}