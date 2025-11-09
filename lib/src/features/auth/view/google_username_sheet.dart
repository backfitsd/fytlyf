// --- file: lib/src/features/auth/view/google_username_sheet.dart ---

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GoogleUsernameSheet extends StatefulWidget {
  const GoogleUsernameSheet({super.key});

  @override
  State<GoogleUsernameSheet> createState() => _GoogleUsernameSheetState();
}

class _GoogleUsernameSheetState extends State<GoogleUsernameSheet> {
  final _ctl = TextEditingController();
  Timer? _debounce;
  bool _checking = false;
  bool? _available;

  static final _reg =
  RegExp(r'^(?!.*\.\.)(?!\.)(?!.*\.$)[a-z0-9._]{3,30}$');

  @override
  void dispose() {
    _debounce?.cancel();
    _ctl.dispose();
    super.dispose();
  }

  Future<bool> _isFree(String u) async {
    final snap =
    await FirebaseFirestore.instance.collection('usernames').doc(u).get();
    return !snap.exists;
  }

  void _onChanged(String raw) {
    final v = raw.trim().toLowerCase();
    if (raw != v) {
      final sel = _ctl.selection;
      _ctl.value = TextEditingValue(text: v, selection: sel);
    }

    setState(() {
      _available = null;
      _checking = v.isNotEmpty;
    });

    _debounce?.cancel();

    if (v.isEmpty || !_reg.hasMatch(v)) {
      setState(() => _checking = false);
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 350), () async {
      try {
        final free = await _isFree(v);
        if (!mounted) return;
        setState(() {
          _available = free;
          _checking = false;
        });
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _available = null;
          _checking = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final rf = (MediaQuery.of(context).size.width / 420).clamp(.9, 1.2);

    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: .18),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "Choose a username",
            style: GoogleFonts.poppins(
              fontSize: 18 * rf,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "This will be your public handle.",
            style: GoogleFonts.roboto(
              fontSize: 14 * rf,
              color: Colors.black.withValues(alpha: .65),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _ctl,
            onChanged: _onChanged,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              hintText: "username",
              prefixIcon: const Icon(Icons.alternate_email_rounded),
              suffixIcon: _checking
                  ? const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
              )
                  : (_available == true
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : (_available == false
                  ? const Icon(Icons.cancel_rounded, color: Colors.red)
                  : null)),
              helperText: "3–30, lowercase a–z, 0–9, . _ (no leading/trailing dot)",
              filled: true,
              fillColor: const Color(0xFFF3F4F6),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              focusedBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(14)),
                borderSide: BorderSide(color: Color(0xFFFF3D00), width: 1.4),
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: (_available == true && _reg.hasMatch(_ctl.text.trim().toLowerCase()))
                  ? () => Navigator.of(context).pop(_ctl.text.trim().toLowerCase())
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF3D00),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Continue", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}
