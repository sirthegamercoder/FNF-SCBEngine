package mobile.backend.native;

#if android
import haxe.Json;
import lime.system.JNI;

class NativeDropDown
{
	public static inline var NO_SELECTION:Int = -1;
	public static inline var CANCELED:Int = -2;

	public static inline var SCROLL_STATE_IDLE:Int = 0;
	public static inline var SCROLL_STATE_TOUCH_SCROLL:Int = 1;
	public static inline var SCROLL_STATE_FLING:Int = 2;

	@:noCompletion private static var _initialized:Bool = false;
	@:noCompletion private static var _showDropDown_jni:Dynamic = null;
	@:noCompletion private static var _pollSelection_jni:Dynamic = null;
	@:noCompletion private static var _isDialogVisible_jni:Dynamic = null;
	@:noCompletion private static var _isScrolling_jni:Dynamic = null;
    @:noCompletion private static var _getScrollState_jni:Dynamic = null;

	@:noCompletion
	private static function ensureInit():Bool
	{
		if (_initialized)
			return _showDropDown_jni != null && _pollSelection_jni != null && _isDialogVisible_jni != null;

		_initialized = true;
		try
		{
			_showDropDown_jni = JNI.createStaticMethod(
				'com/sirthegamercoder/scbengine/DropDown',
				'showDropDown',
				'(Ljava/lang/String;Ljava/lang/String;I)Z'
			);

			_pollSelection_jni = JNI.createStaticMethod(
				'com/sirthegamercoder/scbengine/DropDown',
				'pollSelection',
				'()I'
			);

			_isDialogVisible_jni = JNI.createStaticMethod(
				'com/sirthegamercoder/scbengine/DropDown',
				'isDialogVisible',
				'()Z'
			);

			_isScrolling_jni = JNI.createStaticMethod(
				'com/sirthegamercoder/scbengine/DropDown',
				'isScrolling',
				'()Z'
			);
			
			_getScrollState_jni = JNI.createStaticMethod(
				'com/sirthegamercoder/scbengine/DropDown',
				'getScrollState',
				'()I'
			);
		}
		catch (e:Dynamic)
		{
			trace('JNI init failed: ' + e);
		}

		return _showDropDown_jni != null && _pollSelection_jni != null && _isDialogVisible_jni != null;
	}

	public static function show(title:String, items:Array<String>, selectedIndex:Int):Bool
	{
		if (items == null || items.length == 0)
			return false;

		if (!ensureInit())
			return false;

		try
		{
			return _showDropDown_jni(title, Json.stringify(items), selectedIndex);
		}
		catch (e:Dynamic)
		{
			trace('show failed: ' + e);
		}

		return false;
	}

	public static function pollSelection():Int
	{
		if (!ensureInit())
			return NO_SELECTION;

		try
		{
			return _pollSelection_jni();
		}
		catch (e:Dynamic)
		{
			trace('pollSelection failed: ' + e);
		}

		return NO_SELECTION;
	}

	public static function isScrolling():Bool
	{
		if (!ensureInit())
			return false;

		try
		{
			return _isScrolling_jni();
		}
		catch (e:Dynamic)
		{
			trace('isScrolling failed: ' + e);
		}

		return false;
	}

	public static function getScrollState():Int
	{
		if (!ensureInit())
			return SCROLL_STATE_IDLE;

		try
		{
			return _getScrollState_jni();
		}
		catch (e:Dynamic)
		{
			trace('getScrollState failed: ' + e);
		}

		return SCROLL_STATE_IDLE;
	}

	public static function isDialogVisible():Bool
	{
		if (!ensureInit())
			return false;

		try
		{
			return _isDialogVisible_jni();
		}
		catch (e:Dynamic)
		{
			trace('isDialogVisible failed: ' + e);
		}

		return false;
	}
}
#else
class NativeDropDown
{
	public static inline var NO_SELECTION:Int = -1;
	public static inline var CANCELED:Int = -2;

	public static function show(title:String, items:Array<String>, selectedIndex:Int):Bool
		return false;

	public static function pollSelection():Int
		return NO_SELECTION;

	public static function isDialogVisible():Bool
		return false;
}
#end