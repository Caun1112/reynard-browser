# 上游合并审查（2026-10-11）

## 1. 当前状态、分支与提交历史

- Fork：<https://github.com/Caun1112/reynard-browser>，remote `origin`。
- 上游：<https://github.com/minh-ton/reynard-browser>，remote `upstream`。
- 起始工作区干净，功能分支 `codex/right-hand-ui` 与其远端均为 `a50f384`。旧 `main` 不包含完整右手布局，本次不将其作为目标。
- 共同祖先：`86793782beed4f2667fac08325bdb9987b843bbb`。
- 固定上游快照：`05224364cf0adb81d23ef6e32cc8d117ec79287e`。包含 0.16.0 发布后的修复，并非只合并 0.16.0 标签。
- 相对共同祖先，fork 独有 18 个提交、71 个净改动文件；上游独有 16 个提交、116 个净改动文件。
- `git merge-tree --write-tree` 预演成功，无文本冲突；自动合并 tree 为 `208758acddc2ba7665526e5d3fb901207056cb56`。
- 两个本地子模块未初始化；正式编译在 GitHub Actions 中初始化并校验对应版本。

## 2. 修改归属及重叠范围

上游：应用 0.16.0、Firefox `FIREFOX_157_0_1_RELEASE`、原生文本输入重写、中文等组合文本光标修复、缩放/变换输入框的选择修复、跨进程 iframe 命中及指针捕获修复、iPad 浮动键盘修复、标签关闭后替补标签激活修复、Liquid Glass 交互、刷新指示器及错误提示的遮挡修复。接受上游移除错误实现的实验性原生画中画功能；该功能并非 fork 自有修改。

Fork：iPhone 横竖屏底部右手布局、44 点以上触控范围、单行工具栏、右下标签卡片及双向滑动关闭、可达的资料库/设置/编辑导航、键盘避让、扩展弹窗右下关闭按钮、现有 UI harness 和 fork Actions 构建支持。

| 重叠文件（相对于 browser/Reynard/Client/Interface） | 上游修改 | Fork 修改 | 合并决定 |
| --- | --- | --- | --- |
| BrowserViewController.swift | 新键盘 API、浮动键盘与弹层关闭识别 | iPhone 横屏使用底部布局 | 不同代码段，保留双方 |
| Chrome/ActionBar/FindInPage/FindInPageActionBar.swift | Liquid Glass 容器、交互效果及完成按钮 | 44 点触控范围、65 点旧系统尾部间距 | 保留双方，真机检查新容器布局 |
| Chrome/ActionBar/PageZoom/PageZoomActionBar.swift | 交互式玻璃效果及 capsule | 44 点高度、168 点旧系统宽度、右侧锚点 | 保留双方，真机检查横屏缩放操作 |
| Library/Settings/Sections/About/Experimental/ExperimentalFeaturesViewController.swift | 移除实验 PiP 行 | 重启提示 action sheet 样式 | 接受删除功能，保留提示样式 |
| TabOverview/TabOverviewPresentation.swift | 总是记录待激活标签，去掉已选中索引过滤 | 右下小尺寸卡片 | 保留双方，回归关闭标签后的替补选择 |

无需要人工取舍的文本冲突，独立复审也未发现确定的语义冲突。因此保留 Git 三方合并结果，不使用整文件 ours/theirs，也不增加无关应用改动。

## 3. 安全合并与回滚

备份先推送到 fork，独立分支采用双亲 merge；不 rebase、不强推。构建与产物验证通过后才快进原功能分支。

```sh
git fetch origin --prune
git fetch upstream --prune --tags
git branch backup/right-hand-ui-before-upstream-20261011 a50f384
git push origin backup/right-hand-ui-before-upstream-20261011
git switch -c codex/merge-upstream-20261011 a50f384
git merge --no-ff --no-commit 05224364cf0adb81d23ef6e32cc8d117ec79287e
# 未提交时取消：git merge --abort
# 审查合并结果及本报告后提交并推送。
git diff backup/right-hand-ui-before-upstream-20261011..codex/merge-upstream-20261011

# 构建和产物验证通过后：
git switch codex/right-hand-ui
git merge --ff-only codex/merge-upstream-20261011
git push origin codex/right-hand-ui

# 已共享的合并需要回滚时（MERGE_SHA 为本次双亲合并提交）：
git revert -m 1 MERGE_SHA
git push origin codex/right-hand-ui
```

