# AutoRunner

An AutoHotkey script that can autorun .lnk files upon drive mounting


## Usage

[Pass the drive names as parameters](https://www.autohotkey.com/docs/Scripts.htm#cmd) to the script.

For example:

```
AutoHotkey.exe AutoRunner.ahk W: X:
```

or if you compile the script into .exe:

```
AutoRunner.exe W: X:
```

**Order matters;** the script will scan the drives in order specified.


### Options

Options can be placed before, between, or after drive specifications. Currently available options:

`--dir PATH`

> PATH = drive-less absolute path where autorun targets will be searched within.
>
> Defaults to `\autoruns`
>
> Examples:
>
> * `--dir \autoruns`
> * `--dir \start`

`--exts EXTENSIONS`

> EXTENSIONS = comma-separated extensions (period-less) specifying the autorun targets in the
> autorun directory
>
> Defaults to `lnk`
>
> Examples:
>
> * `--exts lnk`
> * `--exts lnk,exe`


## Installation

Just download the `.ahk` file and run it.

You can optionally compile it to an `.exe` if you want. I'm _not_ providing the compiled script because
antivirus programs seems to be _very_ jumpy with UPX- or MPRESS-compressed executables.


## Contributing

* Please use the [**Whitesmiths brace style**](https://en.wikipedia.org/wiki/Indentation_style#Whitesmiths_style).

  Why? Because it looks like Python ;-)

* I'd appreciate it if you assign your contribution's copyright to me, so if there's a need to change the license
  of this software, I can do that easily.


## License

This script is released under the [MPL 2.0 License](https://www.mozilla.org/en-US/MPL/2.0/).

I chose this license because it is a **file-level license**; if you want to release a proprietary product
using my script, feel free. You DON'T have to release your proprietary product with MPL _except_ for my script;
Changes to my script must be made public, though, because I want to see how you improve it :-)


## Copyrights

Copyright (c) 2020, Pandu POLUAN <pepoluan@gmail.com>


## Attributions

* Icons made by [Icongeek26](https://www.flaticon.com/authors/icongeek26) from
[www.flaticon.com](https://www.flaticon.com/)  

  used under Flaticon License "Free for personal and commercial purpose with attribution."
