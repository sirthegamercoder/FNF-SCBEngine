package backend;

class VersionUtil
{
	public static function compare(version1:String, version2:String):Int
	{
		if (version1 == null || version2 == null)
			return 0;

		version1 = version1.trim();
		version2 = version2.trim();

		if (version1 == version2)
			return 0;

		var v1Parts = parseVersion(version1);
		var v2Parts = parseVersion(version2);

		if (v1Parts.major < v2Parts.major)
			return -1;
		if (v1Parts.major > v2Parts.major)
			return 1;

		if (v1Parts.minor < v2Parts.minor)
			return -1;
		if (v1Parts.minor > v2Parts.minor)
			return 1;

		if (v1Parts.patch < v2Parts.patch)
			return -1;
		if (v1Parts.patch > v2Parts.patch)
			return 1;

		return 0;
	}

	public static function isLessThan(version1:String, version2:String):Bool
	{
		return compare(version1, version2) == -1;
	}

	public static function isGreaterThan(version1:String, version2:String):Bool
	{
		return compare(version1, version2) == 1;
	}

	public static function isEqual(version1:String, version2:String):Bool
	{
		return compare(version1, version2) == 0;
	}

	public static function isLessThanOrEqual(version1:String, version2:String):Bool
	{
		var result = compare(version1, version2);
		return result == -1 || result == 0;
	}

	public static function isGreaterThanOrEqual(version1:String, version2:String):Bool
	{
		var result = compare(version1, version2);
		return result == 1 || result == 0;
	}

	private static function parseVersion(version:String):Version
	{
		var cleaned = version.split('-')[0];
		cleaned = cleaned.split('+')[0];
		cleaned = normalizeDisplaySuffix(cleaned);

		var parts:Array<String> = cleaned.split('.');

		var major:Int = 0;
		var minor:Int = 0;
		var patch:Int = 0;

		if (parts.length > 0)
			major = Std.parseInt(parts[0]) ?? 0;

		if (parts.length > 1)
			minor = Std.parseInt(parts[1]) ?? 0;

		if (parts.length > 2)
			patch = Std.parseInt(parts[2]) ?? 0;

		return {
			major: major,
			minor: minor,
			patch: patch
		};
	}

	public static function isValid(version:String):Bool
	{
		if (version == null || version.trim() == "")
			return false;

		var cleaned = normalizeDisplaySuffix(version.trim());

		var regex:EReg = ~/^(\d+)(?:\.(\d+))?(?:\.(\d+))?(?:-([0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*))?(?:\+([0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*))?$/;
		return regex.match(cleaned);
	}

	private static function normalizeDisplaySuffix(version:String):String
	{
		if (version == null)
			return "";

		var trimmed = version.trim();
		var regex:EReg = ~/\s*\([^\)]*\)\s*$/;
		if (regex.match(trimmed))
			return regex.matchedLeft().trim();

		return trimmed;
	}

	public static function getComparisonString(currentVersion:String, remoteVersion:String):String
	{
		var result = compare(currentVersion, remoteVersion);

		if (result == -1)
			return '$currentVersion is older than $remoteVersion';
		else if (result == 1)
			return '$currentVersion is newer than $remoteVersion';
		else
			return 'Up to date! (v$currentVersion)';
	}
}

typedef Version =
{
	var major:Int;
	var minor:Int;
	var patch:Int;
}
