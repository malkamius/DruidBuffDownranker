# DruidBuffDownranker

**DruidBuffDownranker** is a specialized World of Warcraft addon designed for **The Burning Crusade Classic (Anniversary)**. It simplifies the process of buffing allies and yourself by automatically selecting the highest possible rank of *Mark of the Wild* and *Thorns* that the target can receive based on their level.

## Features

-   **Smart Rank Selection**: Automatically downranks spells to ensure they can be cast on low-level targets without the "Target is too low level" error.
-   **Training Detection**: Only attempts to cast ranks you have actually trained at your class trainer.
-   **Level-Up Notifications**: Informs you in chat when you've reached a high enough level to train a new rank of *Mark of the Wild* or *Thorns*.
-   **Draggable Interface**: A compact UI bar that can be moved anywhere on your screen.
-   **Mouseover Support**: Optionally cast buffs on your mouseover target instead of your current target.
-   **Full Keybinding Support**: Bind your smart-cast macros directly through the WoW Keybindings menu.

## Usage

### UI Bar
The addon provides a small bar with two icons:
-   **Left Icon**: Mark of the Wild
-   **Right Icon**: Thorns

**Movement**: Hold `Shift` and drag the bar with your Left Mouse Button to reposition it.

### Keybindings
You can set up keybindings for one-click buffing:
1.  Open the **Game Menu** (Esc).
2.  Go to **Keybindings**.
3.  Scroll down to the **Druid Buff Downranker** section.
4.  Bind "Cast Smart MotW" and "Cast Smart Thorns" to your preferred keys.

### Macros
If you prefer using your own macros, the addon creates secure buttons you can reference:
-   `/click SmartMotW`
-   `/click SmartThorns`

## Configuration

Settings can be toggled through the standard interface options:
-   **Path**: `Esc > Options > AddOns > Druid > BuffDownranker`
-   **Settings**: Enable/Disable mouseover casting for each spell individually.

## Installation

1.  Download the repository.
2.  Extract the `DruidBuffDownranker` folder to your WoW Classic `Interface/AddOns` directory.
3.  Restart World of Warcraft or type `/reload` if you are already in-game.

---
*Created for TBC Classic Anniversary.*
