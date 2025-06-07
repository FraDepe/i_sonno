import 'package:flutter/material.dart';

class MultiSelect extends StatefulWidget {
  final List<String> items;
  final List<String> initiallySelected;
  const MultiSelect({super.key, required this.items, required this.initiallySelected});

  @override
  State<StatefulWidget> createState() => _MultiSelectState();
}

class _MultiSelectState extends State<MultiSelect> {

  late List<String> _selectedItems = [];

    @override
    void initState() {
      super.initState();
      _selectedItems = List<String>.from(widget.initiallySelected);
    }

  void _itemChange(String itemValue, bool isSelected) {
    setState(() {
      if (isSelected) {
        _selectedItems.add(itemValue);
      } else {
        _selectedItems.remove(itemValue);
      }
    });
  }

  void _cancel() {
    Navigator.pop(context);
  }

  void _submit() {
    Navigator.pop(context, _selectedItems); // fixme Qui si può fare il sort dei giorni
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Scegli i giorni'),
      content: SingleChildScrollView(
        child: ListBody(
          children: widget.items
              .map((item) => CheckboxListTile(
                    value: _selectedItems.contains(item),
                    title: Text(item),
                    controlAffinity: ListTileControlAffinity.leading,
                    onChanged: (isChecked) => _itemChange(item, isChecked!),
                  ))
              .toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _cancel,
          child: const Text('Annulla'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Fatto'),
        ),
      ],
    );
  }
}