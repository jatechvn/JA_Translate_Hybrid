// lib/modules/ui/main_window.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:path/path.dart' as p;
import 'package:logging/logging.dart';

import '../modules.dart';
import 'styles.dart';
import 'dialogs.dart';

final _logger = Logger('MainWindow');

class MainWindow extends StatefulWidget {
  const MainWindow({Key? key}) : super(key: key);

  @override
  State<MainWindow> createState() => _MainWindowState();
}

class _MainWindowState extends State<MainWindow> {
  int _activeTab = 0; // 0: File, 1: Text, 2: Image, 3: Settings/Dict
  
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final logic = Provider.of<TranslationLogic>(context);

    if (!logic.isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primaryTeal),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent, // Để lộ lớp kính mờ Acrylic/Mica
      body: Row(
        children: [
          // Sidebar bên trái
          _buildSidebar(themeProvider),
          
          // Vùng nội dung bên phải
          Expanded(
            child: Container(
              color: Theme.of(context).scaffoldBackgroundColor.withOpacity(
                themeProvider.enableTransparency && isWindows11OrNewer() ? 0.85 : 1.0
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    // Thanh tiêu đề ảo (Window Drag Header)
                    _buildWindowHeader(themeProvider),
                    
                    // Nội dung Tab chính
                    Expanded(
                      child: _buildActiveTabContent(logic, themeProvider),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- CÁC PHẦN GIAO DIỆN CHÍNH ---

  Widget _buildWindowHeader(ThemeProvider themeProvider) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: themeProvider.isDark ? AppColors.borderDark : AppColors.borderLight,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.g_translate, color: AppColors.accentTeal, size: 20),
          const SizedBox(width: 8),
          const Text(
            appName,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primaryTeal.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'v$appVersion',
              style: TextStyle(fontSize: 10, color: AppColors.accentTeal, fontWeight: FontWeight.w600),
            ),
          ),
          const Spacer(),
          // Toggle Theme nhanh trên Titlebar
          IconButton(
            icon: Icon(themeProvider.isDark ? Icons.light_mode : Icons.dark_mode, size: 18),
            onPressed: () {
              themeProvider.updateTheme(
                themeProvider.isDark ? ThemeMode.light : ThemeMode.dark,
                themeProvider.enableTransparency,
              );
              final logic = Provider.of<TranslationLogic>(context, listen: false);
              logic.updateConfig(themeMode: themeProvider.isDark ? 'dark' : 'light');
            },
            tooltip: 'Đổi giao diện Sáng/Tối',
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(ThemeProvider themeProvider) {
    final isDark = themeProvider.isDark;
    
    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark.withOpacity(0.9) : AppColors.cardLight.withOpacity(0.9),
        border: Border(
          right: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
            width: 1.0,
          ),
        ),
      ),
      child: Column(
        children: [
          // Logo & Title
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primaryTeal, AppColors.sapphireBlue],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.translate, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'JA Translate',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 0.5),
                    ),
                    Text(
                      'Hybrid Engine',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.grey),
          const SizedBox(height: 16),
          
          // Các nút chọn tab
          _buildSidebarItem(0, Icons.insert_drive_file_outlined, Icons.insert_drive_file, 'Dịch tài liệu'),
          _buildSidebarItem(1, Icons.text_fields_outlined, Icons.text_fields, 'Dịch văn bản'),
          _buildSidebarItem(2, Icons.image_outlined, Icons.image, 'Dịch hình ảnh'),
          _buildSidebarItem(3, Icons.settings_suggest_outlined, Icons.settings_suggest, 'Cấu hình & Từ điển'),
          
          const Spacer(),
          
          // Footer
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Hệ điều hành Windows',
                  style: TextStyle(fontSize: 10, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      isWindows11OrNewer() ? 'Windows 11 (Tương thích tốt)' : 'Windows 10',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(int index, IconData outlineIcon, IconData solidIcon, String title) {
    final isActive = _activeTab == index;
    final color = isActive ? AppColors.accentTeal : Colors.grey[400];
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: InkWell(
        onTap: () => setState(() => _activeTab = index),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: isActive ? AppColors.primaryTeal.withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: isActive 
                ? Border.all(color: AppColors.primaryTeal.withOpacity(0.3), width: 1)
                : Border.all(color: Colors.transparent, width: 1),
          ),
          child: Row(
            children: [
              Icon(isActive ? solidIcon : outlineIcon, color: color, size: 20),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.grey[300],
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveTabContent(TranslationLogic logic, ThemeProvider themeProvider) {
    switch (_activeTab) {
      case 0:
        return _DocumentTab(logic: logic, themeProvider: themeProvider);
      case 1:
        return _TextTab(logic: logic, themeProvider: themeProvider);
      case 2:
        return _ImageTab(logic: logic, themeProvider: themeProvider);
      case 3:
        return _SettingsTab(logic: logic, themeProvider: themeProvider);
      default:
        return const Center(child: Text('Tab không hợp lệ'));
    }
  }
}

// ============================================================================
// TAB 1: DỊCH TÀI LIỆU (EXCEL, WORD, TXT)
// ============================================================================
class _DocumentTab extends StatefulWidget {
  final TranslationLogic logic;
  final ThemeProvider themeProvider;
  const _DocumentTab({required this.logic, required this.themeProvider, Key? key}) : super(key: key);

  @override
  State<_DocumentTab> createState() => _DocumentTabState();
}

class _DocumentTabState extends State<_DocumentTab> {
  final List<File> _selectedFiles = [];
  bool _isTranslating = false;
  String _targetLang = 'vi';
  double _progressValue = 0.0;
  String _statusText = '';
  
  // Lưu lịch sử dịch tài liệu
  final List<Map<String, dynamic>> _historyResults = [];

  Future<void> _pickFiles() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'docx', 'txt', 'pdf', 'pptx'],
        allowMultiple: true,
      );

      if (result != null) {
        setState(() {
          for (var path in result.paths) {
            if (path != null) {
              final file = File(path);
              if (!_selectedFiles.any((f) => f.path == path)) {
                _selectedFiles.add(file);
              }
            }
          }
        });
      }
    } catch (e) {
      _logger.severe('Pick files error: $e');
    }
  }

  void _clearSelectedFiles() {
    setState(() {
      _selectedFiles.clear();
    });
  }

  Future<void> _startTranslation() async {
    if (_selectedFiles.isEmpty) {
      Dialogs.showMessage(context, 'Cảnh báo', 'Vui lòng chọn hoặc kéo thả tệp tài liệu trước.', isError: true);
      return;
    }

    setState(() {
      _isTranslating = true;
      _progressValue = 0.0;
      _statusText = 'Đang chuẩn bị tiến trình dịch thuật...';
    });

    int successCount = 0;
    
    for (int i = 0; i < _selectedFiles.length; i++) {
      final file = _selectedFiles[i];
      final fileName = p.basename(file.path);
      
      setState(() {
        _statusText = 'Đang dịch file ($i/${_selectedFiles.length}): $fileName...';
        _progressValue = i / _selectedFiles.length;
      });

      // Tạo đường dẫn file kết quả (lưu cùng thư mục, thêm đuôi dịch ngôn ngữ)
      final dir = p.dirname(file.path);
      final ext = p.extension(file.path);
      final baseNameWithoutExt = p.basenameWithoutExtension(file.path);
      final destPath = p.join(dir, '${baseNameWithoutExt}_${_targetLang.toUpperCase()}$ext');

      try {
        final result = await widget.logic.translateFile(srcPath: file.path, destPath: destPath, targetLang: _targetLang);
        
        if (result['success'] == true) {
          successCount++;
          _historyResults.add({
            'fileName': fileName,
            'destPath': destPath,
            'success': true,
            'total_translated': result['total_translated'] ?? 0,
            'remaining_chinese_count': result['remaining_chinese_count'] ?? 0,
            'remaining_cells': result['remaining_cells'] ?? [],
            'time': DateTime.now(),
          });
        } else {
          _historyResults.add({
            'fileName': fileName,
            'success': false,
            'error': result['error'] ?? 'Lỗi không xác định',
            'time': DateTime.now(),
          });
        }
      } catch (e) {
        _historyResults.add({
          'fileName': fileName,
          'success': false,
          'error': e.toString(),
          'time': DateTime.now(),
        });
      }
    }

    setState(() {
      _isTranslating = false;
      _progressValue = 1.0;
      _statusText = 'Hoàn thành dịch $successCount/${_selectedFiles.length} file tài liệu!';
      _selectedFiles.clear(); // Xóa list file đã dịch xong
    });
  }

  void _openFolder(String filePath) {
    final dirPath = p.dirname(filePath);
    if (Platform.isWindows) {
      Process.run('explorer.exe', [dirPath]);
    } else if (Platform.isMacOS) {
      Process.run('open', [dirPath]);
    } else {
      Process.run('xdg-open', [dirPath]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DropTarget(
      onDragDone: (details) {
        setState(() {
          for (var file in details.files) {
            final ext = p.extension(file.path).toLowerCase();
            if (ext == '.xlsx' || ext == '.docx' || ext == '.txt' || ext == '.pdf' || ext == '.pptx') {
              if (!_selectedFiles.any((f) => f.path == file.path)) {
                _selectedFiles.add(File(file.path));
              }
            }
          }
        });
      },
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tiêu đề
            const Text(
              'Dịch thuật Tài liệu chuyên sâu (SOP / Bản vẽ / Hướng dẫn)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 4),
            const Text(
              'Bảo toàn 100% định dạng file gốc (Hình ảnh, Màu nền, Font chữ, Border ô Excel...). Hỗ trợ tự động nhận chữ Trung và quét lỗi sau dịch.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Dịch sang ngôn ngữ:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.cardDark.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.borderDark, width: 0.5),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _targetLang,
                      items: translationLanguages.entries
                          .where((e) => e.key != 'auto')
                          .map((e) {
                        return DropdownMenuItem<String>(
                          value: e.key,
                          child: Text(e.value, style: const TextStyle(fontSize: 13)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _targetLang = val);
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Drop zone kéo thả tệp
            Expanded(
              flex: 4,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.cardDark.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primaryTeal.withOpacity(0.4), width: 1.5, style: BorderStyle.solid),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.cloud_upload_outlined, color: AppColors.accentTeal, size: 56),
                    const SizedBox(height: 16),
                    const Text(
                      'Kéo & thả file Excel (.xlsx), Word (.docx), PowerPoint (.pptx), PDF (.pdf) hoặc Text (.txt) vào đây',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    const Text('hoặc', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _isTranslating ? null : _pickFiles,
                      icon: const Icon(Icons.search),
                      label: const Text('Chọn tệp từ máy tính'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryTeal,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Danh sách file đang chọn
            if (_selectedFiles.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.cardDark.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Text(
                      'Đã chọn ${_selectedFiles.length} file tài liệu',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.accentTeal),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: _clearSelectedFiles,
                      icon: const Icon(Icons.clear_all, size: 16, color: Colors.redAccent),
                      label: const Text('Xóa hết', style: TextStyle(fontSize: 12, color: Colors.redAccent)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                flex: 3,
                child: ListView.builder(
                  itemCount: _selectedFiles.length,
                  itemBuilder: (context, index) {
                    final file = _selectedFiles[index];
                    final ext = p.extension(file.path).toUpperCase();
                    final isExcel = ext == '.XLSX';
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 6),
                      child: ListTile(
                        leading: Icon(
                          ext == '.XLSX'
                              ? Icons.table_chart
                              : ext == '.DOCX'
                                  ? Icons.description
                                  : ext == '.PPTX'
                                      ? Icons.slideshow
                                      : ext == '.PDF'
                                          ? Icons.picture_as_pdf
                                          : Icons.article,
                          color: ext == '.XLSX'
                              ? Colors.green
                              : ext == '.DOCX'
                                  ? Colors.blue
                                  : ext == '.PPTX'
                                      ? Colors.orange
                                      : ext == '.PDF'
                                          ? Colors.red
                                          : Colors.grey,
                        ),
                        title: Text(
                          p.basename(file.path),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13),
                        ),
                        subtitle: Text(
                          file.path,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 18),
                          onPressed: () {
                            setState(() {
                              _selectedFiles.removeAt(index);
                            });
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],

            // Panel Tiến độ Dịch
            if (_isTranslating || _progressValue > 0) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: widget.themeProvider.glassDecoration(context),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          _statusText,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        Text(
                          '${(_progressValue * 100).toInt()}%',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.accentTeal),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: _progressValue,
                      color: AppColors.accentTeal,
                      backgroundColor: Colors.grey[800],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              ),
            ],

            // Nút bấm kích hoạt dịch
            if (!_isTranslating && _selectedFiles.isNotEmpty) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _startTranslation,
                  icon: const Icon(Icons.translate),
                  label: const Text('Bắt đầu dịch tự động tài liệu', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryTeal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 4,
                  ),
                ),
              ),
            ],

            // Lịch sử kết quả dịch
            if (_historyResults.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Text(
                'Lịch sử kết quả dịch file:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Expanded(
                flex: 4,
                child: ListView.builder(
                  itemCount: _historyResults.length,
                  itemBuilder: (context, index) {
                    final res = _historyResults[index];
                    final success = res['success'] == true;
                    
                    return Card(
                      color: success 
                          ? Colors.green.withOpacity(0.05) 
                          : Colors.red.withOpacity(0.05),
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  success ? Icons.check_circle : Icons.error,
                                  color: success ? Colors.green : Colors.red,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    res['fileName'],
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ),
                                if (success)
                                  IconButton(
                                    icon: const Icon(Icons.folder_open, size: 18, color: AppColors.accentTeal),
                                    onPressed: () => _openFolder(res['destPath']),
                                    tooltip: 'Mở thư mục chứa file',
                                  ),
                              ],
                            ),
                            const Divider(height: 12),
                            if (success) ...[
                              Text('• Đã dịch thành công: ${res['total_translated']} nội dung/ô', style: const TextStyle(fontSize: 11)),
                              Row(
                                children: [
                                  Text(
                                    '• Ô chữ Trung chưa dịch: ${res['remaining_chinese_count']}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: res['remaining_chinese_count'] > 0 ? Colors.orange : Colors.green,
                                    ),
                                  ),
                                  if (res['remaining_chinese_count'] > 0)
                                    const SizedBox(width: 4),
                                  if (res['remaining_chinese_count'] > 0)
                                    const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 12),
                                ],
                              ),
                              if (res['remaining_chinese_count'] > 0 && (res['remaining_cells'] as List).isNotEmpty) ...[
                                const SizedBox(height: 4),
                                const Text('  Tọa độ các ô bị sót chữ Trung:', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                Padding(
                                  padding: const EdgeInsets.only(left: 8.0, top: 2.0),
                                  child: Wrap(
                                    spacing: 6,
                                    children: (res['remaining_cells'] as List).map((cell) {
                                      final cellCoord = cell['coordinate'] ?? cell['location'] ?? 'N/A';
                                      return Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          '$cellCoord',
                                          style: const TextStyle(fontSize: 9, color: Colors.orangeAccent),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ],
                            ] else ...[
                              Text('• Lỗi dịch: ${res['error']}', style: const TextStyle(fontSize: 11, color: Colors.redAccent)),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// TAB 2: DỊCH CHỮ (TEXT TRANSLATOR)
// ============================================================================
class _TextTab extends StatefulWidget {
  final TranslationLogic logic;
  final ThemeProvider themeProvider;
  const _TextTab({required this.logic, required this.themeProvider, Key? key}) : super(key: key);

  @override
  State<_TextTab> createState() => _TextTabState();
}

class _TextTabState extends State<_TextTab> {
  final _inputController = TextEditingController();
  final _outputController = TextEditingController();
  bool _isLoading = false;
  String _engineUsed = '';
  String _sourceLang = 'auto';
  String _targetLang = 'vi';

  void _swapLanguages() {
    final currentSource = _sourceLang;
    final currentTarget = _targetLang;
    
    setState(() {
      if (currentSource == 'auto') {
        _sourceLang = currentTarget;
        _targetLang = 'en';
      } else {
        _sourceLang = currentTarget;
        _targetLang = currentSource;
      }
      
      final tempText = _inputController.text;
      _inputController.text = _outputController.text;
      _outputController.text = tempText;
    });
  }

  Widget _buildLanguageSelectorBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.cardDark.withOpacity(0.4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderDark, width: 0.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _sourceLang,
                items: translationLanguages.entries.map((e) {
                  return DropdownMenuItem<String>(
                    value: e.key,
                    child: Text(e.value, style: const TextStyle(fontSize: 13)),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _sourceLang = val);
                },
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.swap_horiz, color: AppColors.accentTeal),
            onPressed: _swapLanguages,
            tooltip: 'Hoán đổi ngôn ngữ',
          ),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _targetLang,
                items: translationLanguages.entries
                    .where((e) => e.key != 'auto')
                    .map((e) {
                  return DropdownMenuItem<String>(
                    value: e.key,
                    child: Text(e.value, style: const TextStyle(fontSize: 13)),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _targetLang = val);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _translate() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _isLoading = true;
      _engineUsed = widget.logic.config.engine == 'gemini' ? 'Gemini AI' : 'Google Free';
    });

    try {
      final translated = await widget.logic.translateText(
        text,
        sourceLang: _sourceLang,
        targetLang: _targetLang,
      );
      setState(() {
        _outputController.text = translated;
      });
    } catch (e) {
      setState(() {
        _outputController.text = 'Lỗi dịch thuật: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _clear() {
    _inputController.clear();
    _outputController.clear();
    setState(() {
      _engineUsed = '';
    });
  }

  void _copyOutput() {
    if (_outputController.text.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: _outputController.text));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã sao chép bản dịch vào Clipboard!'), duration: Duration(milliseconds: 1500)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dịch thuật văn bản song song',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 4),
          const Text(
            'Nhập nội dung văn bản nguồn, ứng dụng sẽ dịch tức thời sang Tiếng Việt.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          _buildLanguageSelectorBar(),
          const SizedBox(height: 20),

          // Vùng nhập xuất text song song
          Expanded(
            child: Row(
              children: [
                // Ô Nhập văn bản nguồn
                Expanded(
                  child: Container(
                    decoration: widget.themeProvider.glassDecoration(context),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.description_outlined, size: 16, color: Colors.grey),
                            const SizedBox(width: 6),
                            const Text('VĂN BẢN NGUỒN (Tự động nhận diện)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.clear, size: 14, color: Colors.grey),
                              onPressed: _clear,
                              tooltip: 'Xóa sạch',
                            ),
                          ],
                        ),
                        const Divider(height: 8),
                        Expanded(
                          child: TextField(
                            controller: _inputController,
                            maxLines: null,
                            expands: true,
                            textAlignVertical: TextAlignVertical.top,
                            decoration: const InputDecoration(
                              hintText: 'Nhập chữ tiếng Trung, Anh... cần dịch tại đây',
                              fillColor: Colors.transparent,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                            ),
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(width: 16),

                // Ô Xuất văn bản dịch
                Expanded(
                  child: Container(
                    decoration: widget.themeProvider.glassDecoration(context),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.g_translate, size: 16, color: AppColors.accentTeal),
                            const SizedBox(width: 6),
                            Text(
                              'BẢN DỊCH (${(translationLanguages[_targetLang] ?? "TIẾNG VIỆT").toUpperCase()}${_engineUsed.isNotEmpty ? " - $_engineUsed" : ""})',
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.accentTeal),
                            ),
                            const Spacer(),
                            if (_outputController.text.isNotEmpty)
                              IconButton(
                                icon: const Icon(Icons.copy, size: 14, color: AppColors.accentTeal),
                                onPressed: _copyOutput,
                                tooltip: 'Sao chép bản dịch',
                              ),
                          ],
                        ),
                        const Divider(height: 8),
                        Expanded(
                          child: _isLoading
                              ? const Center(child: CircularProgressIndicator(color: AppColors.accentTeal))
                              : TextField(
                                  controller: _outputController,
                                  maxLines: null,
                                  expands: true,
                                  readOnly: true,
                                  textAlignVertical: TextAlignVertical.top,
                                  decoration: const InputDecoration(
                                    hintText: 'Kết quả dịch sẽ xuất hiện ở đây',
                                    fillColor: Colors.transparent,
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                  ),
                                  style: const TextStyle(fontSize: 14, color: AppColors.accentTeal),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),

          // Nút bấm dịch
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _translate,
              icon: const Icon(Icons.translate),
              label: const Text('Bắt đầu dịch văn bản', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryTeal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// TAB 3: DỊCH ẢNH (IMAGE TRANSLATOR)
// ============================================================================
class _ImageTab extends StatefulWidget {
  final TranslationLogic logic;
  final ThemeProvider themeProvider;
  const _ImageTab({required this.logic, required this.themeProvider, Key? key}) : super(key: key);

  @override
  State<_ImageTab> createState() => _ImageTabState();
}

class _ImageTabState extends State<_ImageTab> {
  File? _imageFile;
  bool _isLoading = false;
  String _ocrText = '';
  String _translatedText = '';
  List<dynamic> _ocrLines = [];
  String _targetLang = 'vi';

  Future<void> _pickImage() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.image,
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _imageFile = File(result.files.single.path!);
          _ocrText = '';
          _translatedText = '';
          _ocrLines = [];
        });
      }
    } catch (e) {
      _logger.severe('Pick image error: $e');
    }
  }

  Future<void> _startImageTranslation() async {
    if (_imageFile == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final res = await widget.logic.translateImage(_imageFile!.path, targetLang: _targetLang);
      if (res['success'] == true) {
        setState(() {
          _ocrText = res['text'] ?? '';
          _translatedText = res['translated_text'] ?? '';
          _ocrLines = res['lines'] ?? [];
        });
      } else {
        Dialogs.showMessage(context, 'Lỗi', res['error'] ?? 'Nhận diện ảnh thất bại.', isError: true);
      }
    } catch (e) {
      Dialogs.showMessage(context, 'Lỗi', 'Có lỗi xảy ra: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _clearImage() {
    setState(() {
      _imageFile = null;
      _ocrText = '';
      _translatedText = '';
      _ocrLines = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return DropTarget(
      onDragDone: (details) {
        if (details.files.isNotEmpty) {
          final file = details.files.first;
          final ext = p.extension(file.path).toLowerCase();
          if (ext == '.png' || ext == '.jpg' || ext == '.jpeg' || ext == '.bmp') {
            setState(() {
              _imageFile = File(file.path);
              _ocrText = '';
              _translatedText = '';
              _ocrLines = [];
            });
          }
        }
      },
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dịch thuật Hình ảnh (Windows Native OCR)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 4),
            const Text(
              'Kéo thả hình ảnh (ảnh chụp bản vẽ, biểu mẫu...) để trích xuất chữ offline bằng Windows OCR và tự động dịch nghĩa.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Dịch sang ngôn ngữ:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.cardDark.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.borderDark, width: 0.5),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _targetLang,
                      items: translationLanguages.entries
                          .where((e) => e.key != 'auto')
                          .map((e) {
                        return DropdownMenuItem<String>(
                          value: e.key,
                          child: Text(e.value, style: const TextStyle(fontSize: 13)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _targetLang = val);
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            Expanded(
              child: Row(
                children: [
                  // Vùng hình ảnh (Bên trái)
                  Expanded(
                    flex: 1,
                    child: Container(
                      decoration: widget.themeProvider.glassDecoration(context),
                      child: _imageFile == null
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.add_photo_alternate_outlined, color: Colors.grey, size: 56),
                                  const SizedBox(height: 16),
                                  const Text('Kéo thả hoặc chọn ảnh tại đây', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  const SizedBox(height: 12),
                                  ElevatedButton(
                                    onPressed: _pickImage,
                                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryTeal, foregroundColor: Colors.white),
                                    child: const Text('Chọn ảnh'),
                                  ),
                                ],
                              ),
                            )
                          : Stack(
                              children: [
                                Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Image.file(_imageFile!, fit: BoxFit.contain),
                                  ),
                                ),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: CircleAvatar(
                                    backgroundColor: Colors.black.withOpacity(0.6),
                                    child: IconButton(
                                      icon: const Icon(Icons.clear, color: Colors.white, size: 16),
                                      onPressed: _clearImage,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  
                  const SizedBox(width: 16),

                  // Vùng văn bản dịch OCR (Bên phải)
                  Expanded(
                    flex: 1,
                    child: Container(
                      decoration: widget.themeProvider.glassDecoration(context),
                      padding: const EdgeInsets.all(16),
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator(color: AppColors.accentTeal))
                          : _translatedText.isEmpty
                              ? const Center(
                                  child: Text('Chưa có bản dịch. Bấm nút bắt đầu dịch bên dưới.', style: TextStyle(color: Colors.grey)),
                                )
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('VĂN BẢN TRÍCH XUẤT OCR:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                                    const SizedBox(height: 4),
                                    Container(
                                      height: 100,
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(color: Colors.black.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                                      child: SingleChildScrollView(
                                        child: Text(_ocrText, style: const TextStyle(fontSize: 12, fontFamily: 'Consolas')),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        const Text('BẢN DỊCH TIẾNG VIỆT:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.accentTeal)),
                                        const Spacer(),
                                        IconButton(
                                          icon: const Icon(Icons.copy, size: 14, color: AppColors.accentTeal),
                                          onPressed: () {
                                            Clipboard.setData(ClipboardData(text: _translatedText));
                                          },
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Expanded(
                                      child: Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(color: AppColors.primaryTeal.withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
                                        child: SingleChildScrollView(
                                          child: Text(_translatedText, style: const TextStyle(fontSize: 13, color: AppColors.accentTeal, fontWeight: FontWeight.w500)),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),

            // Nút bấm bắt đầu dịch ảnh
            if (_imageFile != null && !_isLoading)
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _startImageTranslation,
                  icon: const Icon(Icons.photo_filter),
                  label: const Text('Bắt đầu quét ảnh & dịch nghĩa', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryTeal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// TAB 4: CẤU HÌNH & TỪ ĐIỂN (SETTINGS & DICTIONARY)
// ============================================================================
class _SettingsTab extends StatefulWidget {
  final TranslationLogic logic;
  final ThemeProvider themeProvider;
  const _SettingsTab({required this.logic, required this.themeProvider, Key? key}) : super(key: key);

  @override
  State<_SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<_SettingsTab> {
  final _keyCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();
  String _selectedEngine = 'google';
  bool _enableTransparency = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _keyCtrl.text = widget.logic.config.apiKey;
    _selectedEngine = widget.logic.config.engine;
    _enableTransparency = widget.logic.config.enableTransparency;
  }

  void _saveSettings() {
    widget.logic.updateConfig(
      apiKey: _keyCtrl.text.trim(),
      engine: _selectedEngine,
      enableTransparency: _enableTransparency,
    );
    widget.themeProvider.updateTheme(
      widget.themeProvider.themeMode,
      _enableTransparency,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã lưu cấu hình thành công!'), duration: Duration(milliseconds: 1500)),
    );
  }

  Future<void> _addDictWord() async {
    final res = await Dialogs.showDictionaryEditDialog(context: context);
    if (res != null) {
      await widget.logic.addDictionaryEntry(res['key']!, res['value']!);
    }
  }

  Future<void> _editDictWord(String key, String value) async {
    final res = await Dialogs.showDictionaryEditDialog(
      context: context,
      initialKey: key,
      initialValue: value,
    );
    if (res != null) {
      await widget.logic.addDictionaryEntry(key, res['value']!);
    }
  }

  Future<void> _deleteDictWord(String key) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa từ khóa "$key" khỏi từ điển?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Hủy')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Xóa', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      await widget.logic.removeDictionaryEntry(key);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Lọc từ điển theo tìm kiếm
    final filteredDict = widget.logic.dictionary.entries.where((entry) {
      final q = _searchQuery.toLowerCase().trim();
      if (q.isEmpty) return true;
      return entry.key.toLowerCase().contains(q) || entry.value.toLowerCase().contains(q);
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bên trái: Cài đặt dịch (Engine & Key)
          Expanded(
            flex: 2,
            child: Container(
              decoration: widget.themeProvider.glassDecoration(context),
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Cấu hình Bộ dịch (Engine Settings)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.accentTeal)),
                    const Divider(height: 20),
                    
                    // Chọn Engine
                    const Text('Bộ công cụ dịch thuật:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedEngine,
                      decoration: const InputDecoration(),
                      items: const [
                        DropdownMenuItem(value: 'google', child: Text('Google Translate Free (Nokey)')),
                        DropdownMenuItem(value: 'gemini', child: Text('Google Gemini API (Cần Key)')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedEngine = val);
                      },
                    ),
                    const SizedBox(height: 16),

                    // Gemini API Key
                    if (_selectedEngine == 'gemini') ...[
                      const Text('Gemini API Key:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _keyCtrl,
                        obscureText: true,
                        decoration: const InputDecoration(
                          hintText: 'Nhập API Key AI Gemini của bạn tại đây',
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Chế độ kính mờ Acrylic
                    const Text('Thiết lập giao diện nâng cao:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    SwitchListTile(
                      title: const Text('Hiệu ứng kính mờ (Transparency Windows 11)', style: TextStyle(fontSize: 12)),
                      activeColor: AppColors.accentTeal,
                      value: _enableTransparency,
                      onChanged: (val) {
                        setState(() => _enableTransparency = val);
                      },
                      contentPadding: EdgeInsets.zero,
                    ),

                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 42,
                      child: ElevatedButton.icon(
                        onPressed: _saveSettings,
                        icon: const Icon(Icons.save_outlined),
                        label: const Text('Lưu cấu hình', style: TextStyle(fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryTeal, foregroundColor: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Bên phải: Trình quản lý từ điển
          Expanded(
            flex: 3,
            child: Container(
              decoration: widget.themeProvider.glassDecoration(context),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('Từ điển thông minh SOP', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.accentTeal)),
                      const Spacer(),
                      ElevatedButton.icon(
                        onPressed: _addDictWord,
                        icon: const Icon(Icons.add, size: 14),
                        label: const Text('Thêm từ', style: TextStyle(fontSize: 11)),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryTeal, foregroundColor: Colors.white),
                      ),
                    ],
                  ),
                  const Divider(height: 20),

                  // Thanh tìm kiếm từ khóa
                  TextField(
                    controller: _searchCtrl,
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm từ khóa trong từ điển...',
                      prefixIcon: const Icon(Icons.search, size: 16),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                      fillColor: Colors.black.withOpacity(0.1),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Danh sách các từ
                  Expanded(
                    child: filteredDict.isEmpty
                        ? const Center(child: Text('Không tìm thấy từ khóa nào', style: TextStyle(color: Colors.grey, fontSize: 12)))
                        : ListView.separated(
                            itemCount: filteredDict.length,
                            separatorBuilder: (context, index) => const Divider(height: 1, color: Colors.grey),
                            itemBuilder: (context, index) {
                              final entry = filteredDict[index];
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6.0),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        entry.key,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.amberAccent),
                                      ),
                                    ),
                                    const Icon(Icons.arrow_forward, size: 12, color: Colors.grey),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        entry.value,
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, size: 16, color: Colors.blueAccent),
                                      onPressed: () => _editDictWord(entry.key, entry.value),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_forever_outlined, size: 16, color: Colors.redAccent),
                                      onPressed: () => _deleteDictWord(entry.key),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
