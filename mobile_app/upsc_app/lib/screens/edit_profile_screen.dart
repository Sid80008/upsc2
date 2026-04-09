import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _auth = AuthService();
  bool _isLoading = true;
  bool _isSaving = false;

  final _nameCtrl = TextEditingController();
  final _targetYearCtrl = TextEditingController();
  
  // Hardcoded for now, could be fetched dynamically
  final List<String> _allSubjects = ['Polity', 'History', 'Geography', 'Economy', 'Ethics', 'Environment'];
  List<String> _weakSubjects = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final profile = await _auth.getProfile();
    if (profile != null && mounted) {
      _nameCtrl.text = profile['name'] ?? '';
      _targetYearCtrl.text = (profile['target_year'] ?? DateTime.now().year + 1).toString();
      
      if (profile['weak_subjects'] != null) {
        try {
          final List dynamicList = jsonDecode(profile['weak_subjects']);
          _weakSubjects = dynamicList.map((e) => e.toString()).toList();
        } catch (e) {
          _weakSubjects = [];
        }
      }
      setState(() => _isLoading = false);
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final year = int.tryParse(_targetYearCtrl.text);
    final success = await _auth.updateProfile(
      name: _nameCtrl.text,
      targetYear: year,
      weakSubjects: _weakSubjects,
    );
    
    setState(() => _isSaving = false);
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated successfully')));
      Navigator.pop(context, true);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update profile')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
       return Scaffold(
         backgroundColor: Theme.of(context).scaffoldBackgroundColor,
         body: Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary)),
       );
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final primary = colorScheme.primary;
    final surface = theme.cardColor;
    final onSurface = colorScheme.onSurface;
    final background = theme.scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text('Edit Profile', style: TextStyle(fontFamily: 'Lexend', fontWeight: FontWeight.w800, fontSize: 18)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Personal Info', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, fontFamily: 'Lexend', color: onSurface)),
            const SizedBox(height: 16),
            TextField(
              controller: _nameCtrl,
              style: TextStyle(color: onSurface),
              decoration: InputDecoration(
                labelText: 'Full Name',
                labelStyle: TextStyle(color: onSurface.withValues(alpha: 0.6)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: colorScheme.outlineVariant)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.3))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: primary, width: 2)),
                filled: true,
                fillColor: surface,
              ),
            ),
            const SizedBox(height: 32),
            Text('Exam Preferences', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, fontFamily: 'Lexend', color: onSurface)),
            const SizedBox(height: 16),
            TextField(
              controller: _targetYearCtrl,
              keyboardType: TextInputType.number,
              style: TextStyle(color: onSurface),
              decoration: InputDecoration(
                labelText: 'Target Year',
                labelStyle: TextStyle(color: onSurface.withValues(alpha: 0.6)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: colorScheme.outlineVariant)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.3))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: primary, width: 2)),
                filled: true,
                fillColor: surface,
              ),
            ),
            const SizedBox(height: 32),
            Text('Weak Subjects (Needs Focus)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, fontFamily: 'Lexend', color: onSurface)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _allSubjects.map((subject) {
                final isSelected = _weakSubjects.contains(subject);
                return FilterChip(
                  label: Text(subject, style: TextStyle(color: isSelected ? Colors.white : onSurface, fontWeight: FontWeight.w600)),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _weakSubjects.add(subject);
                      } else {
                        _weakSubjects.remove(subject);
                      }
                    });
                  },
                  selectedColor: primary,
                  checkmarkColor: Colors.white,
                  backgroundColor: surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: isSelected ? primary : colorScheme.outlineVariant.withValues(alpha: 0.3)),
                  ),
                );
              }).toList(),
            ),
            
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  shadowColor: primary.withValues(alpha: 0.3),
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Save Changes', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Lexend')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
