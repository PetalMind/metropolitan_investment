import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';

/// ⌨️ Keyboard shortcuts service for email editor
/// Provides productivity shortcuts for common email editing operations
class EmailKeyboardShortcuts {
  /// Get keyboard shortcuts map for email editor
  static Map<ShortcutActivator, Intent> getShortcuts() {
    return {
      // Save draft (Ctrl+S)
      const SingleActivator(LogicalKeyboardKey.keyS, control: true):
          const SaveIntent(),

      // Send email (Ctrl+Enter)
      const SingleActivator(LogicalKeyboardKey.enter, control: true):
          const SendIntent(),

      // Close editor (Escape)
      const SingleActivator(LogicalKeyboardKey.escape): const CloseIntent(),

      // Text formatting shortcuts
      const SingleActivator(LogicalKeyboardKey.keyB, control: true):
          const BoldIntent(),
      const SingleActivator(LogicalKeyboardKey.keyI, control: true):
          const ItalicIntent(),
      const SingleActivator(LogicalKeyboardKey.keyU, control: true):
          const UnderlineIntent(),

      // Undo/Redo
      const SingleActivator(LogicalKeyboardKey.keyZ, control: true):
          const UndoIntent(),
      const SingleActivator(LogicalKeyboardKey.keyY, control: true):
          const RedoIntent(),
      const SingleActivator(
        LogicalKeyboardKey.keyZ,
        control: true,
        shift: true,
      ): const RedoIntent(),
    };
  }

  /// Toggle text attribute (bold, italic, underline)
  static void toggleAttribute(QuillController controller, Attribute attribute) {
    final selection = controller.selection;
    if (selection.isValid) {
      final currentAttributes = controller.getSelectionStyle();
      final isActive = currentAttributes.attributes.containsKey(attribute.key);

      if (isActive) {
        controller.formatSelection(Attribute.clone(attribute, null));
      } else {
        controller.formatSelection(attribute);
      }
    }
  }

  /// Create shortcuts widget wrapper
  static Widget createShortcutsWrapper({
    required Widget child,
    required VoidCallback onSave,
    required VoidCallback onSend,
    required VoidCallback onClose,
    QuillController? quillController,
  }) {
    return Shortcuts(
      shortcuts: getShortcuts(),
      child: Actions(
        actions: _getActions(
          onSave: onSave,
          onSend: onSend,
          onClose: onClose,
          quillController: quillController,
        ),
        child: Focus(autofocus: true, child: child),
      ),
    );
  }

  /// Get actions map for shortcuts
  static Map<Type, Action<Intent>> _getActions({
    required VoidCallback onSave,
    required VoidCallback onSend,
    required VoidCallback onClose,
    QuillController? quillController,
  }) {
    return {
      SaveIntent: CallbackAction<SaveIntent>(onInvoke: (intent) => onSave()),
      SendIntent: CallbackAction<SendIntent>(onInvoke: (intent) => onSend()),
      CloseIntent: CallbackAction<CloseIntent>(onInvoke: (intent) => onClose()),
      if (quillController != null)
        ..._getTextFormattingActions(quillController),
    };
  }

  /// Get text formatting actions
  static Map<Type, Action<Intent>> _getTextFormattingActions(
    QuillController quillController,
  ) {
    return {
      BoldIntent: CallbackAction<BoldIntent>(
        onInvoke: (intent) {
          toggleAttribute(quillController, Attribute.bold);
          return null;
        },
      ),
      ItalicIntent: CallbackAction<ItalicIntent>(
        onInvoke: (intent) {
          toggleAttribute(quillController, Attribute.italic);
          return null;
        },
      ),
      UnderlineIntent: CallbackAction<UnderlineIntent>(
        onInvoke: (intent) {
          toggleAttribute(quillController, Attribute.underline);
          return null;
        },
      ),
      UndoIntent: CallbackAction<UndoIntent>(
        onInvoke: (intent) {
          if (quillController.hasUndo) {
            quillController.undo();
          }
          return null;
        },
      ),
      RedoIntent: CallbackAction<RedoIntent>(
        onInvoke: (intent) {
          if (quillController.hasRedo) {
            quillController.redo();
          }
          return null;
        },
      ),
    };
  }

  /// Get shortcuts help text for display
  static Map<String, String> getShortcutsHelp() {
    return {
      'Save Draft': 'Ctrl+S',
      'Send Email': 'Ctrl+Enter',
      'Close Editor': 'Escape',
      'Bold Text': 'Ctrl+B',
      'Italic Text': 'Ctrl+I',
      'Underline Text': 'Ctrl+U',
      'Undo': 'Ctrl+Z',
      'Redo': 'Ctrl+Y or Ctrl+Shift+Z',
    };
  }

  /// Show shortcuts help dialog
  static void showShortcutsHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.keyboard, color: Colors.blue),
            SizedBox(width: 8),
            Text('Keyboard Shortcuts'),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: getShortcutsHelp().entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(entry.key),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.grey[400]!),
                      ),
                      child: Text(
                        entry.value,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

// Intent classes for shortcuts
class SaveIntent extends Intent {
  const SaveIntent();
}

class SendIntent extends Intent {
  const SendIntent();
}

class CloseIntent extends Intent {
  const CloseIntent();
}

class BoldIntent extends Intent {
  const BoldIntent();
}

class ItalicIntent extends Intent {
  const ItalicIntent();
}

class UnderlineIntent extends Intent {
  const UnderlineIntent();
}

class UndoIntent extends Intent {
  const UndoIntent();
}

class RedoIntent extends Intent {
  const RedoIntent();
}
