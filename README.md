# FlypyHelper

一个原生 macOS 小鹤双拼练习器：看中文，输入对应的双拼编码。

## 功能

- 支持单字、词语、句子和文章四种练习模式
- 实时统计准确率、字速、键速和历史最佳成绩
- 小鹤双拼虚拟键盘与按键提示
- 连续输错 3 次后显示拼音和双拼码提示

## 运行

需要 macOS 14 或更高版本，以及 Swift 6。

```bash
git clone https://github.com/Logic995/flypy-helper.git
cd FlypyHelper
swift run
```

安装为 macOS 应用：

```bash
./scripts/install_app.sh
```

## 快捷键

- `⌘⌥K` 打开/隐藏全局参考面板。
- `ESC` 关闭当前小窗（菜单栏程序继续运行）。
- `TAB` 临时高亮下一键。
- `SPACE` 在输入中作为分隔符；输入为空时切到下一题。

## 退出

点击参考面板右上角的电源按钮，或右键菜单栏图标并选择“退出 FlypyHelper”。
