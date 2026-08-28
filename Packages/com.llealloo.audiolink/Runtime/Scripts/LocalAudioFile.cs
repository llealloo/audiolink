#if UNITY_EDITOR && !COMPILER_UDONSHARP
using System;
using System.Collections.Generic;
using System.IO;
using System.Text;
using UnityEngine;

// Format tables and the ffmpeg conversion step behind EditorAudioPlayer's Local File source.
// Split out from EditorAudioPlayer.cs purely to keep that file to a readable size.

namespace AudioLink
{
    /// <summary>File extension bookkeeping for the Local File source of EditorAudioPlayer.</summary>
    public static class LocalAudioFile
    {
        /// <summary>Containers Unity's own decoders handle, so they can be loaded straight off disk.</summary>
        public static readonly string[] NativeExtensions =
        {
            ".wav", ".wave", ".mp3", ".ogg", ".oga", ".aif", ".aiff", ".aifc", ".mod", ".it", ".s3m", ".xm"
        };

        /// <summary>Everything else worth offering in the file dialog. These go through ffmpeg first.</summary>
        public static readonly string[] TranscodeExtensions =
        {
            ".flac", ".m4a", ".m4b", ".aac", ".alac", ".opus", ".wma", ".ape", ".wv", ".mka", ".mp4", ".m4v", ".mkv", ".webm", ".mov", ".avi", ".wmv", ".flv", ".ts", ".mpg", ".mpeg"
        };

        public static bool IsNativelySupported(string path)
        {
            return Array.IndexOf(NativeExtensions, ExtensionOf(path)) >= 0;
        }

        public static bool IsKnownExtension(string path)
        {
            string extension = ExtensionOf(path);
            return Array.IndexOf(NativeExtensions, extension) >= 0 || Array.IndexOf(TranscodeExtensions, extension) >= 0;
        }

        public static AudioType AudioTypeOf(string path)
        {
            switch (ExtensionOf(path))
            {
                case ".wav":
                case ".wave":
                    return AudioType.WAV;
                case ".mp3":
                    return AudioType.MPEG;
                case ".ogg":
                case ".oga":
                    return AudioType.OGGVORBIS;
                case ".aif":
                case ".aiff":
                case ".aifc":
                    return AudioType.AIFF;
                case ".mod":
                    return AudioType.MOD;
                case ".it":
                    return AudioType.IT;
                case ".s3m":
                    return AudioType.S3M;
                case ".xm":
                    return AudioType.XM;
                default:
                    return AudioType.UNKNOWN;
            }
        }

        /// <summary>Filter list for EditorUtility.OpenFilePanelWithFilters.</summary>
        public static string[] FilePanelFilters()
        {
            List<string> all = new List<string>();
            all.AddRange(StripDots(NativeExtensions));
            all.AddRange(StripDots(TranscodeExtensions));

            return new[]
            {
                "Audio & video files", string.Join(",", all),
                "Natively supported audio", string.Join(",", StripDots(NativeExtensions)),
                "All files", "*"
            };
        }

        /// <summary>Where the ffmpeg-converted copy of <paramref name="sourcePath"/> lives.</summary>
        public static string CachePath(string sourcePath)
        {
            string key = sourcePath;
            try
            {
                FileInfo info = new FileInfo(sourcePath);
                key += $"|{info.Length}|{info.LastWriteTimeUtc.Ticks}";
            }
            catch (Exception)
            {
                // A stat failure just means a less specific cache key; the transcode will fail loudly anyway.
            }

            string directory = Path.GetFullPath(Path.Combine("Temp", "AudioLink Audio Cache"));
            return Path.Combine(directory, Hash128.Compute(key) + ".wav");
        }

        private static string ExtensionOf(string path)
        {
            if (string.IsNullOrEmpty(path)) return "";

            return Path.GetExtension(path).ToLowerInvariant();
        }

        private static List<string> StripDots(string[] extensions)
        {
            List<string> stripped = new List<string>(extensions.Length);
            foreach (string extension in extensions)
            {
                stripped.Add(extension.TrimStart('.'));
            }

            return stripped;
        }
    }

    /// <summary>
    /// Converts formats Unity cannot decode into a plain 16-bit stereo WAV, reusing the ffmpeg
    /// installation that ytdlpPlayer already knows how to locate.
    /// </summary>
    public static class LocalAudioTranscoder
    {
        public static bool isAvailable => ytdlpURLResolver.IsFFmpegAvailable();

        public static LocalAudioTranscodeJob Start(string sourcePath)
        {
            LocalAudioTranscodeJob job = new LocalAudioTranscodeJob(LocalAudioFile.CachePath(sourcePath));

            if (!isAvailable)
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
                $"\"{job.outputPath}\""
            };

            job.Begin(ytdlpURLResolver.ResolvingProcess(ytdlpURLResolver.FFmpegPath, arguments));
            return job;
        }
    }

    /// <summary>A running (or finished) ffmpeg conversion. Poll it from the main thread.</summary>
    public class LocalAudioTranscodeJob
    {
        private readonly StringBuilder _standardError = new StringBuilder();
        private System.Diagnostics.Process _process;
        private volatile bool _exited;

        public string outputPath { get; private set; }
        public bool isDone { get; private set; }
        public bool succeeded { get; private set; }
        public string error { get; private set; }

        public LocalAudioTranscodeJob(string outputPath)
        {
            this.outputPath = outputPath;
            error = "";
        }

        internal void CompleteFromCache()
        {
            succeeded = true;
            isDone = true;
        }

        internal void CompleteWithError(string message)
        {
            error = message;
            succeeded = false;
            isDone = true;
        }

        internal void Begin(System.Diagnostics.Process process)
        {
            _process = process;
            _process.Exited += (sender, args) => _exited = true;
            _process.ErrorDataReceived += (sender, args) =>
            {
                if (string.IsNullOrEmpty(args.Data)) return;

                lock (_standardError) _standardError.AppendLine(args.Data);
            };
            // stdout is redirected by ResolvingProcess; drain it so a full pipe cannot stall ffmpeg.
            _process.OutputDataReceived += (sender, args) => { };

            try
            {
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
            if (isDone || _process == null || !_exited) return;

            // Flushes the async stderr reader so the error text below is complete.
            _process.WaitForExit();

            int exitCode = _process.ExitCode;
            lock (_standardError) error = _standardError.ToString().Trim();

            succeeded = exitCode == 0 && File.Exists(outputPath);
            if (!succeeded && string.IsNullOrEmpty(error))
            {
                error = $"ffmpeg exited with code {exitCode}.";
            }

            _process.Dispose();
            _process = null;
            isDone = true;
        }

        public void Cancel()
        {
            if (_process == null)
            {
                isDone = true;
                return;
            }

            try
            {
                if (!_process.HasExited)
                    _process.Kill();
            }
            catch (Exception)
            {
                // Already gone, or we never had the rights to signal it. Nothing useful to do.
            }

            try
            {
                _process.Dispose();
            }
            catch (Exception)
            {
                // Swallow
            }

            _process = null;
            isDone = true;
            succeeded = false;
        }
    }
}
#endif
