import 'package:flutter/material.dart';
import 'package:sign_pdf_redpdf/theme/app_theme.dart';

class EditSignatureScreen extends StatefulWidget {
  const EditSignatureScreen({super.key});

  @override
  State<EditSignatureScreen> createState() => _EditSignatureScreenState();
}

class _EditSignatureScreenState extends State<EditSignatureScreen> {
  double thickness = 3.5;
  Color selectedColor = Colors.black;
  int selectedTool = 2; // Thickness selected

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.lightColors;

    return Scaffold(
      backgroundColor: colors.bg,

      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close),
        ),
        title: const Text("Edit Signature"),
        actions: [
          TextButton(
            onPressed: () {},
            child: Text("Save", style: TextStyle(color: colors.primary)),
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SafeArea(
          child: Column(
            children: [
              // 🧾 Signature Preview
              _previewCard(colors),

              const SizedBox(height: 20),

              // 🔧 Editing Tools
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "EDITING TOOLS",
                  style: TextStyle(
                    color: colors.primary,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                childAspectRatio: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: [
                  _tool(colors, "Crop", Icons.crop, 0),
                  _tool(colors, "Rotate", Icons.rotate_right, 1),
                  _tool(colors, "Thickness", Icons.menu, 2),
                  _tool(colors, "Color", Icons.palette, 3),
                ],
              ),

              const SizedBox(height: 20),

              // 🎚 Thickness Card
              _thicknessCard(colors),

              const SizedBox(height: 20),

              // 🎨 Color Picker
              _colorCard(colors),

              const SizedBox(height: 24),

              // 🔵 Save Changes Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {},
                  child: const Text("Save Changes"),
                ),
              ),

              const SizedBox(height: 16),

              // 🗑 Delete (subtle)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.delete, color: colors.light),
                  const SizedBox(width: 6),
                  Text(
                    "Delete Signature",
                    style: TextStyle(color: colors.light),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🧾 Preview Card
  Widget _previewCard(AppColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          Container(
            height: 160,
            width: 160,
            color: Colors.black87,
            child: const Center(
              child: Text(
                "Jatt.",
                style: TextStyle(color: Colors.white, fontSize: 28),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton(
              onPressed: () {},
              child: const Text("Preview"),
            ),
          ),
        ],
      ),
    );
  }

  // 🔧 Tool Button
  Widget _tool(AppColors colors, String text, IconData icon, int index) {
    final isSelected = selectedTool == index;

    return GestureDetector(
      onTap: () => setState(() => selectedTool = index),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? colors.primary.withOpacity(0.1) : colors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? colors.primary : colors.border,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? colors.primary : colors.text),
            const SizedBox(width: 6),
            Text(
              text,
              style: TextStyle(
                color: isSelected ? colors.primary : colors.text,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🎚 Thickness Card
  Widget _thicknessCard(AppColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Stroke Thickness"),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: colors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  "${thickness.toStringAsFixed(1)} px",
                  style: TextStyle(color: colors.primary),
                ),
              ),
            ],
          ),

          Slider(
            value: thickness,
            min: 1,
            max: 8,
            activeColor: colors.primary,
            onChanged: (v) => setState(() => thickness = v),
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [Text("1px"), Text("8px")],
          ),
        ],
      ),
    );
  }

  // 🎨 Color Picker
  Widget _colorCard(AppColors colors) {
    final colorList = [
      Colors.black,
      colors.primary,
      Colors.blue,
      Colors.green,
      Colors.purple,
      Colors.grey,
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Signature Color"),
          const SizedBox(height: 10),

          Row(
            children: colorList.map((c) {
              final isSelected = selectedColor == c;

              return GestureDetector(
                onTap: () => setState(() => selectedColor = c),
                child: Container(
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: isSelected
                        ? Border.all(color: colors.primary, width: 2)
                        : null,
                  ),
                  child: CircleAvatar(backgroundColor: c, radius: 14),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