以上回滚会撤销本次上游改动，保留合并前的 fork 功能及已有提交历史。备份分支仍保留完整旧版本。后续重新合入被 revert 的提交应先评估 revert-of-revert，不能假定重复 merge 会恢复它们。

## 4. 逐文件合并代码片段

以下为不同方法中的关键摘录，不是完整函数；完整实现以合并后的文件为准。

### BrowserViewController.swift

布局与键盘处理分属不同方法。右手模式继续传递真实方向；键盘改用上游的新接口，iPad 浮动键盘不触发页面上移。

```swift
if RightHandLayout.isEnabled {
    return resolvePhoneLayout(orientation: orientation)
}

browserChrome.onKeyboardDismissal = { [weak self] in
    self?.tabManager.selectedTab?.session.dismissSoftwareKeyboard()
}

let spansWindow = view.bounds.width > 0
&& keyboardFrame.width >= view.bounds.width * UX.floatingKeyboardWidthRatio
let sitsFlushWithBottom = keyboardFrame.maxY >= view.bounds.maxY - 8
let isFloatingKeyboard = browserLayout.interfaceIdiom == .pad
&& !(spansWindow && sitsFlushWithBottom)
```

### FindInPageActionBar.swift

尺寸常量仍为 fork 值；新版容器将子视图放入 visual effect 的 contentView，以适配上游玻璃效果。

```swift
static var controlsHeight: CGFloat {
    if #available(iOS 26.0, *) { return 48 }
    return 44
}
static var controlButtonWidth: CGFloat {
    if #available(iOS 26.0, *) { return 44 }
    return 55
}
static var contentTrailingInset: CGFloat {
    if #available(iOS 26.0, *) { return 12 }
    return 65
}

let contentView = (searchContentView as? UIVisualEffectView)?.contentView ?? searchContentView
```

### PageZoomActionBar.swift

视觉效果更新不改变右手位置约束；旧系统仍保留 44 点高、168 点宽、48 点单按钮宽。

```swift
@available(iOS 26.0, *)
func setModernContentHidden(_ hidden: Bool) {
    let effect = UIGlassEffect(style: .regular)
    effect.isInteractive = true
    controlsBackground.effect = hidden ? nil : effect
    controlsBackground.contentView.alpha = hidden ? 0 : 1
}

if RightHandLayout.isEnabled {
    controlsShadowView.rightAnchor.constraint(equalTo: safeAreaLayoutGuide.rightAnchor, constant: -65).isActive = true
} else {
    controlsShadowView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
}
```

### ExperimentalFeaturesViewController.swift

保留上游清空实验功能列表，不恢复失去引擎支持的 PiP 开关。现有、暂未调用的重启提示继续保留 fork 样式。

```swift
override func numberOfSections(in tableView: UITableView) -> Int {
    return 0
}

override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return 0
}

let alert = UIAlertController(
    title: "Restart Required",
    message: "The app will now close for the experimental setting to take effect.",
    preferredStyle: RightHandLayout.isEnabled ? .actionSheet : .alert
)
```

### TabOverviewPresentation.swift

卡片尺寸保留 fork 值；待选择标签即使索引等于替补标签，也必须执行选择以实际激活会话。

```swift
if RightHandLayout.isEnabled {
    // Keep previews and titles within the right thumb’s reach.
    return CGSize(width: max(1, floor(min(280, availableWidth * 0.78))),
                  height: min(180, max(100, collectionView.bounds.height * 0.23)) + 48)
}

func prepareDismissSelection(to index: Int, mode: TabMode, previewImage: UIImage?) {
    dismissalTargetTabIndex = index
    dismissalTargetTabMode = mode
    pendingSelectionTabIndex = index
    pendingSelectionTabMode = mode
    pendingSelectionPreviewImage = previewImage
}
```

## 5. 验证步骤、范围及结果

### 本地静态检查（已通过）

