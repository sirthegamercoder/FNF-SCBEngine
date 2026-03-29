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
		The smoothed frame rate for stable display
	**/
	public var smoothedFPS(default, null):Int;

	/**
		The current memory usage (WARNING: this is NOT your total program memory usage, rather it shows the garbage collector memory)
	**/
	public var memoryMegas(get, never):Float;
	
	/**
		Peak memory usage tracked during gameplay
	**/
	public var peakMemoryMegas(default, null):Float;

	@:noCompletion private var times:Array<Float>;
	@:noCompletion private var lastFramerateUpdateTime:Float;
	@:noCompletion private var updateTime:Int;
	@:noCompletion private var framesCount:Int;
	@:noCompletion private var prevTime:Int;
	
	@:noCompletion private var smoothedFPSValue:Float;
	@:noCompletion private var smoothingFactor:Float;

	public var os:String = '';

	public function new(x:Float = 10, y:Float = 10, color:Int = 0x000000)
	{
		super();

		if (LimeSystem.platformName == LimeSystem.platformVersion || LimeSystem.platformVersion == null)
			os = '\nOS: ${LimeSystem.platformName}' #if cpp + ' ${getArch() != 'Unknown' ? getArch() : ''}' #end;
		else
			os = '\nOS: ${LimeSystem.platformName}' #if cpp + ' ${getArch() != 'Unknown' ? getArch() : ''}' #end + ' - ${LimeSystem.platformVersion}';

		positionFPS(x, y);

		currentFPS = 0;
		smoothedFPS = 0;
		smoothedFPSValue = 0;
		smoothingFactor = 0.3;
		peakMemoryMegas = 0;
		
		selectable = false;
		mouseEnabled = false;
		defaultTextFormat = new TextFormat(Paths.font("phantom.ttf"), 14, color);
		width = FlxG.width;
		multiline = true;
		text = "FPS: ";

		times = [];
		lastFramerateUpdateTime = Timer.stamp();
		prevTime = Lib.getTimer();
		updateTime = prevTime + 500;
	}
	
	private function updateSmoothedFPS():Void
	{
		if (smoothedFPSValue == 0) {
			smoothedFPSValue = currentFPS;
		} else {
			smoothedFPSValue = (smoothedFPSValue * (1 - smoothingFactor)) + (currentFPS * smoothingFactor);
		}
		smoothedFPS = Math.round(smoothedFPSValue);
	}
	
	private function updatePeakMemory():Void
	{
		if (memoryMegas > peakMemoryMegas) {
			peakMemoryMegas = memoryMegas;
		}
	}
	
	private function getFPSColor():Int
	{
		var targetFPS = ClientPrefs.data.framerate;
		if (targetFPS <= 0) targetFPS = 60;
		
		var ratio = smoothedFPS / targetFPS;
		
		if (ratio >= 0.9) return 0xFF00FF00;
		if (ratio >= 0.7) return 0xFFFFFF00;
		if (ratio >= 0.5) return 0xFFFFA500;
		return 0xFFFF0000;
	}
	
	private function formatBytes(bytes:Float):String
	{
		return flixel.util.FlxStringUtil.formatBytes(bytes);
	}

	public dynamic function updateText():Void // so people can override it in hscript
	{
		updatePeakMemory();
		
		var memoryStr = formatBytes(memoryMegas);
		var peakStr = formatBytes(peakMemoryMegas);
		var fpsToShow = smoothedFPS;

		text = 
		'FPS: $fpsToShow' + 
		'\nMemory: $memoryStr / $peakStr' +
		os;

		textColor = getFPSColor();
	}

	var deltaTimeout:Float = 0.0;
	private override function __enterFrame(deltaTime:Float):Void
	{
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
				currentFPS = Math.ceil((framesCount * 1000) / elapsed);
				framesCount = 0;
				prevTime = currentTime;
				updateTime = currentTime + 500;

				updateSmoothedFPS();
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
			// prevents the overlay from updating every frame, why would you need to anyways @crowplexus
			if (deltaTimeout < 50)
			{
				deltaTimeout += deltaTime;
				return;
			}

			currentFPS = times.length < FlxG.updateFramerate ? times.length : FlxG.updateFramerate;
			deltaTimeout = 0.0;

			updateSmoothedFPS();
		}

		updateText();
	}

	inline function get_memoryMegas():Float
		return cpp.vm.Gc.memInfo64(cpp.vm.Gc.MEM_INFO_USAGE);

	public inline function positionFPS(X:Float, Y:Float, ?scale:Float = 1){
		scaleX = scaleY = #if android (scale > 1 ? scale : 1) #else (scale < 1 ? scale : 1) #end;
		x = FlxG.game.x + X;
		y = FlxG.game.y + Y;
	}

	public inline function resetPeakMemory():Void
	{
		peakMemoryMegas = memoryMegas;
	}

	public inline function setSmoothingFactor(factor:Float):Void
	{
		smoothingFactor = Math.max(0.05, Math.min(0.95, factor));
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