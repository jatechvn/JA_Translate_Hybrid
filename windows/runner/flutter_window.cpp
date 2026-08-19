#include "flutter_window.h"

#include <optional>

#include "flutter/generated_plugin_registrant.h"
#include <dwmapi.h>
#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());

  auto channel = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      flutter_controller_->engine()->messenger(),
      "ja_translate/theme",
      &flutter::StandardMethodCodec::GetInstance());

  channel->SetMethodCallHandler(
      [this](const flutter::MethodCall<flutter::EncodableValue>& call,
             std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
        if (call.method_name().compare("setTheme") == 0) {
          const auto* arguments = call.arguments();
          if (arguments && std::holds_alternative<std::string>(*arguments)) {
            std::string theme = std::get<std::string>(*arguments);
            BOOL enable_dark_mode = (theme == "dark") ? TRUE : FALSE;
            HWND hWnd = GetHandle();
            if (hWnd) {
              DwmSetWindowAttribute(hWnd, 19, &enable_dark_mode, sizeof(enable_dark_mode));
              DwmSetWindowAttribute(hWnd, 20, &enable_dark_mode, sizeof(enable_dark_mode));
              
              RECT rect;
              GetWindowRect(hWnd, &rect);
              SetWindowPos(hWnd, nullptr, 0, 0, 
                           (rect.right - rect.left) - 1, (rect.bottom - rect.top), 
                           SWP_NOMOVE | SWP_NOZORDER | SWP_NOACTIVATE);
              SetWindowPos(hWnd, nullptr, 0, 0, 
                           (rect.right - rect.left), (rect.bottom - rect.top), 
                           SWP_NOMOVE | SWP_NOZORDER | SWP_NOACTIVATE | SWP_FRAMECHANGED);
              
              SendMessage(hWnd, WM_NCACTIVATE, FALSE, 0);
              SendMessage(hWnd, WM_NCACTIVATE, TRUE, 0);
            }
            result->Success(flutter::EncodableValue(true));
          } else {
            result->Error("BAD_ARGS", "Expected string argument");
          }
        } else {
          result->NotImplemented();
        }
      });
  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    this->Show();
  });

  // Flutter can complete the first frame before the "show window" callback is
  // registered. The following call ensures a frame is pending to ensure the
  // window is shown. It is a no-op if the first frame hasn't completed yet.
  flutter_controller_->ForceRedraw();

  return true;
}

void FlutterWindow::OnDestroy() {
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
