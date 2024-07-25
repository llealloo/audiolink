var AnalyzerLink = {
  SetupAnalyzerSpace: function () {
    if (typeof window["_WebALPeerAnalyzers"] == "undefined") {
      window["_WebALPeerAnalyzers"] = {};
    }
  },
  LinkAnalyzer: function (ID, duration, bufferSize) {
    setTimeout(() => {
      var tolerableLength = 0.075;

      var name = btoa(ID);

      if (
        window["_WebALPeerAnalyzers"][name] == null ||
        typeof window["_WebALPeerAnalyzers"][name] == "undefined"
      ) {
        var splitter = null;
        var AnalyzerLeft = null;
        var AnalyzerRight = null;
        var source = null;

        try {
          var WAInstKeys = Object.keys(WEBAudio.audioInstances);
          if (typeof WEBAudio != "undefined" && WAInstKeys.length > 1) {
            for (var index = WAInstKeys.length - 1; index >= 0; i--) {
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
              AnalyzerLeft = AContext.createAnalyzer();
              AnalyzerRight = AContext.createAnalyzer();

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

              return 0;
            } else return 2;
          }
        } catch (e) {
          if (source != null && splitter != null) source.disconnect(splitter);
          if (splitter != null && AnalyzerLeft != null)
            splitter.disconnect(AnalyzerLeft);
          if (splitter != null && AnalyzerRight != null)
            splitter.disconnect(AnalyzerRight);

          throw e;
        }
      } else return 1;

      return 3;
    }, 250);
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
