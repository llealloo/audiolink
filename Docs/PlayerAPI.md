# Using the Player API

- Import AudioLink `using AudioLink;`
- Add AudioLink variable `public AudioLink.AudioLink audiolink;`
- Set Volume display `audiolink.SetMediaVolume(player.volume);`
- Set Time display `audiolink.SetMediaTime(player.time);`
- Set Playback display `audiolink.SetMediaPlaying((int)MediaPlaying.playing)`
- Set Loop display `audiolink.SetMediaLoop((int)MediaLoop.Loop)`

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
        None    0 (0.00)
        Playing 1 (0.10)
        Paused  2 (0.20)
        Stopped 3 (0.30)
        Loading 4 (0.40)
        Streaming 5 (0.50)
        Error     6 (0.60)
        */
        if (Utilities.IsValid(audiolink)) {
            audiolink.SetMediaPlaying((int)MediaPlaying.None);
            audiolink.SetMediaPlaying((int)MediaPlaying.Playing);
            audiolink.SetMediaPlaying((int)MediaPlaying.Paused);
            audiolink.SetMediaPlaying((int)MediaPlaying.Stopped);
            audiolink.SetMediaPlaying((int)MediaPlaying.Loading);
            audiolink.SetMediaPlaying((int)MediaPlaying.Streaming);
            audiolink.SetMediaPlaying((int)MediaPlaying.Error);
        }

    }

    //Update Media Volume
    public void UpdateVolume(float volume) {

        //Ranges from 0 to 1
        if (Utilities.IsValid(audiolink)) audiolink.SetMediaVolume(volume);

    }

    //Update Media Time
    public void UpdateTime(float time) {

        //Ranges from 0 to 1
        if (Utilities.IsValid(audiolink)) audiolink.SetMediaTime(time);

    }

    //Update Media Loop state
    public void UpdateLoop() {

        /* Avalible Loop states
        None       0 (0.00)
        Loop       1 (0.10)
        LoopOne    2 (0.20)
        Random     3 (0.30)
        RandomLoop 4 (0.40)
        */
        if (Utilities.IsValid(audiolink)) {
            audiolink.SetMediaLoop((int)MediaLoop.None);
            audiolink.SetMediaLoop((int)MediaLoop.Loop);
            audiolink.SetMediaLoop((int)MediaLoop.LoopOne);
            audiolink.SetMediaLoop((int)MediaLoop.Random);
            audiolink.SetMediaLoop((int)MediaLoop.RandomLoop);
        }

    }
}
```