import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../models/tour_model.dart';
import '../../services/database_service.dart';
import '../../services/cloudinary_service.dart';

class EditTourScreen extends StatefulWidget {
  final Tour tour;
  const EditTourScreen({super.key, required this.tour});

  @override
  State<EditTourScreen> createState() => _EditTourScreenState();
}

class _EditTourScreenState extends State<EditTourScreen> {
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TextEditingController _priceController;
  late TextEditingController _slotsController;
  
  File? _imageFile;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.tour.title);
    _descController = TextEditingController(text: widget.tour.description);
    _priceController = TextEditingController(text: widget.tour.price.toInt().toString());
    _slotsController = TextEditingController(text: widget.tour.totalSlots.toString());
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked != null) setState(() => _imageFile = File(picked.path));
  }

  Future<void> _saveChanges() async {
    setState(() => _isLoading = true);
    final dbService = Provider.of<DatabaseService>(context, listen: false);
    String currentImageUrl = widget.tour.imageUrl;

    try {
      if (_imageFile != null) {
        final cloudinary = CloudinaryService();
        String? newUrl = await cloudinary.uploadImage(_imageFile!.path);
        if (newUrl != null) currentImageUrl = newUrl;
      }

      await dbService.updateTour(widget.tour.id, {
        'title': _titleController.text,
        'description': _descController.text,
        'price': double.parse(_priceController.text),
        'totalSlots': int.parse(_slotsController.text),
        'availableSlots': int.parse(_slotsController.text),
        'imageUrl': currentImageUrl,
        // Giữ nguyên các thông tin chi tiết khác
        'highlights': widget.tour.highlights,
        'scheduleItems': widget.tour.scheduleItems.map((e) => e.toMap()).toList(),
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cập nhật tour thành công!'), backgroundColor: Colors.green));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Thiết lập Tour', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('HÌNH ẢNH TOUR', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 200, width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[100], borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.blue[900]!.withOpacity(0.2)),
                    ),
                    child: _imageFile != null 
                      ? ClipRRect(borderRadius: BorderRadius.circular(15), child: Image.file(_imageFile!, fit: BoxFit.cover))
                      : ClipRRect(borderRadius: BorderRadius.circular(15), child: Image.network(widget.tour.imageUrl, fit: BoxFit.cover, errorBuilder: (c,e,s) => const Icon(Icons.image, size: 50))),
                  ),
                ),
                const SizedBox(height: 30),
                _buildField(_titleController, 'Tên Tour', Icons.title),
                const SizedBox(height: 15),
                _buildField(_priceController, 'Giá vé (đ)', Icons.payments, isNumber: true),
                const SizedBox(height: 15),
                _buildField(_slotsController, 'Số chỗ trống', Icons.people, isNumber: true),
                const SizedBox(height: 15),
                _buildField(_descController, 'Mô tả chi tiết', Icons.description, maxLines: 5),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[900], shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                    onPressed: _saveChanges, 
                    child: const Text('LƯU TOÀN BỘ THAY ĐỔI', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
    );
  }

  Widget _buildField(TextEditingController controller, String label, IconData icon, {bool isNumber = false, int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: isNumber ? TextInputType.number : TextInputType.multiline,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.blue[900]),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey[50],
      ),
    );
  }
}
