// ---------------- IMPORTS ----------------
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../viewmodels/auth_viewmodel.dart';
import '../../models/user_model.dart'; // Asegúrate que exista este archivo
import '../../utils/app_colors.dart';

// ---------------- WIDGET PRINCIPAL ----------------
class CreateReportScreen extends StatefulWidget {
  const CreateReportScreen({super.key});

  @override
  State<CreateReportScreen> createState() => _CreateReportScreenState();
}

class _CreateReportScreenState extends State<CreateReportScreen>
    with SingleTickerProviderStateMixin {

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();

  String _selectedIssueType = 'Poste dañado';
  String _selectedPriority = 'Alta';
  List<String> _selectedPhotos = [];

  final List<String> _issueTypes = [
    'Poste dañado',
    'Bache en vía',
    'Alumbrado público',
    'Recolección de basura',
    'Semáforo dañado',
    'Fuga de agua',
    'Limpieza de áreas verdes',
    'Otro'
  ];

  final List<String> _priorityLevels = ['Alta', 'Media', 'Baja'];

  @override
  void initState() {
    super.initState();

    // --------- ANIMACIONES ----------
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<double>(begin: 50, end: 0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();

    // Valores de ejemplo
    _descriptionController.text =
        'Poste de luz inclinado en la esquina, parece que va a caerse.';
    _selectedPhotos = ['Foto1.jpg', 'Foto2.jpg'];
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context);
    final user = authViewModel.currentUser;

    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: _buildAppBar(),
      body: _buildAnimatedBody(),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: FadeTransition(
        opacity: _fadeAnimation,
        child: const Text(
          "EDITAR REPORTE",
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      backgroundColor: AppColors.primaryBlue,
      foregroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildAnimatedBody() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) =>
          Opacity(
            opacity: _fadeAnimation.value,
            child: Transform.translate(
              offset: Offset(0, _slideAnimation.value),
              child: _buildBody(),
            ),
          ),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildReportHeader(),
            const SizedBox(height: 24),
            _buildIssueType(),
            const SizedBox(height: 24),
            _buildDescription(),
            const SizedBox(height: 24),
            const Divider(),
            _buildLocation(),
            const SizedBox(height: 24),
            _buildPhotos(),
            const SizedBox(height: 24),
            _buildPriority(),
            const SizedBox(height: 32),
            _buildButtons(),
          ],
        ),
      ),
    );
  }

  // ---------------- SECCIONES ----------------

  Widget _buildReportHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.chiclayoOrange,
            AppColors.chiclayoOrange.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("#1235",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white)),
          SizedBox(height: 4),
          Text("EDITAR REPORTE",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildIssueType() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Tipo de incidencia:",
            style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: _boxDecoration(),
          child: DropdownButtonHideUnderline(
            child: DropdownButton(
              value: _selectedIssueType,
              isExpanded: true,
              items: _issueTypes.map((i) => DropdownMenuItem(
                value: i,
                child: Text(i),
              )).toList(),
              onChanged: (v) => setState(() => _selectedIssueType = v!),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDescription() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Descripción:", style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        Container(
          decoration: _boxDecoration(),
          child: TextFormField(
            controller: _descriptionController,
            maxLines: 4,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(16),
            ),
            validator: (v) => v!.isEmpty ? "Ingresa una descripción" : null,
          ),
        ),
      ],
    );
  }

  Widget _buildLocation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Ubicación:",
            style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: _boxDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Av. Balta Nº 1024 - Chiclayo"),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _showMapDialog(),
                child: Row(
                  children: [
                    Icon(Icons.map, color: AppColors.primaryBlue, size: 18),
                    const SizedBox(width: 4),
                    const Text("Ajustar en mapa",
                        style: TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
              )
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPhotos() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Fotos (máx. 3):",
            style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        _selectedPhotos.isEmpty ? _emptyPhotos() : _photosGrid(),
      ],
    );
  }

  Widget _emptyPhotos() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: _boxDecoration(),
      child: Column(
        children: [
          Icon(Icons.photo_library, size: 40, color: Colors.grey[400]),
          const SizedBox(height: 12),
          const Text("No hay fotos agregadas"),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _addPhoto,
            icon: const Icon(Icons.add_photo_alternate),
            label: const Text("Agregar Fotos"),
          )
        ],
      ),
    );
  }

  Widget _photosGrid() {
    return Column(
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _selectedPhotos.length + (_selectedPhotos.length < 3 ? 1 : 0),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10),
          itemBuilder: (context, index) {
            if (index < _selectedPhotos.length) {
              return _photoTile(index);
            }
            return _addPhotoTile();
          },
        ),
      ],
    );
  }

  Widget _photoTile(int index) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey[300],
          ),
          child: const Center(
            child: Icon(Icons.photo, size: 30, color: Colors.white),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => _removePhoto(index),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(4),
              child: const Icon(Icons.close, size: 14, color: Colors.white),
            ),
          ),
        )
      ],
    );
  }

  Widget _addPhotoTile() {
    return GestureDetector(
      onTap: _addPhoto,
      child: Container(
        decoration: _boxDecoration(),
        child: const Center(
          child: Icon(Icons.add_photo_alternate),
        ),
      ),
    );
  }

  Widget _buildPriority() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Prioridad:", style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          children: _priorityLevels.map((p) {
            final bool selected = _selectedPriority == p;

            Color color;
            if (p == "Alta") color = AppColors.criticalRed;
            else if (p == "Media") color = AppColors.warningYellow;
            else color = AppColors.actionGreen;

            return ChoiceChip(
              label: Text(p),
              selected: selected,
              onSelected: (_) =>
                  setState(() => _selectedPriority = p),
              selectedColor: color.withOpacity(0.15),
            );
          }).toList(),
        )
      ],
    );
  }

  Widget _buildButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _saveReport,
            child: const Text("Guardar Cambios"),
          ),
        ),
      ],
    );
  }

  // ---------------- FUNCIONES ----------------

  void _addPhoto() {
    if (_selectedPhotos.length < 3) {
      setState(() {
        _selectedPhotos.add("Foto${_selectedPhotos.length + 1}.jpg");
      });
    }
  }

  void _removePhoto(int index) {
    setState(() => _selectedPhotos.removeAt(index));
  }

  void _saveReport() {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Reporte guardado correctamente")),
      );
      Navigator.pop(context);
    }
  }

  void _showMapDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Ajustar Ubicación"),
        content: const Text("Función de mapa en desarrollo..."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cerrar"),
          )
        ],
      ),
    );
  }

  // Caja decorativa reutilizable
  BoxDecoration _boxDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.grey.shade300),
    );
  }
}
