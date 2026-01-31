# GREAT FIRE WALL SIMULATOR - Tutorial Content

## 命题阐述 / Introduction
[center][color=#cccccc]
本次 Game Jam 要求在 48 小时内完成一款基于 [color=#00ff41]“MASK”[/color] 主题的游戏。
核心机制必须包含 [color=#00ff41]“精准且快速”[/color] 的操作。

[i]我们对核心元素进行了技术化的诠释：[/i]
将 “Mask” 解构为网络工程中的 [b][color=#00ff41]“子网掩码 (Subnet Mask)”[/color

玩家需要左手操作键盘控制“掩码”，右手点击 IP，从而对流量进行精准且快速地分发的分发。

## 核心协议 / Core Protocol

[center][font_size=24]
[color=#888888]核心协议 Protocol[/color]

[color=#00ffff]TARGET_IP[/color]  [b]=[/b]  [color=#00ff41]INCOMING_IP[/color]  [b]&[/b]  [color=#ffff00]YOUR_MASK[/color]
[/font_size][/center]

## 界面指南 / Interface Guide
```
[center][font_size=12][code][color=#00ff41]
   _____ ______ _       __   [color=#00ffff]TARGET: 192.168.1.0/24[/color]
  / ____|  ____| |     / /   [color=#cccccc](Current Objective)[/color]
 | |  __| |__  | | /| / /    
 | | |_ |  __| | |/ |/ /     [color=#ffff00]MASK: 255.255.255.0[/color]
 | |__| | |    |   |   |     [color=#cccccc]Q:/8 W:/16 E:/24 R:/32[/color]
  \_____|_|     |__/|__/     
                             
       [color=#cccccc]Incoming Traffic[/color]
           │
           ▼
    [color=#00ff41]192.168.1.45[/color]  ✓ [color=#888888](Match)[/color]
    [color=#ff3333]10.0.0.12[/color]     ✗ [color=#888888](Ignore)[/color]
    [color=#ff0000][ WARNING ][/color]    ☠ [color=#888888](VIRUS)[/color]

         .|||||||||.
        |||||||||||||
       /. `|||||||||'
      o__,_|||||||||
      |  |||||||||||
       \ `||||||||||
        `||||||||||'
         `||||||||'     [b]IDENTITY: V[/b]
           `||||'       [i]"Ideas are bulletproof."[/i]
[/color][/code][/font_size][/center]
```

## 操作指令 / Controls
[center]
[b]操作指令 / CONTROLS[/b]

[color=#ffff00]Q[/color] : /8 [color=#888888](255.0.0.0)[/color]      [color=#ffff00]W[/color] : /16 [color=#888888](255.255.0.0)[/color]
[color=#ffff00]E[/color] : /24 [color=#888888](255.255.255.0)[/color]    [color=#ffff00]R[/color] : /32 [color=#888888](255.255.255.255)[/color]

[/center]





我想以 ASCII Art 的形式表达附件文档中的所有内容，作为游戏 Great Fire Wall Simulator 的新手引导与初始化页面。注意：总共只有一屏，需要包含所有内容。
