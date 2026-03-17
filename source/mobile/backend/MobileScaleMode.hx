package mobile.backend;

import flixel.system.scaleModes.BaseScaleMode;

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

	public static function getVerticalOffset():Float
	{
		if (!ClientPrefs.data.wideScreen || !allowWideScreen)
			return 0;
		
		if (screenWidth == 0 || screenHeight == 0)
			return 0;

		var screenRatio:Float = screenWidth / screenHeight;
		var targetRatio:Float = BASE_GAME_WIDTH / BASE_GAME_HEIGHT;
		
		if (screenRatio >= targetRatio)
		{
			return 0;
		}

		var scaledHeight:Float = FlxG.height;
		var baseHeightAtCurrentScale:Float = (screenWidth / FlxG.width) * BASE_GAME_HEIGHT;
		var extraHeight:Float = scaledHeight - baseHeightAtCurrentScale;
		
		return Math.max(0, extraHeight / 2);
	}

	override function updateGameSize(Width:Int, Height:Int):Void
	{
		screenWidth = Width;
		screenHeight = Height;
		
		if (ClientPrefs.data.wideScreen && allowWideScreen)
		{
			super.updateGameSize(Width, Height);
		}
		else
		{
			var ratio:Float = FlxG.width / FlxG.height;
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
	}

	override function updateGamePosition():Void
	{
		super.updateGamePosition();
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
