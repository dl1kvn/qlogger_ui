#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include "flutter_window.h"
#include "utils.h"

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);

  // Calculate window size: 1:1.8 aspect ratio, max width 800px, max height 80% screen
  int screenHeight = GetSystemMetrics(SM_CYSCREEN);
  int maxHeight = static_cast<int>(screenHeight * 0.8);
  int width = 800;
  int height = static_cast<int>(width * 1.8);  // 1:1.8 aspect ratio

  // If calculated height exceeds 80% of screen, scale down
  if (height > maxHeight) {
    height = maxHeight;
    width = static_cast<int>(height / 1.8);
  }

  // Center the window horizontally
  int screenWidth = GetSystemMetrics(SM_CXSCREEN);
  int originX = (screenWidth - width) / 2;
  int originY = (screenHeight - height) / 2;

  Win32Window::Point origin(originX, originY);
  Win32Window::Size size(width, height);
  if (!window.Create(L"qlogger_ui", origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}
