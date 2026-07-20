# Third-party asset attribution

`ow_icons5x9.png`, `icons3x7.png`, `s_map_overworld_vanilla_strip8.png`,
`icons7x7.png`, `icons8x16.png`, `icons10x10.png`, `zelda_items16x16.png`,
`all-items-hud-pixels1.png`, `all-items-hud-pixels1-worse.png`, and `icons8x8.png` are copied from
[Zelda1RandoTools](https://github.com/brianmcn/Zelda1RandoTools) by Brian
McNamara, used under the MIT License:

```
The MIT License (MIT)

Copyright (c) 2021 Brian McNamara

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

See `docs/decisions/0001-native-swiftui-over-avalonia-port.md` for the
decision to reuse these assets rather than redraw them.

## Game sprite GIFs (`Resources/*.gif`)

The individual sprite GIFs in `Sources/ZTrackerMac/Resources/*.gif` are ripped
*The Legend of Zelda* (1986) game sprites — **© Nintendo**. They are used here
only as functional item/marker indicators in a non-commercial, personal fan
tracker (this project is a clone of Zelda1RandoTools, which serves the same
purpose). They are **not** MIT-licensed and are not covered by the notice above;
they remain the property of Nintendo. `T-161` migrated the tracker's icons onto
them, replacing the cruder reference atlases.

## App icon (`Bundle/AppIcon.png`)

The app icon is an original "quest-log" crest supplied by the project owner
(generated with an image tool). It uses generic RPG iconography — a plain
heraldic shield, hearts, a map/compass, a sword, a banner — and deliberately
avoids Nintendo's protected marks (no Triforce, Hylian Shield crest, or Master
Sword).