- 索引无未解决冲突，正式 merge tree 与三方预演完全相同。
- 66 个仅 fork 改动文件的 Git blob 与合并前逐一相同；111 个仅上游改动文件与固定上游逐一相同（含删除及子模块 gitlink）。
- 自动合并结果相对上游的差异文件集合恰好等于原有 71 个 fork 文件，没有 fork 文件丢失。新增本报告单独计入。
- 5 个重叠 Swift 文件均通过 `swiftc -frontend -parse`；此检查仅验证语法，不是 iOS SDK 类型检查。
- `sh -n tools/release/build-app.sh tools/release/create-ipa.sh` 通过。
- 完整 `git diff --cached --check` 报告上游既有的尾随空白/patch 上下文空行；未批量改写 Gecko patch。应用合并相对自动合并 tree 无额外差异。

### GitHub Actions 编译与 UI 测试

本机仅有 CommandLineTools，没有 Xcode 或 iOS SDK。按用户要求，仅使用 GitHub Actions 编译正式 TIPA。所有 gh 操作显式指定 fork，避免 CLI 默认解析到上游。

```sh
gh workflow run build.yml --repo Caun1112/reynard-browser \
  --ref codex/merge-upstream-20261011 \
  -f checkout_ref=MERGE_SHA \
  -f nightly=false -f prepare_dependencies_only=false \
  -f build_normal_ipa=false -f build_trollstore_tipa=true \
  -f build_jailbroken_ipa=false
```

`MERGE_SHA` 必须替换为完整固定提交 SHA。正式流程：初始化子模块、下载/应用 Gecko patches、编译引擎和 idevice、arm64 Release 归档、TrollStore entitlements 签名及 TIPA 打包。仅构建所需的 TIPA。

- 引擎版本：`FIREFOX_157_0_1_RELEASE`；gitlink `0c469c2352451630bc69fc328c9f0c589c6c534d`，与 Mozilla 远端 tag 一致。
- idevice gitlink：`d32c8189c51c2789496b0768039419c3705498c3`。
- SDK 缓存 key 包含引擎版本、全部 patches、build-gecko.sh、Rust/Xcode 和架构，没有旧 SDK 回退 key。派发前 fork 缓存为空，预计完整重编引擎。
- 上游新增的旧版 concurrency dylib 下载仅用于 jailbroken IPA；本次 TIPA 不经过该路径。
- 现有 6 个 UI 测试检查 iPhone 15 Pro Max 的右手工具栏点击、横竖屏、单行排列、底部导航、保存状态、键盘避让、滚动及明暗外观。测试使用部分替身，未编译本次 5 个重叠文件，不能替代完整 app 构建和真机回归。

### 产物验证（构建完成后执行）

1. 校验指定 Actions run、job、完整源码 SHA 和 TIPA artifact ID。
2. 下载 artifact ZIP，核对 GitHub API SHA-256 digest，验证外层和内层 ZIP CRC。
3. 主 app、Helper、OpenIn 的版本应为 0.16.0，build 应为固定构建 SHA 的前 7 位。
4. 检查 GeckoView、Gecko 引擎、插件及 `ts_ptrace_jit`，所有 Mach-O 应为 arm64。
5. 用 ldid 核对主程序、Helper、ts_ptrace_jit 三份 entitlements 与构建提交一致。
6. 生成 TIPA SHA-256 和验证报告；发布 fork 独立 Release，标签固定到实际构建提交，重新核对上传资产的大小和 digest。

### 真机运行与回归清单（未执行）

在支持的 TrollStore 设备安装 TIPA，确认启动、JIT、网页载入及重启后标签恢复。检查 iPhone 横竖屏右手工具栏、地址栏、资料库/设置/书签编辑、右下扩展弹窗关闭、标签双向滑动关闭及替补标签激活；检查查找、页面缩放、刷新指示器和崩溃提示。回归中文组合输入、光标、选择手柄、多行和缩放/变换输入框、键盘收起，以及 iPad 浮动键盘。检查扩展、下载、相机权限与视频播放。

真机运行结果不得由模拟器 harness 或编译成功推断。本报告后续补充实际 Actions、TIPA 和 Release 结果。
