import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_assesment_1/features/home/provider/category_provider.dart';
import 'package:flutter_assesment_1/features/home/models/product_model.dart'; // Using generic Product model file which likely has Category class

class CreateCategoryPage extends ConsumerStatefulWidget {
  final Category? categoryToEdit;

  const CreateCategoryPage({super.key, this.categoryToEdit});

  @override
  ConsumerState<CreateCategoryPage> createState() => _CreateCategoryPageState();
}

class _CreateCategoryPageState extends ConsumerState<CreateCategoryPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  String? _currentImageUrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.categoryToEdit != null) {
      _nameController.text = widget.categoryToEdit!.name;
      _currentImageUrl = widget.categoryToEdit!.image;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        // Clear remote URL if we picked a local file
        // _currentImageUrl = null; // Optional: depending on UX, maybe keep it as fallback?
        // Usually local file overrides remote url for display
      });
    }
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      // Validation: Must have image (either new local file or existing remote url)
      if (_imageFile == null && _currentImageUrl == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Please select an image')));
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        final notifier = ref.read(categoryProvider.notifier);
        String imageUrl = _currentImageUrl ?? '';

        // Upload new image if selected
        if (_imageFile != null) {
          final uploadedUrl = await notifier.uploadImage(_imageFile!.path);
          if (uploadedUrl != null) {
            imageUrl = uploadedUrl;
          } else {
            throw Exception('Image upload failed');
          }
        }

        if (widget.categoryToEdit != null) {
          // Update
          await notifier.updateCategory(
            id: widget.categoryToEdit!.id,
            name: _nameController.text.trim(),
            image: imageUrl,
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Category updated successfully!')),
            );
          }
        } else {
          // Create
          await notifier.createCategory(
            name: _nameController.text.trim(),
            image: imageUrl,
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Category created successfully!')),
            );
          }
        }

        if (mounted) {
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed: ${e.toString().replaceAll('Exception:', '').trim()}',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.categoryToEdit != null ? 'Edit Category' : 'Create Category',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[400]!),
                    image: _imageDecoration(),
                  ),
                  child: (_imageFile == null && _currentImageUrl == null)
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_photo_alternate,
                              size: 50,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Tap to select image',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Category Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        widget.categoryToEdit != null
                            ? 'Update Category'
                            : 'Create Category',
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  DecorationImage? _imageDecoration() {
    if (_imageFile != null) {
      return DecorationImage(image: FileImage(_imageFile!), fit: BoxFit.cover);
    }
    if (_currentImageUrl != null) {
      return DecorationImage(
        image: NetworkImage(_currentImageUrl!),
        fit: BoxFit.cover,
      );
    }
    return null;
  }
}
