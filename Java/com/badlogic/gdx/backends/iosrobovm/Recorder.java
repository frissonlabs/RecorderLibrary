package com.badlogic.gdx.backends.iosrobovm;

import org.robovm.apple.foundation.NSObject;
import org.robovm.objc.ObjCRuntime;
import org.robovm.objc.Selector;
import org.robovm.objc.annotation.NativeClass;
import org.robovm.rt.bro.annotation.Bridge;
import org.robovm.rt.bro.annotation.Library;
import org.robovm.rt.bro.ptr.FloatPtr;

import com.badlogic.gdx.audio.AudioRecorder;

@Library(Library.INTERNAL)
@NativeClass
public class Recorder extends NSObject implements AudioRecorder{

	static { ObjCRuntime.bind(Recorder.class); }
	
    private static final Selector startRecording = Selector.register("startRecording");
    
    @Bridge private native static void objc_startRecording(Recorder __self__, Selector __cmd__);
    public void startRecording() {
        objc_startRecording(this, startRecording);
    }
    
    private static final Selector readSamples = Selector.register("readSamples");
  
    @Bridge private native static FloatPtr objc_readSamples(Recorder __self__, Selector __cmd__);
    public void read(short[] samples, int offset, int numSamples) {
    	float[] temp = new float[samples.length];
        objc_readSamples(this, readSamples).get(temp, offset, numSamples);
        for(int i = 0; i < samples.length; i++){
        	samples[i] = (short) (temp[i] * 32768.0);
        }
    }
    
    private static final Selector stopRecording = Selector.register("stopRecording");
    
    @Bridge private native static void stopRecording(Recorder __self__, Selector __cmd__);
    public void stopRecording() {
        stopRecording(this, stopRecording);
    }
}