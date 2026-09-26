#if UNITY_EDITOR && !COMPILER_UDONSHARP
using System;
using System.Collections.Generic;
using System.IO;
using System.Text;
using UnityEngine;

namespace AudioLink
{
    public partial class EditorAudioPlayer
    {
        private static readonly string[] NativeExtensions =
        {
            "wav", "wave", "mp3", "ogg", "oga", "aif", "aiff", "aifc"
        };

        private static readonly string[] TranscodeExtensions =
        {
            "flac", "m4a", "m4b", "aac", "alac", "opus", "wma", "ape", "wv", "mka",
            "mp4", "m4v", "mkv", "webm", "mov", "avi", "wmv", "flv", "ts", "mpg", "mpeg"
        };

        internal static bool IsNativelySupportedFile(string path)
        {
            return Array.IndexOf(NativeExtensions, ExtensionOf(path)) >= 0;
        }

        internal static bool IsKnownAudioFile(string path)
        {
            string extension = ExtensionOf(path);
            return Array.IndexOf(NativeExtensions, extension) >= 0 || Array.IndexOf(TranscodeExtensions, extension) >= 0;
        }

        internal static string[] FilePanelFilters()
        {
            List<string> all = new List<string>(NativeExtensions);
            all.AddRange(TranscodeExtensions);

            return new[]
            {
                "Audio & video files", string.Join(",", all),
                "All files", "*"
            };
        }

        private static AudioType AudioTypeOf(string path)
        {
            switch (ExtensionOf(path))
            {
                case "wav":
                case "wave":
                    return AudioType.WAV;
                case "mp3":
                    return AudioType.MPEG;
                case "ogg":
                case "oga":
                    return AudioType.OGGVORBIS;
                case "aif":
                case "aiff":
                case "aifc":
                    return AudioType.AIFF;
                default:
                    return AudioType.UNKNOWN;
            }
        }

        private static string ExtensionOf(string path)
        {
            return Path.GetExtension(path).TrimStart('.').ToLowerInvariant();
        }

        private static string TranscodeCachePath(string sourcePath)
        {
            // Size and timestamp are part of the key so that editing the source invalidates the cached conversion.
            FileInfo info = new FileInfo(sourcePath);
            string key = $"{sourcePath}|{info.Length}|{info.LastWriteTimeUtc.Ticks}";

            string directory = Path.GetFullPath(Path.Combine("Temp", "AudioLink Audio Cache"));
            return Path.Combine(directory, Hash128.Compute(key) + ".wav");
        }

        private static TranscodeJob StartTranscode(string sourcePath)
        {
            TranscodeJob job = new TranscodeJob(TranscodeCachePath(sourcePath));

            if (!EditorAudioURLResolver.IsFFmpegAvailable())
            {
                job.CompleteWithError("ffmpeg was not found.");
                return job;
            }

            if (File.Exists(job.outputPath))
            {
                job.CompleteFromCache();
                return job;
            }

            try
            {
                Directory.CreateDirectory(Path.GetDirectoryName(job.outputPath));
            }
            catch (Exception e)
            {
                job.CompleteWithError(e.Message);
                return job;
            }

            // ffmpeg writes to a scratch name and the finished file is moved into place, so a run
            // that is killed or fails can never leave a truncated file that later reads as a cache hit.
            string[] arguments =
            {
                "-hide_banner",
                "-nostats",
                "-loglevel error",
                "-y",
                "-i", $"\"{sourcePath}\"",
                "-vn", "-sn", "-dn",
                "-ac", "2",
                "-c:a", "pcm_s16le",
                "-f", "wav",
                $"\"{job.scratchPath}\""
            };

            job.Begin(EditorAudioURLResolver.ResolvingProcess(EditorAudioURLResolver.FFmpegPath, arguments));
            return job;
        }

        private class TranscodeJob
        {
            private readonly StringBuilder _standardError = new StringBuilder();
            private System.Diagnostics.Process _process;

            public string outputPath { get; }
            public string scratchPath { get; }
            public bool isDone { get; private set; }
            public bool succeeded { get; private set; }
            public string error { get; private set; }

            public TranscodeJob(string outputPath)
            {
                this.outputPath = outputPath;
                scratchPath = outputPath + ".part";
                error = "";
            }

            public void CompleteFromCache()
            {
                succeeded = true;
                isDone = true;
            }

            public void CompleteWithError(string message)
            {
                error = message;
                succeeded = false;
                isDone = true;
            }

            public void Begin(System.Diagnostics.Process process)
            {
                _process = process;
                _process.ErrorDataReceived += (sender, args) =>
                {
                    if (string.IsNullOrEmpty(args.Data))
                        return;

                    lock (_standardError)
                        _standardError.AppendLine(args.Data);
                };
                // stdout is redirected by ResolvingProcess; drain it so a full pipe cannot stall ffmpeg.
                _process.OutputDataReceived += (sender, args) => { };

                try
                {
                    DiscardScratchFile();
                    _process.Start();
                    _process.BeginErrorReadLine();
                    _process.BeginOutputReadLine();
                }
                catch (Exception e)
                {
                    _process.Dispose();
                    _process = null;
                    CompleteWithError(e.Message);
                }
            }

            public void Poll()
            {
                if (isDone || _process == null || !_process.HasExited)
                    return;

                // Flushes the async stderr reader so the error text below is complete.
                _process.WaitForExit();

                int exitCode = _process.ExitCode;
                lock (_standardError)
                    error = _standardError.ToString().Trim();

                _process.Dispose();
                _process = null;
                isDone = true;

                succeeded = exitCode == 0 && PublishScratchFile();
                if (!succeeded)
                {
                    DiscardScratchFile();
                    if (string.IsNullOrEmpty(error))
                    {
                        error = exitCode == 0
                            ? "ffmpeg reported success but produced no output file."
                            : $"ffmpeg exited with code {exitCode}.";
                    }
                }
            }

            public void Cancel()
            {
                isDone = true;
                succeeded = false;

                if (_process != null)
                {
                    try
                    {
                        if (!_process.HasExited)
                            _process.Kill();
                    }
                    catch (Exception)
                    {
                        // Already gone, or we never had the rights to signal it.
                    }

                    try
                    {
                        _process.Dispose();
                    }
                    catch (Exception)
                    {
                    }

                    _process = null;
                }

                DiscardScratchFile();
            }

            private bool PublishScratchFile()
            {
                try
                {
                    if (!File.Exists(scratchPath))
                        return false;

                    if (File.Exists(outputPath))
                        File.Delete(outputPath);

                    File.Move(scratchPath, outputPath);
                    return true;
                }
                catch (Exception e)
                {
                    error = string.IsNullOrEmpty(error) ? e.Message : $"{error}\n{e.Message}";
                    return false;
                }
            }

            private void DiscardScratchFile()
            {
                try
                {
                    if (File.Exists(scratchPath))
                        File.Delete(scratchPath);
                }
                catch (Exception)
                {
                    // A leftover .part is harmless; it is overwritten on the next attempt.
                }
            }
        }
    }
}
#endif
