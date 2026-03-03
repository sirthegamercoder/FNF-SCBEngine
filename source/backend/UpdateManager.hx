package backend;

import haxe.Http;
import states.MainMenuState;

class UpdateManager
{
	public static var hasUpdate:Bool = false;
	public static var latestVersion:String = "";
	public static var currentVersion:String = "";
	public static var isChecking:Bool = false;
	private static var updateURL:String = "https://raw.githubusercontent.com/sirthegamercoder/FNF-SCBEngine/refs/heads/main/gitVersion.txt";
	public static var changelogURL:String = "https://raw.githubusercontent.com/sirthegamercoder/FNF-SCBEngine/refs/heads/main/gitChangelog.txt";
	public static var releaseURL:String = "https://github.com/sirthegamercoder/FNF-SCBEngine/releases";
	private static var baseDownloadURL:String = "https://github.com/sirthegamercoder/FNF-SCBEngine/releases/download";
	private static var downloadFilenames:Map<String, String> = [
		"windows" => "SCBEngine-Windows.zip",
		"linux" => "SCBEngine-Linux.zip",
		"mac" => "SCBEngine-macOS.zip",
		"android" => "SCBEngine-Android.apk"
	];

	private static var updateCheckCallback:Void->Void = null;

	public static function checkForUpdates(?customURL:String, ?onComplete:Void->Void):String
	{
		if (customURL != null && customURL.length > 0)
			updateURL = customURL;

		currentVersion = MainMenuState.plusEngineVersion.trim();
		hasUpdate = false;
		latestVersion = currentVersion;
		isChecking = true;

		if (!ClientPrefs.data.checkForUpdates)
		{
			trace('Update checking is disabled in settings');
			isChecking = false;
			if (onComplete != null)
				onComplete();
			return currentVersion;
		}

		trace('Checking for updates...');
		trace('Current version: $currentVersion (${getVersionType(currentVersion)})');

		#if sys
		sys.thread.Thread.create(function()
		{
			performUpdateCheck(onComplete);
		});
		#else
		performUpdateCheck(onComplete);
		#end

		return currentVersion;
	}

	private static function performUpdateCheck(?onComplete:Void->Void):Void
	{
		var http = new Http(updateURL);

		http.onData = function(data:String)
		{
			var remoteVersion:String = data.split('\n')[0].trim();
			trace('Remote version: $remoteVersion (${getVersionType(remoteVersion)})');

			if (!VersionUtil.isValid(currentVersion))
			{
				trace('WARNING: Current version "$currentVersion" is not valid semantic version');
			}

			if (!VersionUtil.isValid(remoteVersion))
			{
				trace('WARNING: Remote version "$remoteVersion" is not valid semantic version');
			}

			if (VersionUtil.isLessThan(currentVersion, remoteVersion))
			{
				trace('Update available! $currentVersion -> $remoteVersion');
				hasUpdate = true;
				latestVersion = remoteVersion;
			}
			else if (VersionUtil.isEqual(currentVersion, remoteVersion))
			{
				trace('Already up to date! (v$currentVersion)');
				hasUpdate = false;
				latestVersion = currentVersion;
			}
			else
			{
				trace('Your version is newer than latest release ($currentVersion > $remoteVersion)');
				hasUpdate = false;
				latestVersion = remoteVersion;
			}

			isChecking = false;
			http.onData = null;
			http.onError = null;
			http = null;

			if (onComplete != null)
			{
				updateCheckCallback = onComplete;
			}
		};

		http.onError = function(error:String)
		{
			trace('Error checking for updates: $error');
			hasUpdate = false;
			isChecking = false;

			http.onData = null;
			http.onError = null;
			http = null;

			if (onComplete != null)
			{
				updateCheckCallback = onComplete;
			}
		};

		http.request();
	}

	private static function getVersionType(version:String):String
	{
		if (normalized.indexOf("beta") != -1)
			return "beta version";

		return "stable release";
	}

	public static function update():Void
	{
		if (updateCheckCallback != null)
		{
			var callback = updateCheckCallback;
			updateCheckCallback = null;
			callback();
		}
	}

	public static function getDownloadURL():String
	{
		var platform:String = getPlatformKey();
		var version:String = latestVersion.length > 0 ? latestVersion : currentVersion;

		if (downloadFilenames.exists(platform))
		{
			var filename:String = downloadFilenames.get(platform);
			return '$baseDownloadURL/$version/$filename';
		}

		return releaseURL;
	}

	public static function openDownloadPage():Void
	{
		var url = getDownloadURL();
		trace('Opening download page: $url');
		CoolUtil.browserLoad(url);
	}

	private static function getPlatformKey():String
	{
		#if windows
		return "windows";
		#elseif linux
		return "linux";
		#elseif mac
		return "mac";
		#elseif android
		return "android";
		#elseif ios
		return "ios";
		#else
		return "unknown";
		#end
	}

	public static function getPlatformName():String
	{
		#if windows
		return "Windows";
		#elseif linux
		return "Linux";
		#elseif mac
		return "macOS";
		#elseif android
		return "Android";
		#elseif ios
		return "iOS";
		#else
		return "Unknown Platform";
		#end
	}

	public static function supportsAutoUpdate():Bool
	{
		#if (windows || linux || mac)
		return true;
		#elseif android
		return false;
		#elseif ios
		return false;
		#else
		return false;
		#end
	}

	public static function getUpdateInfo():String
	{
		var info:String = "";

		info += 'Current Version: $currentVersion\n';
		info += 'Latest Version: $latestVersion\n';
		info += 'Platform: ${getPlatformName()}\n';

		if (hasUpdate)
		{
			info += 'Status: Update Available!\n';
			info += VersionUtil.getComparisonString(currentVersion, latestVersion);
		}
		else
		{
			info += 'Status: Up to date!';
		}

		return info;
	}

	public static function reset():Void
	{
		hasUpdate = false;
		latestVersion = "";
		currentVersion = "";
		isChecking = false;
		updateCheckCallback = null;
	}
}
