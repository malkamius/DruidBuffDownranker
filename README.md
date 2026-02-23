# DruidBuffDownranker

**DruidBuffDownranker** is a specialized World of Warcraft addon designed for **The Burning Crusade Classic (Anniversary)**. It simplifies the process of buffing allies and yourself by automatically selecting the highest possible rank of *Mark of the Wild* and *Thorns* that the target can receive based on their level.

## Features

-   **Smart Rank Selection**: Automatically downranks spells to ensure they can be cast on low-level targets without the "Target is too low level" error.
-   **Training Detection**: Only attempts to cast ranks you have actually trained at your class trainer. Button hides automatically until you know the spell.
-   **Level-Up Notifications**: Informs you in chat when you've reached a high enough level to train a new rank of *Mark of the Wild* or *Thorns*.
-   **Class Detection**: The entire addon and Action Bar automatically hides itself on characters that are not Druids.
-   **Draggable Interface**: A compact UI bar that can be moved anywhere on your screen.
-   **Mouseover Support**: Optionally cast buffs on your mouseover target instead of your current target.
-   **Full Keybinding Support**: Bind your smart-cast macros directly through the WoW Keybindings menu.

## Usage

### UI Bar
The addon provides a small bar with up to three icons (depending on what you've toggled on/off and learned):
-   **Mark of the Wild**
-   **Thorns**
-   **Omen of Clarity** (Self-buff only)

**Movement**: Hold `Shift` and drag the bar with your Left Mouse Button to reposition it.

### Keybindings
You can set up keybindings for one-click buffing:
1.  Open the **Game Menu** (Esc).
2.  Go to **Keybindings**.
3.  Scroll down to the **Druid Buff Downranker** section.
4.  Bind "Cast Smart MotW", "Cast Smart Thorns", and "Cast Smart Omen" to your preferred keys.

### Macros
If you prefer using your own macros, the addon creates secure buttons you can reference:
-   `/click SmartMotW`
-   `/click SmartThorns`

## Configuration

Settings can be toggled through the standard interface options, and are saved globally across your characters:
-   **Path**: `Esc > Options > AddOns > Druid > BuffDownranker`
-   **Settings Available**: 
    -   Show/Hide the Action Bar entirely.
    -   Show/Hide individual buttons for *Mark of the Wild*, *Thorns*, and *Omen of Clarity*. 
    -   Enable/Disable Mouseover casting for *Mark of the Wild* and *Thorns*.

## Installation

1.  Download the repository as a ZIP.
2.  Extract the contents to your WoW Classic `Interface/AddOns` directory.
3.  **Crucial**: Rename the extracted folder (e.g., `DruidBuffDownranker-main`) to exactly `DruidBuffDownranker`. If the folder name does not match, the addon will not load.
4.  Restart World of Warcraft or type `/reload` if you are already in-game.


---
*Created for TBC Classic Anniversary.*
