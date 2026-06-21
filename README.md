# AnimeFaceFollower

iOS SwiftUI App Demo: Real-time face tracking with Vision framework. An adorable anime-style character whose eyes follow you in real time via the front camera.

## 特性
- 实时前置摄像头预览
- 使用 Apple Vision 框架进行人脸检测
- 可爱的 2D 动漫风格人物，眼睛会实时跟随你的脸部位置转动
- 平滑的眼睛跟随动画
- 纯原生 SwiftUI + Vision + AVFoundation（无任何第三方依赖）

## 如何运行

1. 打开 Xcode，创建新的 **iOS App** 项目（选择 SwiftUI 界面，Swift 语言）
2. 随便命名（例如 AnimeFaceFollower）
3. 删除默认的 `ContentView.swift`
4. 将本仓库中的四个 `.swift` 文件添加到你的项目中
5. 打开 `Info.plist` （或项目设置 → Info），添加相机权限：
   ```xml
   <key>NSCameraUsageDescription</key>
   <string>需要相机权限来实时检测人脸，让动漫人物眼睛跟随你</string>
   ```
6. 在真机上 Build & Run（前置摄像头 + 人脸检测在真机上效果最好，Simulator 支持有限）

## 项目结构
- `CameraManager.swift` — 处理 AVCaptureSession + Vision 人脸检测
- `CameraPreview.swift` — UIViewRepresentable 实现实时摄像头预览
- `AnimeCharacterView.swift` — 可爱动漫人物 + 眼睛跟随逻辑
- `ContentView.swift` — 主界面，组合所有组件

## 技术实现
- 使用 `VNDetectFaceRectanglesRequest` 实时人脸检测
- 眼睛子根据从角色眼睛到检测到的脸部中心的向量进行移动
- 正确处理了前置摄像头的镜像和坐标系转换

## 后续改进建议
- 使用 `VNDetectFaceLandmarksRequest` 获取更精确的五官位置
- 引入 `VNTrackObjectRequest` 提升性能和跟踪稳定性
- 支持多人脸，选择最大/最近的一个
- 添加眨眼动画或根据表情改变嘴型
- 用自定义 PNG 图片替换向量图形，做出更精致的动漫风格
- 添加 RealityKit AR 模式

## 截图 / Demo

运行后可以添加截图。

---

**Made with ❤️ using SwiftUI + Vision**