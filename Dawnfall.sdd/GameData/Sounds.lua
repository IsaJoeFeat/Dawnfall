local Sounds = {
  SoundItems = {
    IncomingChat = {
      --- always play on the front speaker(s)
      file = "sounds/beep4.wav",
      in3d = "false",
    },
    MultiSelect = {
      --- always play on the front speaker(s)
      file = "sounds/button9.wav",
      in3d = "false",
    },
    MapPoint = {
      --- respect where the point was set, but don't attenuate in distance
      --- also, when moving the camera, don't pitch it
      file = "sounds/beep6.wav",
      rolloff = 0,
      dopplerscale = 0,
    },
    SwordHit = {
      --- some things you can do with this file
      --- can be either ogg or wav
      file = "sounds/swordhit.wav",
      gain = 1,
      pitch = 1,
      dopplerscale = 1,
      priority = 0,
      maxconcurrent = 16,
      maxdist = 20000,
      rolloff = 1,
      in3d = true,
      looptime = 0,
    },

    -- new since 89.0
    default = {
      gainmod = 0.35,
      pitchmod = 0.3,
      pitch = 0.7,
      in3d = true,
    },
  },
}

return Sounds