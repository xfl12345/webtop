#!/usr/bin/env bash

### 清除浏览器无效排他资源
if [[ "$(ls ~/.config/google-chrome/Singleton*)" != "" ]]; then
    rm  ~/.config/google-chrome/Singleton*
    echo "[完成] 清除 Google Chrome 浏览器无效排他资源"
fi

if [[ "$(ls ~/.config/BraveSoftware/Brave-Browser/Singleton*)" != "" ]]; then
    rm  ~/.config/BraveSoftware/Brave-Browser/Singleton*
    echo "[完成] 清除 Brave 浏览器无效排他资源"
fi

