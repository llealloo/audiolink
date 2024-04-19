var AnalyserLink = {
    SetupAnalyserSpace: function () {

        if (typeof window["_WebALPeerAnalysers"] == "undefined") {

            window["_WebALPeerAnalysers"] = {};
        }

    },
    LinkAnalyser: function (ID, duration, bufferSize) {

        setTimeout(() => {

            var tolerableLength = .075;

            var name = btoa(ID);

            if (window["_WebALPeerAnalysers"][name] == null || typeof window["_WebALPeerAnalysers"][name] == "undefined") {

                var splitter = null;
                var analyserLeft = null;
                var analyserRight = null;
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
                                        if (Math.abs(rootSource.buffer.duration - duration) < tolerableLength) {
                                            source = rootSource;
                                            break;
                                        }

                            }

                        }

                        if (source != null && typeof source.context != "undefined") {

                            var AContext = source.context;

                            splitter = AContext.createChannelSplitter(2);
                            analyserLeft = AContext.createAnalyser();
                            analyserRight = AContext.createAnalyser();

                            analyserLeft.fftSize = analyserRight.fftSize = bufferSize * 2;
                            analyserLeft.smoothingTimeConstant = analyserRight.smoothingTimeConstant = 0;

                            source.connect(splitter);
                            splitter.connect(analyserLeft, 0, 0);
                            splitter.connect(analyserRight, 1, 0);

                            window["_WebALPeerAnalysers"][name] = {
                                source: source,
                                splitter: splitter,
                                analyserLeft: analyserLeft,
                                analyserRight: analyserRight
                            };

                            return 0;

                        } else return 2;

                    }

                } catch (e) {

                    if (source != null && splitter != null) source.disconnect(splitter);
                    if (splitter != null && analyserLeft != null) splitter.disconnect(analyserLeft);
                    if (splitter != null && analyserRight != null) splitter.disconnect(analyserRight);

                    throw e;
                }

            } else return 1;

            return 3;

        }, 250);

    },
    UnlinkAnalyser: function (ID) {

        var name = btoa(ID);

        var analysers = window["_WebALPeerAnalysers"][name];

        if (analysers != null && typeof analysers != "undefined") {

            try {

                analysers.splitter.disconnect(analysers.analyserLeft);
                analysers.splitter.disconnect(analysers.analyserRight);
                analysers.source.disconnect(analysers.splitter);
                delete window["_WebALPeerAnalysers"][name];
                
                return 0;

            } catch (e) {
                throw e;
            }

        }

        return 1;
    },
    FetchAnalyserLeft: function (ID, bufferPtr, bufferSize) {

        var name = btoa(ID);

        if (window["_WebALPeerAnalysers"][name] != null && typeof window["_WebALPeerAnalysers"][name] != "undefined") {

            try {

                var buffer = new Uint8Array(Module.HEAPU8.buffer, bufferPtr, Float32Array.BYTES_PER_ELEMENT * bufferSize);
                buffer = new Float32Array(buffer.buffer, buffer.byteOffset, bufferSize);

                var analysers = window["_WebALPeerAnalysers"][name];

                analysers.analyserLeft.getFloatTimeDomainData(buffer);

            } catch (e) {
                throw e;
            }

            return 3;

        } else return 1;

    },
    FetchAnalyserRight: function (ID, bufferPtr, bufferSize) {

        var name = btoa(ID);

        if (window["_WebALPeerAnalysers"][name] != null && typeof window["_WebALPeerAnalysers"][name] != "undefined") {

            try {

                var buffer = new Uint8Array(Module.HEAPU8.buffer, bufferPtr, Float32Array.BYTES_PER_ELEMENT * bufferSize);
                buffer = new Float32Array(buffer.buffer, buffer.byteOffset, bufferSize);

                var analysers = window["_WebALPeerAnalysers"][name];

                analysers.analyserRight.getFloatTimeDomainData(buffer);

            } catch (e) {
                throw e;
            }

            return 3;

        } else return 1;

    }
};

//autoAddDeps(AnalyserLink, "$analysers");
mergeInto(LibraryManager.library, AnalyserLink);