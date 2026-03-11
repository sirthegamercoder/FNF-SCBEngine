/*
 * Copyright (C) 2026 Mobile Porting Team
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 */

package flixel.system.scaleModes;

import flixel.FlxG;
import flixel.math.FlxPoint;

/**
 * Mobile-optimized scale mode
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