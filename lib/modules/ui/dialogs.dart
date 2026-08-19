// lib/modules/ui/dialogs.dart
import 'package:flutter/material.dart';
import 'styles.dart';

class Dialogs {
  /// Hiển thị Dialog thêm/sửa từ khóa vào từ điển
  static Future<Map<String, String>?> showDictionaryEditDialog({
    required BuildContext context,
    String? initialKey,
    String? initialValue,
  }) async {
    final keyController = TextEditingController(text: initialKey);
    final valController = TextEditingController(text: initialValue);
    final formKey = GlobalKey<FormState>();

    return showDialog<Map<String, String>>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            initialKey == null ? 'Thêm từ khóa mới' : 'Chỉnh sửa từ khóa',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: keyController,
                  decoration: const InputDecoration(
                    labelText: 'Từ khóa gốc (tiếng Trung/Anh)',
                    hintText: 'Ví dụ: 站位',
                  ),
                  enabled: initialKey == null, // Không cho sửa key gốc khi đang edit
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập từ khóa gốc';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: valController,
                  decoration: const InputDecoration(
                    labelText: 'Bản dịch nghĩa (tiếng Việt)',
                    hintText: 'Ví dụ: Vị trí thao tác',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập bản dịch nghĩa';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.of(context).pop({
                    'key': keyController.text.trim(),
                    'value': valController.text.trim(),
                  });
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryTeal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Lưu'),
            ),
          ],
        );
      },
    );
  }

  /// Hiển thị Dialog cấu hình vá lỗi theo tọa độ ô Excel
  static Future<Map<String, String>?> showExcelPatchDialog({
    required BuildContext context,
    String? initialSheet,
    String? initialCell,
    String? initialValue,
  }) async {
    final sheetController = TextEditingController(text: initialSheet);
    final cellController = TextEditingController(text: initialCell);
    final valController = TextEditingController(text: initialValue);
    final formKey = GlobalKey<FormState>();

    return showDialog<Map<String, String>>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            initialCell == null ? 'Vá lỗi tọa độ ô Excel' : 'Sửa lỗi tọa độ ô Excel',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: sheetController,
                    decoration: const InputDecoration(
                      labelText: 'Tên Sheet',
                      hintText: 'Ví dụ: Sheet1 hoặc SOP-站位',
                    ),
                    enabled: initialCell == null,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Vui lòng nhập tên Sheet';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: cellController,
                    decoration: const InputDecoration(
                      labelText: 'Tọa độ ô',
                      hintText: 'Ví dụ: B6, C12, A1',
                    ),
                    enabled: initialCell == null,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Vui lòng nhập tọa độ ô';
                      }
                      final reg = RegExp(r'^[a-zA-Z]+\d+$');
                      if (!reg.hasMatch(value.trim())) {
                        return 'Tọa độ ô không hợp lệ (ví dụ: B6)';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: valController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Nội dung dịch chỉ định',
                      hintText: 'Nhập nội dung dịch hoàn chỉnh mong muốn ghi đè lên ô này',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Vui lòng nhập nội dung chỉ định';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.of(context).pop({
                    'sheet': sheetController.text.trim(),
                    'cell': cellController.text.trim().toUpperCase(),
                    'value': valController.text.trim(),
                  });
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.sapphireBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Lưu'),
            ),
          ],
        );
      },
    );
  }

  /// Dialog hiển thị lỗi hoặc tiến độ
  static void showMessage(BuildContext context, String title, String message, {bool isError = false}) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                isError ? Icons.error_outline : Icons.info_outline,
                color: isError ? Colors.red : AppColors.primaryTeal,
              ),
              const SizedBox(width: 8),
              Text(title),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
