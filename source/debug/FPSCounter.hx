package debug;

import flixel.FlxG;
import openfl.Lib;
import haxe.Timer;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.system.System as OpenFlSystem;
import lime.system.System as LimeSystem;

/**
	The FPS class provides an easy-to-use monitor to display
	the current frame rate of an OpenFL project
**/
#if cpp
#if windows
@:cppFileCode('#include <windows.h>')
#elseif (ios || mac)
@:cppFileCode('#include <mach-o/arch.h>')
#else
@:headerInclude('sys/utsname.h')
#end
#end

class FPSCounter extends TextField
{
	/**
		The current frame rate, expressed using frames-per-second
	**/
	public var currentFPS(default, null):Int;

	/**
		The current memory usage (WARNING: this is NOT your total program memory usage, rather it shows the garbage collector memory)
	**/

	public var memoryMegas(get, never):Float;

	/**
		Peak memory usage tracking
	**/
	public var memoryPeak(default, null):Float = 0;
	
	/**
		Smooth memory display (interpolated for smooth animation)
	**/
	private var displayedMemory:Float = 0;
	private var displayedMemoryPeak:Float = 0;
	private var memoryLerpSpeed:Float = 0.1;
	
	/**
		Text display field
	**/
	private var textDisplay:TextField;

	public static var instance:FPSCounter;

	private var lastFrameTime:Float = 0.0;
	private var frameTimeMs:Float = 0.0;
	private var frameTimesArray:Array<Float> = [];
	private var avgFrameTimeMs:Float = 0.0;

	@:noCompletion private var times:Array<Float>;
	@:noCompletion private var lastFramerateUpdateTime:Float;
	@:noCompletion private var updateTime:Int;
	@:noCompletion private var framesCount:Int;
	@:noCompletion private var prevTime:Int;

	public function new(x:Float = 45, y:Float = 30, color:Int = 0x000000)
    {
        super();
        
        instance = this;
        
        positionFPS(x, y);
        
        currentFPS = 0;

        selectable = false;
        mouseEnabled = false;
        defaultTextFormat = new TextFormat(Paths.font("phantom.ttf"), 14, color);
        antiAliasType = openfl.text.AntiAliasType.NORMAL;
        sharpness = 100;
        width = 350;
        height = 550;
        x = X;
        y = Y;
        multiline = true;
        text = "FPS";
        wordWrap = false;
        autoSize = openfl.text.TextFieldAutoSize.LEFT;
        
        times = [];
        lastFramerateUpdateTime = Timer.stamp();
        prevTime = Lib.getTimer();
        updateTime = prevTime + 500;
        
        lastFrameTime = Timer.stamp();
        frameTimesArray = [];
    }
    
    public dynamic function updateText():Void
    {
        var currentMemory = memoryMegas;
        
        if (currentMemory > memoryPeak) {
            memoryPeak = currentMemory;
        }
        
        if (displayedMemory == 0) {
            displayedMemory = currentMemory;
            displayedMemoryPeak = memoryPeak;
        } else {
            displayedMemory += (currentMemory - displayedMemory) * memoryLerpSpeed;
            displayedMemoryPeak += (memoryPeak - displayedMemoryPeak) * memoryLerpSpeed;
        }
        
        var currentMemoryStr = flixel.util.FlxStringUtil.formatBytes(displayedMemory);
        var peakMemoryStr = flixel.util.FlxStringUtil.formatBytes(displayedMemoryPeak);
        
        var targetFPS = #if (ClientPrefs && ClientPrefs.data && ClientPrefs.data.framerate) ClientPrefs.data.framerate #else FlxG.stage.window.frameRate #end;
        var halfFPS = targetFPS * 0.5;
        var textColorValue:Int;
        
        if (currentFPS >= halfFPS) {
            textColorValue = 0xFFFFFF;
        } else {
            textColorValue = 0xFF0000;
        }
        defaultTextFormat = new TextFormat(Paths.font("phantom.ttf"), 14, textColorValue);
        setTextFormat(defaultTextFormat);
        
        var displayText:String = "";
        displayText = '' + Std.string(currentFPS) + ' FPS';
        displayText += '\n' + formatFloat(frameTimeMs, 1) + ' / ' + formatFloat(avgFrameTimeMs, 1) + ' ms';
        displayText += '\n' + currentMemoryStr + ' / ' + peakMemoryStr;
        
        text = displayText;
    }

