import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import '../../models/email_attachment.dart';
import '../../services/email_attachment_service.dart';
import '../../theme/app_theme.dart';

/// 📎 WIDGET ZARZĄDZANIA ZAŁĄCZNIKAMI EMAIL
/// 
/// Umożliwia dodawanie, podgląd i usuwanie załączników w email editorze.
class AttachmentManagerWidget extends StatefulWidget {
  final List<EmailAttachment> initialAttachments;
  final Function(List<EmailAttachment>) onAttachmentsChanged;
  final String userId;
  final bool enabled;
  final bool showUploadProgress;

  const AttachmentManagerWidget({
    super.key,
    required this.initialAttachments,
    required this.onAttachmentsChanged,
    required this.userId,
    this.enabled = true,
    this.showUploadProgress = true,
  });

  @override
  State<AttachmentManagerWidget> createState() => _AttachmentManagerWidgetState();
}

class _AttachmentManagerWidgetState extends State<AttachmentManagerWidget>
    with TickerProviderStateMixin {
  final EmailAttachmentService _attachmentService = EmailAttachmentService();
  
  List<EmailAttachment> _attachments = [];
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String? _uploadError;
  
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _attachments = List.from(widget.initialAttachments);
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_fadeController);
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadFiles() async {
    if (!widget.enabled) return;
    
    try {
      setState(() {
        _isUploading = true;
        _uploadProgress = 0.0;
        _uploadError = null;
      });

      // Pick files
      final files = await _attachmentService.pickFiles(
        allowMultiple: true,
        allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'jpg', 'jpeg', 'png', 'txt'],
      );

      if (files == null || files.isEmpty) {
        setState(() {
          _isUploading = false;
        });
        return;
      }

      // Validate files
      final validFiles = <PlatformFile>[];
      for (final file in files) {
        final validation = _attachmentService.validateFile(file);
        if (validation['isValid']) {
          validFiles.add(file);
        } else {
          final issues = validation['issues'] as List<String>;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Błąd pliku ${file.name}: ${issues.join(', ')}'),
              backgroundColor: AppTheme.errorPrimary,
            ),
          );
        }
      }

      if (validFiles.isEmpty) {
        setState(() {
          _isUploading = false;
        });
        return;
      }

      // Upload files
      final newAttachments = <EmailAttachment>[];
      for (int i = 0; i < validFiles.length; i++) {
        final file = validFiles[i];
        
        final attachment = await _attachmentService.uploadAndCreateAttachment(
          file: file,
          userId: widget.userId,
          onProgress: (progress) {
            if (widget.showUploadProgress) {
              setState(() {
                _uploadProgress = (i + progress) / validFiles.length;
              });
            }
          },
        );

        if (attachment != null) {
          newAttachments.add(attachment);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Nie udało się przesłać pliku: ${file.name}'),
              backgroundColor: AppTheme.errorPrimary,
            ),
          );
        }
      }

      // Update attachments list
      setState(() {
        _attachments.addAll(newAttachments);
        _isUploading = false;
        _uploadProgress = 0.0;
      });

      widget.onAttachmentsChanged(_attachments);
      HapticFeedback.mediumImpact();

    } catch (e) {
      setState(() {
        _isUploading = false;
        _uploadError = 'Błąd podczas przesyłania: $e';
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_uploadError!),
          backgroundColor: AppTheme.errorPrimary,
        ),
      );
    }
  }

  Future<void> _removeAttachment(EmailAttachment attachment) async {
    if (!widget.enabled) return;

    try {
      // Remove from service if it has an ID (was uploaded)
      if (attachment.id.isNotEmpty) {
        await _attachmentService.deleteAttachment(attachment.id);
      }

      // Remove from local list
      setState(() {
        _attachments.remove(attachment);
      });

      widget.onAttachmentsChanged(_attachments);
      HapticFeedback.lightImpact();

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Nie udało się usunąć załącznika: $e'),
          backgroundColor: AppTheme.errorPrimary,
        ),
      );
    }
  }

  String _getTotalSize() {
    final totalBytes = _attachments.fold<int>(0, (sum, attachment) => sum + attachment.size);
    if (totalBytes < 1024) {
      return '$totalBytes B';
    } else if (totalBytes < 1024 * 1024) {
      return '${(totalBytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(totalBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.backgroundSecondary.withOpacity(0.9),
                AppTheme.backgroundPrimary.withOpacity(0.7),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.borderPrimary.withOpacity(0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(),
              
              // Upload Progress
              if (_isUploading && widget.showUploadProgress)
                _buildUploadProgress(),
              
              // Attachments List
              if (_attachments.isNotEmpty)
                _buildAttachmentsList(),
              
              // Add Button
              if (widget.enabled)
                _buildAddButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.secondaryGold.withOpacity(0.1),
            AppTheme.primaryColor.withOpacity(0.1),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: AppTheme.borderPrimary.withOpacity(0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.attach_file,
            color: AppTheme.secondaryGold,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Załączniki (${_attachments.length})',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (_attachments.isNotEmpty)
                  Text(
                    'Łączny rozmiar: ${_getTotalSize()}',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadProgress() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  value: _uploadProgress,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Przesyłanie... ${(_uploadProgress * 100).toInt()}%',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: _uploadProgress,
            backgroundColor: AppTheme.backgroundSecondary,
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.secondaryGold),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentsList() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      child: ListView.builder(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _attachments.length,
        itemBuilder: (context, index) {
          final attachment = _attachments[index];
          return _buildAttachmentItem(attachment);
        },
      ),
    );
  }

  Widget _buildAttachmentItem(EmailAttachment attachment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundSecondary.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.borderPrimary.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          // File icon
          Text(
            attachment.fileIcon,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(width: 8),
          
          // File info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attachment.originalName,
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  attachment.formattedSize,
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          
          // Remove button
          if (widget.enabled)
            IconButton(
              onPressed: () => _removeAttachment(attachment),
              icon: Icon(
                Icons.close,
                color: AppTheme.errorPrimary,
                size: 16,
              ),
              constraints: const BoxConstraints(
                minWidth: 24,
                minHeight: 24,
              ),
              padding: EdgeInsets.zero,
              tooltip: 'Usuń załącznik',
            ),
        ],
      ),
    );
  }

  Widget _buildAddButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: _isUploading ? null : _pickAndUploadFiles,
          icon: Icon(
            Icons.add,
            size: 16,
            color: widget.enabled ? AppTheme.secondaryGold : AppTheme.textSecondary,
          ),
          label: Text(
            _isUploading ? 'Przesyłanie...' : 'Dodaj załączniki',
            style: TextStyle(
              color: widget.enabled ? AppTheme.secondaryGold : AppTheme.textSecondary,
            ),
          ),
          style: OutlinedButton.styleFrom(
            side: BorderSide(
              color: widget.enabled 
                  ? AppTheme.secondaryGold.withOpacity(0.5)
                  : AppTheme.borderPrimary.withOpacity(0.3),
            ),
            backgroundColor: AppTheme.secondaryGold.withOpacity(0.05),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
    );
  }
}