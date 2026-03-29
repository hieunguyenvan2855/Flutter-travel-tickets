import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  final _scheduleController = TextEditingController(); // Đây là nội dung lịch trình Admin nhập vào

  File? _imageFile;
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 70);
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
      final cloudinary = CloudinaryService();
      String? imageUrl = await cloudinary.uploadImage(_imageFile!.path);

      if (imageUrl != null) {
        // Chuyển đổi nội dung schedule từ text sang List<ScheduleItem> đơn giản
        // Mặc định cho toàn bộ nội dung vào Ngày 1
        final scheduleItems = [
          ScheduleItem(title: 'Lịch trình chi tiết', content: _scheduleController.text)
        ];

        final tour = Tour(
          id: '',
          title: _titleController.text,
          description: _descController.text,
          price: double.parse(_priceController.text),
          totalSlots: int.parse(_slotsController.text),
          availableSlots: int.parse(_slotsController.text),
          location: _locationController.text,
          imageUrl: imageUrl,
          scheduleItems: scheduleItems, // Cập nhật để khớp với Model mới
          highlights: ['Mới cập nhật', 'Tour hấp dẫn'],
        );

        await Provider.of<DatabaseService>(context, listen: false).addTour(tour);
        if (context.mounted) Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thêm Tour Mới')),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20),
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
                  TextFormField(controller: _slotsController, decoration: const InputDecoration(labelText: 'Số chỗ'), keyboardType: TextInputType.number),
                  TextFormField(controller: _locationController, decoration: const InputDecoration(labelText: 'Địa điểm')),
                  TextFormField(controller: _descController, decoration: const InputDecoration(labelText: 'Mô tả ngắn'), maxLines: 2),
                  TextFormField(controller: _scheduleController, decoration: const InputDecoration(labelText: 'Nội dung lịch trình'), maxLines: 5),
                  const SizedBox(height: 30),
                  ElevatedButton(onPressed: _saveTour, child: const Text('LƯU TOUR')),
                ],
              ),
            ),
          ),
    );
  }
}
