# Uma-Radar

OCR Team Trials Refresh Script for Umamusume: Pretty Derby

Built in AutoHotkey, credit to thqby for their amazing [Rapid OCR Library](https://github.com/thqby/ahk2_lib/tree/master/RapidOcr) and also iseahound for their [ImagePut Library](https://github.com/iseahound/ImagePut).

This script is designed to automatically refresh the Team Trials screen in Umamusume: Pretty Derby until it finds the specified opponents. It uses OCR to read the opponent names from the screen and compares them against a list of target names provided by the user.

## Usage

- **`F9`: STOP THE SCRIPT**

There are two ways to use this script:

### .EXE Method (Quicker)

1. Go to the [releases](https://github.com/Gredrah/Uma-Radar/releases) page and download the latest version of the script. Extract `Uma-Radar.exe.zip` and run `Uma-Radar.exe`.

2. Run `Uma-Radar.exe` once to create the `config.ini` file. Open `config.ini` and set the `targets` variable to the names of the opponents you want to find, separated by commas. For example:

    ```targets=Special Week, Silence Suzuka, Tokai Teio```

3. Save the `config.ini` file and run `Uma-Radar.exe` again. The script will automatically search for the specified opponents in the game.

### .AHK Method (More Customizable)

1. Download and install [AutoHotkey](https://www.autohotkey.com/).

2. Download the `Uma-Radar.ahk.zip` from the [releases](https://github.com/Gredrah/Uma-Radar/releases) page, or [clone this project](https://docs.github.com/en/repositories/creating-and-managing-repositories/cloning-a-repository).

3. Either run `Uma-Radar.ahk` directly or compile it to an executable using AutoHotkey's compiler.

4. Once you've run the script, it will create a `config.ini` file. Open `config.ini` and set the `targets` variable to the names of the opponents you want to find, separated by commas. For example:

    ```targets=Special Week, Silence Suzuka, Tokai Teio```

5. Save the `config.ini` file and run the script again. The script will automatically search for the specified opponents in the game.

**Please test this first by using a word that you know will be on the screen before the opponent's name, such as "Starting" or "Next". This will help you confirm that the script is working correctly.**

## Settings

The `config.ini` file contains the following settings:

- `sound`: Add your own .wav file if you're feeling quirky and change the config to point to it.

- `TargetText`: A comma-separated list of opponent names to search for. For example: `targets=Special Week, Silence Suzuka, Tokai Teio`

- `CoordX` and `CoordY`: The X and Y coordinates of the location on the screen to be clicked, defaults to the location of the team trials refresh button on 1080p resolution. Adjust these values if you are using a different resolution or if the refresh button is in a different location.

- `sleept`: The amount of time (in milliseconds) to wait between each refresh. Adjust this value if you want the script to refresh more or less frequently. However, the default is roughly how long the image takes to stabilize.

- `jumpBack`: A binary setting (0 or 1) that sets whether to return your mouse to its original position after clicking the refresh button. Set this to 1 if you want the script to move your mouse back to its original position after refreshing, or set it to 0 if you want the mouse to stay on the refresh button.
