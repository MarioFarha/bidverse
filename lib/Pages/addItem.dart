import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddItem extends StatefulWidget {
  const AddItem({Key? key}) : super(key: key);

  @override
  AddItemState createState() => AddItemState();
}

class AddItemState extends State<AddItem> {
  final TextEditingController _itemNameController = TextEditingController();
  final TextEditingController _startingBidController = TextEditingController();
  DateTime _auctionEndDate = DateTime.now();
  final TextEditingController _descriptionController = TextEditingController();
  late String itemID;

  final ImagePicker picker = ImagePicker();
  XFile? _selectedImage;
  String? _imageUrl;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  Future<void> _selectImage() async {
    try {
      final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        final Reference storageReference = firebase_storage.FirebaseStorage.instance.ref().child('item_images/${DateTime.now().toIso8601String()}');
        final UploadTask uploadTask = storageReference.putFile(File(pickedFile.path));

        await uploadTask.whenComplete(() async {
          final String imageUrl = await storageReference.getDownloadURL();

          setState(() {
            _selectedImage = pickedFile;
            _imageUrl = imageUrl;
          });
        });
      }
    } catch (error) {
      print('Error picking image: $error');
    }
  }

  Future<void> _selectAuctionEndDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _auctionEndDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            primaryColor: Colors.black, // Set the text color of the selected date
            hintColor: Colors.black, // Set the color of the selected date's background
            colorScheme: const ColorScheme.dark(primary: Colors.white),
            buttonTheme: const ButtonThemeData(textTheme: ButtonTextTheme.primary),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
        builder: (BuildContext context, Widget? child) {
          return Theme(
            data: ThemeData.dark().copyWith(
              primaryColor: Colors.black, // Set the text color of the selected time
              hintColor: Colors.black, // Set the color of the selected time's background
              colorScheme: const ColorScheme.dark(primary: Colors.white),
              buttonTheme: const ButtonThemeData(textTheme: ButtonTextTheme.primary),
            ),
            child: child!,
          );
        },
      );

      if (pickedTime != null) {
        pickedDate = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        setState(() {
          _auctionEndDate = pickedDate!;
        });
      }
    }
  }

  Future<void> addItemToFirestore(String itemName, String startingBidPrice, String description) async {
    double? startingBid = double.tryParse(startingBidPrice);
    if (startingBid == null || startingBid <= 0) {
      // Show an error message or handle the invalid input
      return;
    }

    FirebaseFirestore firestore = FirebaseFirestore.instance;
    CollectionReference items = firestore.collection('items');

    try {
      DocumentReference addedItem = await items.add({
        'itemName': itemName,
        'startingBidPrice': startingBid,
        'auctionEndDate': _auctionEndDate,
        'description': description,
        'userID': FirebaseAuth.instance.currentUser?.uid,
        'imageUrl': _imageUrl,
      });

      print("Item added with ID: ${addedItem.id}");
      itemID=addedItem.id;
      Navigator.pop(context, itemID);

    } catch (error) {
      print("Error adding item: $error");
      // Handle the error as needed
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.arrow_back),
                        color: Colors.black,
                      ),
                      const Text(
                        'Add Item',
                        style: TextStyle(
                          fontSize: 18.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16.0),
                  const Text('Add Your Valuable Item Details!',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 30.0),
                  _buildTextField(_itemNameController, 'Item Name', 'Enter item name'),
                  const SizedBox(height: 16.0),
                  _buildTextField(_startingBidController, 'Starting Bid Price', 'Enter starting bid price'),
                  const SizedBox(height: 16.0),
                  _buildAuctionEndDatePicker(),
                  const SizedBox(height: 16.0),
                  _buildTextField(_descriptionController, 'Description', 'Enter item description', maxLines: 3),
                  const SizedBox(height: 16.0),
                  _buildSelectImageButton(),
                  const SizedBox(height: 16.0),
                  _buildImagePreview(),
                  const SizedBox(height: 16.0),
                  _buildSubmitButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: TextButton(
        onPressed: () {
          if (_formKey.currentState?.validate() ?? false) {
            // Validation passed, check if an image is selected
            if (_selectedImage == null) {
              // Show an error message or handle the case where no image is selected
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please select an image',
                    style:TextStyle(
                        color: Colors.red
                    ),
                  ),
                  backgroundColor: Colors.white,
                  behavior:  SnackBarBehavior.floating,
                ),
              );
            } else {
              // Image selected, submit the form
              addItemToFirestore(
                _itemNameController.text,
                _startingBidController.text,
                _descriptionController.text,
              );
              Navigator.pop(context);
            }
          }
        },
        child: const Text(
          'Add Item',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18.0,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, String hint, {int? maxLines}) {
    return TextFormField(
      controller: controller,
      keyboardType: controller == _startingBidController ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter $label';
        }
        return null;
      },
    );
  }

  Widget _buildSelectImageButton() {
    return ElevatedButton(
      onPressed: _selectImage,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black, // Set the background color to black
      ),
      child: Text(_selectedImage == null ? 'Select Image' : 'Image Selected'),
    );
  }

  Widget _buildImagePreview() {
    return _selectedImage != null
        ? Column(
      children: [
        const Text('Image Preview:'),
        const SizedBox(height: 8.0),
        Image.file(File(_selectedImage!.path), height: 150.0),
      ],
    )
        : Container();
  }

  Widget _buildAuctionEndDatePicker() {
    return InkWell(
      onTap: _selectAuctionEndDate,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Auction End Date',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              ' ${_formattedDate(_auctionEndDate)}',
              style: const TextStyle(
                fontSize: 16.0,
                color: Colors.black,
              ),
            ),
            const Icon(Icons.calendar_today),
          ],
        ),
      ),
    );
  }

  String _formattedDate(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}