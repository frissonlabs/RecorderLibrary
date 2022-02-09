# RecorderLibrary

1. In your *-ios project, add the java files to the src folder and then add the libRecorder.a file to the build/libs/ios folder. 
2. Add the line `<lib>build/libs/ios/libRecorder.a</lib>` in the block in `robovm.xml`.
3. Follow the instructions at https://github.com/libgdx/libgdx/wiki/Interfacing-with-platform-specific-code to interface with the ios recorder functions.
