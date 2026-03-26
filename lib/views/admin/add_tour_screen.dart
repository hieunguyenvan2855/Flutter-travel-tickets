import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../services/database_service.dart';
import '../../services/cloudinary_service.dart';
import '../../models/tour_model.dart';

class AddTourScreen extends StatefulWidget {
  const AddTourScreen({super.key});

  @override
  State<AddTourScreen> createState() => _AddTourScreenState();
}

class _AddTourScreenState extends State<AddTourScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  final _slotsController = TextEditingController();
  final _locationController = TextEditingController();
  
  File? _imageFile;
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  Future<void> _saveTour() async {
    if (!_formKey.currentState!.validate() || _imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng điền đủ thông tin và chọn ảnh')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Upload ảnh lên Cloudinary
      final cloudinary = CloudinaryService();
      String? imageUrl = await cloudinary.uploadImage(_imageFile!.path);

      if (imageUrl != null) {
        // 2. Lưu thông tin Tour vào Firestore
        final tour = Tour(
          id: '', // Firestore sẽ tự tạo ID
          title: _titleController.text,
          description: _descController.text,
          price: double.parse(_priceController.text),
          totalSlots: int.parse(_slotsController.text),
          availableSlots: int.parse(_slotsController.text),
          location: _locationController.text,
          imageUrl: imageUrl,
        );

        await Provider.of<DatabaseService>(context, listen: false).addTour(tour);
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thêm Tour Mới')),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      height: 200, width: double.infinity,
                      color: Colors.grey[200],
                      child: _imageFile == null 
                        ? const Icon(Icons.add_a_photo, size: 50) 
                        : Image.file(_imageFile!, fit: BoxFit.cover),
                    ),
                  ),
                  TextFormField(controller: _titleController, decoration: const InputDecoration(labelText: 'Tên Tour')),
                  TextFormField(controller: _priceController, decoration: const InputDecoration(labelText: 'Giá vé'), keyboardType: TextInputType.number),
                  TextFormField(controller: _slotsController, decoration: const InputDecoration(labelText: 'Số lượng chỗ'), keyboardType: TextInputType.number),
                  TextFormField(controller: _locationController, decoration: const InputDecoration(labelText: 'Địa điểm')),
                  TextFormField(controller: _descController, decoration: const InputDecoration(labelText: 'Mô tả'), maxLines: 3),
                  const SizedBox(height: 20),
                  ElevatedButton(onPressed: _saveTour, child: const Text('Lưu Tour')),
                ],
              ),
            ),
          ),
    );
  }
}
