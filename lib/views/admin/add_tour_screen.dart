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
  final _scheduleController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();

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
        GeoPoint? geoPoint;
        if (_latController.text.isNotEmpty && _lngController.text.isNotEmpty) {
          geoPoint = GeoPoint(double.parse(_latController.text), double.parse(_lngController.text));
        }

        final tour = Tour(
          id: '',
          title: _titleController.text,
          description: _descController.text,
          price: double.parse(_priceController.text),
          totalSlots: int.parse(_slotsController.text),
          availableSlots: int.parse(_slotsController.text),
          location: _locationController.text,
          imageUrl: imageUrl,
          schedule: _scheduleController.text,
          geoPoint: geoPoint,
          highlights: ['Mới cập nhật', 'Hấp dẫn'], // Mặc định
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
      appBar: AppBar(title: const Text('Thêm Tour Du Lịch Mới')),
      body: _isLoading 
        ? const Center(child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [CircularProgressIndicator(), SizedBox(height: 16), Text('Đang đăng tải tour...')]))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      height: 200, width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.grey[400]!)
                      ),
                      child: _imageFile == null 
                        ? const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_a_photo, size: 50), Text('Bấm để chọn ảnh đại diện')])
                        : ClipRRect(borderRadius: BorderRadius.circular(15), child: Image.file(_imageFile!, fit: BoxFit.cover)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildLabel('Thông tin cơ bản'),
                  TextFormField(controller: _titleController, decoration: const InputDecoration(labelText: 'Tên Tour', prefixIcon: Icon(Icons.title))),
                  Row(
                    children: [
                      Expanded(child: TextFormField(controller: _priceController, decoration: const InputDecoration(labelText: 'Giá vé (đ)', prefixIcon: Icon(Icons.money)), keyboardType: TextInputType.number)),
                      const SizedBox(width: 15),
                      Expanded(child: TextFormField(controller: _slotsController, decoration: const InputDecoration(labelText: 'Số chỗ', prefixIcon: Icon(Icons.people)), keyboardType: TextInputType.number)),
                    ],
                  ),
                  TextFormField(controller: _locationController, decoration: const InputDecoration(labelText: 'Địa điểm', prefixIcon: Icon(Icons.location_on))),
                  const SizedBox(height: 20),
                  _buildLabel('Mô tả & Lịch trình'),
                  TextFormField(controller: _descController, decoration: const InputDecoration(labelText: 'Mô tả ngắn'), maxLines: 2),
                  TextFormField(controller: _scheduleController, decoration: const InputDecoration(labelText: 'Lịch trình chi tiết'), maxLines: 4),
                  const SizedBox(height: 20),
                  _buildLabel('Tọa độ GPS (Tùy chọn)'),
                  Row(
                    children: [
                      Expanded(child: TextFormField(controller: _latController, decoration: const InputDecoration(labelText: 'Vĩ độ (Lat)'), keyboardType: TextInputType.number)),
                      const SizedBox(width: 15),
                      Expanded(child: TextFormField(controller: _lngController, decoration: const InputDecoration(labelText: 'Kinh độ (Lng)'), keyboardType: TextInputType.number)),
                    ],
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[900], shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                      onPressed: _saveTour,
                      child: const Text('LƯU VÀ ĐĂNG TOUR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)));
  }
}
