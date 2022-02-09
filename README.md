# RecorderLibrary

1. In your *-ios project, add the java files to the src folder.
2. Add `libRecorder.a` to the `build/libs/ios` folder. 
3. Add the line `<lib>build/libs/ios/libRecorder.a</lib>` in the block in `robovm.xml`.
4. Follow the instructions at https://libgdx.com/wiki/app/interfacing-with-platform-specific-code to interface with the ios recorder functions.
