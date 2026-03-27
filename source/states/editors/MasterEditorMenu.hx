package states.editors;

import backend.WeekData;

import objects.Character;
import flixel.FlxObject;

import states.MainMenuState;
import states.FreeplayState;

class MasterEditorMenu extends MusicBeatState
{
	var options:Array<String> = [
		'Chart Editor',
		'Character Editor',
		'Stage Editor',
		'Week Editor',
		'Menu Character Editor',
		'Dialogue Editor',
		'Dialogue Portrait Editor',
		'Note Splash Editor'
	];

	var iconNames:Array<String> = [
		'chart',
		'character',
		'stage',
		'week',
		'menuChar',
		'dialogue',
		'portrait',
		'noteSplash'
	];
	
	private var grpItems:FlxTypedGroup<FlxSpriteGroup>;
	private var directories:Array<String> = [null];

	private var curSelected = 0;
	private var curDirectory = 0;
	private var directoryTxt:FlxText;
	
	private var itemWidth:Float = 250;
	private var itemHeight:Float = 180;
	private var itemSpacing:Float = 20;

	override function create()
	{
		FlxG.camera.bgColor = FlxColor.BLACK;
		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Editors Main Menu", null);
		#end

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.scrollFactor.set();
		bg.color = 0xFF353535;
		add(bg);

		grpItems = new FlxTypedGroup<FlxSpriteGroup>();
		add(grpItems);

		var centerX:Float = (FlxG.width - itemWidth) / 2;
		var centerY:Float = (FlxG.height - itemHeight) / 2;

		for (i in 0...options.length)
		{
			var itemGroup:FlxSpriteGroup = new FlxSpriteGroup();
			itemGroup.x = centerX;
			itemGroup.y = centerY;

			var iconBg:FlxSprite = new FlxSprite().makeGraphic(150, 150, FlxColor.WHITE);
			iconBg.setGraphicSize(120, 120);
			iconBg.updateHitbox();
			iconBg.screenCenter(XY);
			iconBg.x = (itemWidth / 2) - (iconBg.width / 2);
			iconBg.y = -30;
			iconBg.alpha = 0.2;
			iconBg.antialiasing = ClientPrefs.data.antialiasing;
			itemGroup.add(iconBg);

			var icon:FlxSprite = new FlxSprite().loadGraphic(Paths.image('editors/menuIcons/' + iconNames[i]));
			icon.setGraphicSize(100, 100);
			icon.updateHitbox();
			icon.screenCenter(XY);
			icon.x = (itemWidth / 2) - (icon.width / 2);
			icon.y = -20;
			icon.antialiasing = ClientPrefs.data.antialiasing;
			itemGroup.add(icon);

			var leText:Alphabet = new Alphabet(0, 70, options[i], true);
			leText.screenCenter(X);
			leText.x = (itemWidth / 2) - (leText.width / 2);
			leText.alpha = 0.6;
			itemGroup.add(leText);
			
			grpItems.add(itemGroup);
			itemGroup.visible = false;
		}

		if (grpItems.length > 0) grpItems.members[0].visible = true;

		#if MODS_ALLOWED
		var textBG:FlxSprite = new FlxSprite(0, FlxG.height - 42).makeGraphic(FlxG.width, 42, 0xFF000000);
		textBG.alpha = 0.6;
		add(textBG);

		directoryTxt = new FlxText(textBG.x, textBG.y + 4, FlxG.width, '', 32);
		directoryTxt.setFormat(Paths.font("phantom.ttf"), 32, FlxColor.WHITE, CENTER);
		directoryTxt.scrollFactor.set();
		add(directoryTxt);
		
		for (folder in Mods.getModDirectories())
		{
			directories.push(folder);
		}

		var found:Int = directories.indexOf(Mods.currentModDirectory);
		if(found > -1) curDirectory = found;
		changeDirectory();
		#end
		
		Cursor.hide();

		addTouchPad('LEFT_FULL', 'A_B');

		super.create();
	}

	override function update(elapsed:Float)
	{
		if (controls.UI_LEFT_P)
		{
			changeSelection(-1);
		}
		if (controls.UI_RIGHT_P)
		{
			changeSelection(1);
		}

		#if MODS_ALLOWED
		if(controls.UI_UP_P)
		{
			changeDirectory(-1);
		}
		if(controls.UI_DOWN_P)
		{
			changeDirectory(1);
		}
		#end

		if (controls.BACK)
		{
			MusicBeatState.switchState(new MainMenuState());
		}

		if (controls.ACCEPT)
		{
			switch(options[curSelected]) {
				case 'Chart Editor':
					LoadingState.loadAndSwitchState(new ChartingState(), false);
				case 'Character Editor':
					LoadingState.loadAndSwitchState(new CharacterEditorState(Character.DEFAULT_CHARACTER, false));
				case 'Stage Editor':
					LoadingState.loadAndSwitchState(new StageEditorState());
				case 'Week Editor':
					MusicBeatState.switchState(new WeekEditorState());
				case 'Menu Character Editor':
					MusicBeatState.switchState(new MenuCharacterEditorState());
				case 'Dialogue Editor':
					LoadingState.loadAndSwitchState(new DialogueEditorState(), false);
				case 'Dialogue Portrait Editor':
					LoadingState.loadAndSwitchState(new DialogueCharacterEditorState(), false);
				case 'Note Splash Editor':
					MusicBeatState.switchState(new NoteSplashEditorState());
			}
			FlxG.sound.music.volume = 0;
			FreeplayState.destroyFreeplayVocals();
		}
		
		super.update(elapsed);
	}

	function changeSelection(change:Int = 0)
	{
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		if (grpItems.members[curSelected] != null)
			grpItems.members[curSelected].visible = false;

		curSelected = FlxMath.wrap(curSelected + change, 0, options.length - 1);

		if (grpItems.members[curSelected] != null)
			grpItems.members[curSelected].visible = true;
	}

	#if MODS_ALLOWED
	function changeDirectory(change:Int = 0)
	{
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		curDirectory += change;

		if(curDirectory < 0)
			curDirectory = directories.length - 1;
		if(curDirectory >= directories.length)
			curDirectory = 0;
	
		WeekData.setDirectoryFromWeek();
		if(directories[curDirectory] == null || directories[curDirectory].length < 1)
			directoryTxt.text = '< No Mod Directory Loaded >';
		else
		{
			Mods.currentModDirectory = directories[curDirectory];
			directoryTxt.text = '< Loaded Mod Directory: ' + Mods.currentModDirectory + ' >';
		}
		directoryTxt.text = directoryTxt.text.toUpperCase();
	}
	#end
}