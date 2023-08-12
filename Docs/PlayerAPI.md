# Using the Player API

- Import AudioLink `using AudioLink;`
- Disable Auto Set Media State toggle on the AudioLink behaviour
- Add AudioLink variable `public AudioLink.AudioLink audiolink;`
- Set Volume display `audiolink.SetMediaVolume(player.volume);`
- Set Time display `audiolink.SetMediaTime(player.time);`
- Set Playback display `audiolink.SetMediaPlaying(MediaPlaying.playing)`
- Set Loop display `audiolink.SetMediaLoop(MediaLoop.Loop)`

```
using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;
using AudioLink;

public class Player : UdonSharpBehaviour {

    //AudioLink's UdonBehavior
    public AudioLink.AudioLink audiolink;

    //Update Media Playing State
    public void UpdatePlaying() {

        /* Avalible playing states
        None    0   (0.0f)
        Playing 1   (1.0f)
        Paused  2   (2.0f)
        Stopped 3   (3.0f)
        Loading 4   (4.0f)
        Streaming 5 (5.0f)
        Error     6 (6.0f)
        */
        if (VRC.SDKBase.Utilities.IsValid(audiolink)) {
            audiolink.SetMediaPlaying(MediaPlaying.None);
            audiolink.SetMediaPlaying(MediaPlaying.Playing);
            audiolink.SetMediaPlaying(MediaPlaying.Paused);
            audiolink.SetMediaPlaying(MediaPlaying.Stopped);
            audiolink.SetMediaPlaying(MediaPlaying.Loading);
            audiolink.SetMediaPlaying(MediaPlaying.Streaming);
            audiolink.SetMediaPlaying(MediaPlaying.Error);
        }

    }

    // Update Media Volume
    public void UpdateVolume(float volume) {

        //Ranges from 0 to 1
        if (VRC.SDKBase.Utilities.IsValid(audiolink)) audiolink.SetMediaVolume(volume);

    }

    // Update Media Time
    public void UpdateTime(float time) {

        //Ranges from 0 to 1
        if (VRC.SDKBase.Utilities.IsValid(audiolink)) audiolink.SetMediaTime(time);

    }

    //Update Media Loop state
    public void UpdateLoop() {

        /* Avalible Loop states
        None       0 (0.0f)
        Loop       1 (1.0f)
        LoopOne    2 (2.0f)
        Random     3 (3.0f)
        RandomLoop 4 (4.0f)
        */
        if (VRC.SDKBase.Utilities.IsValid(audiolink)) {
            audiolink.SetMediaLoop(MediaLoop.None);
            audiolink.SetMediaLoop(MediaLoop.Loop);
            audiolink.SetMediaLoop(MediaLoop.LoopOne);
            audiolink.SetMediaLoop(MediaLoop.Random);
            audiolink.SetMediaLoop(MediaLoop.RandomLoop);
        }

    }
}
```