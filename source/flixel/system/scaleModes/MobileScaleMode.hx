package flixel.system.scaleModes;

import flixel.FlxG;

/**
 * ...
 * @author: Karim Akra
 */
class MobileScaleMode extends BaseScaleMode
{
	public static var allowWideScreen(default, set):Bool = true;

	public static final BASE_GAME_WIDTH:Int = 1280;
	public static final BASE_GAME_HEIGHT:Int = 720;

	static var screenWidth:Float = 0;
	static var screenHeight:Float = 0;

	public static inline function getSafeWidth():Int
	{
		return BASE_GAME_WIDTH;
	}

	public static inline function getSafeHeight():Int
	{
		return BASE_GAME_HEIGHT;
	}

	public static function getHorizontalOffset():Float
	{
		if (!ClientPrefs.data.wideScreen || !allowWideScreen)
			return 0;
		
		var screenRatio:Float = screenWidth / screenHeight;
		var baseRatio:Float = BASE_GAME_WIDTH / BASE_GAME_HEIGHT;
		
		if (screenRatio <= baseRatio)
		{
			return 0;
		}

		return Math.max(0, (FlxG.width - BASE_GAME_WIDTH) / 2);
	}

	public static function getVerticalOffset():Float
	{
		if (!ClientPrefs.data.wideScreen || !allowWideScreen)
			return 0;
		
		var screenRatio:Float = screenWidth / screenHeight;
		var baseRatio:Float = BASE_GAME_WIDTH / BASE_GAME_HEIGHT;
		
		if (screenRatio >= baseRatio)
		{
			return 0;
		}

		return Math.max(0, (FlxG.height - BASE_GAME_HEIGHT) / 2);
	}

	public static inline function isWideActive():Bool
	{
		return ClientPrefs.data.wideScreen && allowWideScreen;
	}
	
	public static inline function getScreenWidth():Int
	{
		return FlxG.width;
	}

	public static inline function getScreenHeight():Int
	{
		return FlxG.height;
	}

	override function onMeasure(Width:Int, Height:Int):Void
	{
		screenWidth = Width;
		screenHeight = Height;
		
		if (ClientPrefs.data.wideScreen && allowWideScreen)
		{
			var screenRatio:Float = Width / Height;
			var baseRatio:Float = BASE_GAME_WIDTH / BASE_GAME_HEIGHT;
			
			if (screenRatio < baseRatio)
			{
				FlxG.width = BASE_GAME_WIDTH;
				FlxG.height = Math.ceil(BASE_GAME_WIDTH / screenRatio);
			}
			else
			{
				FlxG.height = BASE_GAME_HEIGHT;
				FlxG.width = Math.ceil(BASE_GAME_HEIGHT * screenRatio);
			}

			gameSize.x = Width;
			gameSize.y = Height;
		}
		else
		{
			FlxG.width = BASE_GAME_WIDTH;
			FlxG.height = BASE_GAME_HEIGHT;
			
			var ratio:Float = BASE_GAME_WIDTH / BASE_GAME_HEIGHT;
			var realRatio:Float = Width / Height;
			var scaleY:Bool = realRatio < ratio;

			if (scaleY)
			{
				gameSize.x = Width;
				gameSize.y = Math.floor(gameSize.x / ratio);
			}
			else
			{
				gameSize.y = Height;
				gameSize.x = Math.floor(gameSize.y * ratio);
			}
		}
		
		updateDeviceSize(Width, Height);
		updateScaleOffset();
		updateGamePosition();
	}

	@:noCompletion
	private static function set_allowWideScreen(value:Bool):Bool
	{
		if (allowWideScreen == value)
			return value;
			
		allowWideScreen = value;

		if (Std.isOfType(FlxG.scaleMode, MobileScaleMode))
		{
			if (FlxG.game != null)
			{
				FlxG.resizeGame(FlxG.width, FlxG.height);
			}
		}
		
		return value;
	}
}