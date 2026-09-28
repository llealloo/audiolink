#if UNITY_WEBGL
namespace AudioLink
{
    public class WebALPeer
    {
        const int SAMPLES_COUNT = 4096;

        public float[] WaveformSamplesLeft, WaveformSamplesRight;

        public WebALPeer()
        {
            WaveformSamplesLeft = new float[SAMPLES_COUNT];
            WaveformSamplesRight = new float[SAMPLES_COUNT];
        }

    }
}
#endif