	var deltaTimeout:Float = 0.0;
	private override function __enterFrame(deltaTime:Float):Void
	{
		var currentFrameTime = Timer.stamp();
		frameTimeMs = (currentFrameTime - lastFrameTime) * 1000.0;
		lastFrameTime = currentFrameTime;

		frameTimesArray.push(frameTimeMs);
		if (frameTimesArray.length > 10) {
			frameTimesArray.shift();
		}
		
		var sum:Float = 0.0;
		for (time in frameTimesArray) {
			sum += time;
		}
		avgFrameTimeMs = sum / frameTimesArray.length;
		
		if (ClientPrefs.data.fpsRework)
		{
			// Flixel keeps reseting this to 60 on focus gained
			if (FlxG.stage.window.frameRate != ClientPrefs.data.framerate && FlxG.stage.window.frameRate != FlxG.game.focusLostFramerate)
				FlxG.stage.window.frameRate = ClientPrefs.data.framerate;

			var currentTime = openfl.Lib.getTimer();
			framesCount++;

			if (currentTime >= updateTime)
			{
				var elapsed = currentTime - prevTime;
				currentFPS = Math.round((framesCount * 1000) / elapsed);
				framesCount = 0;
				prevTime = currentTime;
				updateTime = currentTime + 500;
			}

			// Set Update and Draw framerate to the current FPS every 1.5 second to prevent "slowness" issue
			if ((FlxG.updateFramerate >= currentFPS + 5 || FlxG.updateFramerate <= currentFPS - 5)
				&& haxe.Timer.stamp() - lastFramerateUpdateTime >= 1.5
				&& currentFPS >= 30)
			{
				FlxG.updateFramerate = FlxG.drawFramerate = currentFPS;
				lastFramerateUpdateTime = haxe.Timer.stamp();
			}
		}
		else
		{
			final now:Float = haxe.Timer.stamp() * 1000;
			times.push(now);
			while (times[0] < now - 1000)
				times.shift();

			if (deltaTimeout < 33)
			{
				deltaTimeout += deltaTime;
				return;
			}

			currentFPS = times.length;
			deltaTimeout = 0.0;
		}

		updateText();
	}

	private function formatFloat(value:Float, decimals:Int):String {
		var multiplier = Math.pow(10, decimals);
		var rounded = Math.round(value * multiplier) / multiplier;
		var str = Std.string(rounded);

		if (str.indexOf('.') == -1) {
			str += '.';
		}
		
		var parts = str.split('.');
		if (parts.length > 1) {
			while (parts[1].length < decimals) {
				parts[1] += '0';
			}
			return parts[0] + '.' + parts[1];
		}
		
		return str + StringTools.lpad('', '0', decimals);
	}

	private function getGCStats():String {
		#if cpp
		try {
			var totalMem = cpp.vm.Gc.memInfo64(cpp.vm.Gc.MEM_INFO_RESERVED);
			var usedMem = cpp.vm.Gc.memInfo64(cpp.vm.Gc.MEM_INFO_USAGE);
			var freeMem = totalMem - usedMem;
			
			var freePercentage = Math.round((freeMem / totalMem) * 100);
			return '${freePercentage}% free';
		} catch (e:Dynamic) {
			return 'N/A';
		}
		#else
		return 'N/A';
		#end
	}

	inline function get_memoryMegas():Float
		return cpp.vm.Gc.memInfo64(cpp.vm.Gc.MEM_INFO_USAGE);

	public inline function positionFPS(X:Float, Y:Float, ?scale:Float = 1){
		scaleX = scaleY = 1.0;
		x = X;
		y = Y;
	}

	#if cpp
	#if windows
	@:functionCode('
		SYSTEM_INFO osInfo;

		GetSystemInfo(&osInfo);

		switch(osInfo.wProcessorArchitecture)
		{
			case 9:
				return ::String("x86_64");
			case 5:
				return ::String("ARM");
			case 12:
				return ::String("ARM64");
			case 6:
				return ::String("IA-64");
			case 0:
				return ::String("x86");
			default:
				return ::String("Unknown");
		}
	')
	#elseif (ios || mac)
	@:functionCode('
		const NXArchInfo *archInfo = NXGetLocalArchInfo();
    	return ::String(archInfo == NULL ? "Unknown" : archInfo->name);
	')
	#else
	@:functionCode('
		struct utsname osInfo{};
		uname(&osInfo);
		return ::String(osInfo.machine);
	')
	#end
	@:noCompletion
	private function getArch():String
	{
		return "Unknown";
	}
	#end
}