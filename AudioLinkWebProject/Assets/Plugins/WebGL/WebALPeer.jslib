var AnalyzerLink = {
  SetupAnalyzerSpace: function () {
    if (typeof window["_WebALPeerAnalyzers"] == "undefined") {
      window["_WebALPeerAnalyzers"] = {};
    }
  },
  // Keeps looking until the clip is playing, or until a minute has passed.
  //
  // There is nothing to attach an analyzer to until the clip is actually
  // playing: Unity creates the buffer source when the sound starts, and the
  // clip is matched by its duration, so before that there is nothing in
  // WEBAudio.audioInstances to find. On the web that is never immediate. An
  // AudioContext stays suspended until the page has been clicked, which can be
  // a minute after the scene loads and is entirely up to whoever is reading the
  // page. One attempt a quarter of a second in linked nothing, gave up, and
  // left the scene with a flat spectrum for the rest of its life -- the only
  // thing that ever tried again was alt-tabbing away and back, which is what
  // Application.focusChanged is wired to on the C# side.
  LinkAnalyzer: function (ID, duration, bufferSize) {
    var tolerableLength = 0.075;
    var firstDelay = 250;
    var retryDelay = 500;
    var attempts = 120;

    var name = btoa(ID);

    var attempt = function (remaining) {
      // SetupAnalyzerSpace is called before this on the C# side, but a link
      // that arrives without it should not take the scene down with it.
      if (typeof window["_WebALPeerAnalyzers"] == "undefined") {
        window["_WebALPeerAnalyzers"] = {};
      }

      // Already linked: either this ID was linked earlier, or two attempts
      // were in flight at once and the other one got there first.
      if (
        window["_WebALPeerAnalyzers"][name] != null &&
        typeof window["_WebALPeerAnalyzers"][name] != "undefined"
      ) {
        return;
      }

      var splitter = null;
      var AnalyzerLeft = null;
      var AnalyzerRight = null;
      var source = null;

      try {
        var WAInstKeys =
          typeof WEBAudio != "undefined"
            ? Object.keys(WEBAudio.audioInstances)
            : [];

        for (var index = WAInstKeys.length - 1; index >= 0; index--) {
          var WAInst = WEBAudio.audioInstances[WAInstKeys[index]];

          if (WAInst != null) {
            var rootSource = WAInst.source;

            if (rootSource != null)
              if (rootSource.buffer != null)
                if (
                  Math.abs(rootSource.buffer.duration - duration) <
                  tolerableLength
                ) {
                  source = rootSource;
                  break;
                }
          }
        }

        if (source != null && typeof source.context != "undefined") {
          var AContext = source.context;

          splitter = AContext.createChannelSplitter(2);
          AnalyzerLeft = AContext.createAnalyser();
          AnalyzerRight = AContext.createAnalyser();

          AnalyzerLeft.fftSize = AnalyzerRight.fftSize = bufferSize * 2;
          AnalyzerLeft.smoothingTimeConstant =
            AnalyzerRight.smoothingTimeConstant = 0;

          source.connect(splitter);
          splitter.connect(AnalyzerLeft, 0, 0);
          splitter.connect(AnalyzerRight, 1, 0);

          window["_WebALPeerAnalyzers"][name] = {
            source: source,
            splitter: splitter,
            AnalyzerLeft: AnalyzerLeft,
            AnalyzerRight: AnalyzerRight,
          };

          return;
        }
      } catch (e) {
        if (source != null && splitter != null) source.disconnect(splitter);
        if (splitter != null && AnalyzerLeft != null)
          splitter.disconnect(AnalyzerLeft);
        if (splitter != null && AnalyzerRight != null)
          splitter.disconnect(AnalyzerRight);

        throw e;
      }

      // Nothing to link to yet. The clip has not started, or it is not this
      // one; either way, come back and look again.
      if (remaining > 0) {
        setTimeout(function () {
          attempt(remaining - 1);
        }, retryDelay);
      }
    };

    setTimeout(function () {
      attempt(attempts);
    }, firstDelay);
  },
  UnlinkAnalyzer: function (ID) {
    var name = btoa(ID);

    var Analyzers = window["_WebALPeerAnalyzers"][name];

    if (Analyzers != null && typeof Analyzers != "undefined") {
      try {
        Analyzers.splitter.disconnect(Analyzers.AnalyzerLeft);
        Analyzers.splitter.disconnect(Analyzers.AnalyzerRight);
        Analyzers.source.disconnect(Analyzers.splitter);
        delete window["_WebALPeerAnalyzers"][name];

        return 0;
      } catch (e) {
        delete window["_WebALPeerAnalyzers"][name];
      }
    }

    return 1;
  },
  FetchAnalyzerLeft: function (ID, bufferPtr, bufferSize) {
    var name = btoa(ID);

    if (
      window["_WebALPeerAnalyzers"][name] != null &&
      typeof window["_WebALPeerAnalyzers"][name] != "undefined"
    ) {
      try {
        var buffer = new Uint8Array(
          Module.HEAPU8.buffer,
          bufferPtr,
          Float32Array.BYTES_PER_ELEMENT * bufferSize
        );
        buffer = new Float32Array(buffer.buffer, buffer.byteOffset, bufferSize);

        var Analyzers = window["_WebALPeerAnalyzers"][name];

        Analyzers.AnalyzerLeft.getFloatTimeDomainData(buffer);
      } catch (e) {
        throw e;
      }

      return 3;
    } else return 1;
  },
  FetchAnalyzerRight: function (ID, bufferPtr, bufferSize) {
    var name = btoa(ID);

    if (
      window["_WebALPeerAnalyzers"][name] != null &&
      typeof window["_WebALPeerAnalyzers"][name] != "undefined"
    ) {
      try {
        var buffer = new Uint8Array(
          Module.HEAPU8.buffer,
          bufferPtr,
          Float32Array.BYTES_PER_ELEMENT * bufferSize
        );
        buffer = new Float32Array(buffer.buffer, buffer.byteOffset, bufferSize);

        var Analyzers = window["_WebALPeerAnalyzers"][name];

        Analyzers.AnalyzerRight.getFloatTimeDomainData(buffer);
      } catch (e) {
        throw e;
      }

      return 3;
    } else return 1;
  },
};

mergeInto(LibraryManager.library, AnalyzerLink);
