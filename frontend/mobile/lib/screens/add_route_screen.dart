import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../config/app_config.dart';
import '../providers/route_provider.dart';

class AddRouteScreen extends StatefulWidget {
  const AddRouteScreen({super.key});

  @override
  State<AddRouteScreen> createState() => _AddRouteScreenState();
}

class _AddRouteScreenState extends State<AddRouteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _stopIdController = TextEditingController();
  final _stopNameController = TextEditingController();
  final _routeNumberController = TextEditingController();
  final _routeNameController = TextEditingController();

  final Set<int> _selectedDays = {};
  TimeOfDay _startTime = const TimeOfDay(hour: 7, minute: 30);
  TimeOfDay _endTime = const TimeOfDay(hour: 8, minute: 0);
  int _alertMinutes = AppConfig.defaultAlertMinutes;

  @override
  void dispose() {
    _stopIdController.dispose();
    _stopNameController.dispose();
    _routeNumberController.dispose();
    _routeNameController.dispose();
    super.dispose();
  }

  Future<void> _selectTime(bool isStart) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('בחר לפחות יום אחד'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    final routeProvider = Provider.of<RouteProvider>(context, listen: false);

    final routeData = {
      'stop_id': _stopIdController.text.trim(),
      'stop_name': _stopNameController.text.trim(),
      'route_number': _routeNumberController.text.trim(),
      'route_name': _routeNameController.text.trim(),
      'days_of_week': _selectedDays.toList(),
      'time_window_start': _formatTime(_startTime),
      'time_window_end': _formatTime(_endTime),
      'alert_minutes_before': _alertMinutes,
    };

    final success = await routeProvider.createRoute(routeData);

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('המסלול נוסף בהצלחה'),
          backgroundColor: AppTheme.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(routeProvider.error ?? 'שגיאה בהוספת מסלול'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('הוסף מסלול חדש'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Stop ID
            TextFormField(
              controller: _stopIdController,
              decoration: const InputDecoration(
                labelText: 'מספר תחנה',
                hintText: '3045',
                prefixIcon: Icon(Icons.pin_drop),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'נא להזין מספר תחנה';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            // Stop Name
            TextFormField(
              controller: _stopNameController,
              decoration: const InputDecoration(
                labelText: 'שם התחנה (אופציונלי)',
                hintText: 'רחוב הרצל 45',
                prefixIcon: Icon(Icons.location_on),
              ),
            ),
            const SizedBox(height: 16),
            // Route Number
            TextFormField(
              controller: _routeNumberController,
              decoration: const InputDecoration(
                labelText: 'מספר קו',
                hintText: '18',
                prefixIcon: Icon(Icons.directions_bus),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'נא להזין מספר קו';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            // Route Name
            TextFormField(
              controller: _routeNameController,
              decoration: const InputDecoration(
                labelText: 'שם הקו (אופציונלי)',
                hintText: 'תל אביב - בת ים',
                prefixIcon: Icon(Icons.route),
              ),
            ),
            const SizedBox(height: 24),
            // Days of Week
            const Text('ימים', style: AppTheme.headline3),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AppConfig.daysOfWeek.entries.map((entry) {
                final day = entry.key;
                final dayName = entry.value;
                final isSelected = _selectedDays.contains(day);
                return ChoiceChip(
                  label: Text(dayName),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedDays.add(day);
                      } else {
                        _selectedDays.remove(day);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            // Time Window
            const Text('חלון זמן', style: AppTheme.headline3),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    title: const Text('שעת התחלה'),
                    subtitle: Text(_formatTime(_startTime)),
                    trailing: const Icon(Icons.access_time),
                    onTap: () => _selectTime(true),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: AppTheme.divider),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ListTile(
                    title: const Text('שעת סיום'),
                    subtitle: Text(_formatTime(_endTime)),
                    trailing: const Icon(Icons.access_time),
                    onTap: () => _selectTime(false),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: AppTheme.divider),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Alert Minutes
            const Text('התרע לפני', style: AppTheme.headline3),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              value: _alertMinutes,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.notifications),
              ),
              items: AppConfig.alertMinutesOptions.map((minutes) {
                return DropdownMenuItem(
                  value: minutes,
                  child: Text('$minutes דקות'),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _alertMinutes = value!;
                });
              },
            ),
            const SizedBox(height: 40),
            // Submit Button
            ElevatedButton(
              onPressed: _handleSubmit,
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'הוסף מסלול',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
