import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../domain/address_model.dart';
import 'address_provider.dart';

class AddEditShopAddressPage extends StatefulWidget {
  const AddEditShopAddressPage({
    super.key,
    this.shopAddress,
  });

  final ShopAddress? shopAddress;

  static const routeName = '/add-edit-shop-address';

  @override
  State<AddEditShopAddressPage> createState() => _AddEditShopAddressPageState();
}

class _AddEditShopAddressPageState extends State<AddEditShopAddressPage> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  // Form controllers
  late final TextEditingController _contactPersonController;
  late final TextEditingController _phoneController;
  late final TextEditingController _alternatePhoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _streetController;
  late final TextEditingController _landmarkController;
  late final TextEditingController _cityController;
  late final TextEditingController _stateController;
  late final TextEditingController _pincodeController;
  late final TextEditingController _instructionsController;

  // Form state
  String _selectedCountry = 'India';
  TimeOfDay _openingTime = const TimeOfDay(hour: 10, minute: 0);
  TimeOfDay _closingTime = const TimeOfDay(hour: 20, minute: 0);
  List<String> _selectedWorkingDays = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'
  ];

  // Location state
  double? _latitude;
  double? _longitude;
  bool _isLocating = false;

  // Validation state
  Map<String, String?> _validationSuggestions = {};

  bool get isEditing => widget.shopAddress != null;
  
  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _populateExistingData();
  }

  void _initializeControllers() {
    _contactPersonController = TextEditingController();
    _phoneController = TextEditingController();
    _alternatePhoneController = TextEditingController();
    _emailController = TextEditingController();
    _streetController = TextEditingController();
    _landmarkController = TextEditingController();
    _cityController = TextEditingController();
    _stateController = TextEditingController();
    _pincodeController = TextEditingController();
    _instructionsController = TextEditingController();
  }

  void _populateExistingData() {
    if (isEditing) {
      final shop = widget.shopAddress!;
      _contactPersonController.text = shop.contactPerson;
      _phoneController.text = shop.phone;
      _alternatePhoneController.text = shop.alternatePhone;
      _emailController.text = shop.email;
      _streetController.text = shop.street;
      _landmarkController.text = shop.landmark;
      _cityController.text = shop.city;
      _stateController.text = shop.state;
      _selectedCountry = shop.country;
      _pincodeController.text = shop.pincode;
      _instructionsController.text = shop.instructions ?? '';
      
      _latitude = shop.latitude;
      _longitude = shop.longitude;
      
      // Parse time
      _openingTime = _parseTimeString(shop.openingHours);
      _closingTime = _parseTimeString(shop.closingHours);
      _selectedWorkingDays = List.from(shop.workingDays);
    }
  }

  @override
  void dispose() {
    _contactPersonController.dispose();
    _phoneController.dispose();
    _alternatePhoneController.dispose();
    _emailController.dispose();
    _streetController.dispose();
    _landmarkController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _instructionsController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Shop Address' : 'Add Shop Address'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _getCurrentLocation,
            tooltip: 'Get Current Location',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Instructions card
              Card(
                color: Colors.blue.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.info_outline, color: Colors.blue),
                          const SizedBox(width: 12),
                          Text(
                            'Setup Your Pickup Location',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Customers will use this information to find and pickup their orders from your shop.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Contact Information Section
              _buildSectionHeader('Contact Information'),
              _buildContactPersonField(),
              const SizedBox(height: 16),
              _buildPhoneField(),
              const SizedBox(height: 16),
              _buildAlternatePhoneField(),
              const SizedBox(height: 16),
              _buildEmailField(),

              const SizedBox(height: 32),

              // Address Information Section
              _buildSectionHeader('Address Information'),
              _buildStreetField(),
              const SizedBox(height: 16),
              _buildLandmarkField(),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildCityField()),
                  const SizedBox(width: 16),
                  Expanded(child: _buildPincodeField()),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildStateField()),
                  const SizedBox(width: 16),
                  Expanded(child: _buildCountryField()),
                ],
              ),

              const SizedBox(height: 16),

              // Location picker
              _buildLocationSection(),

              const SizedBox(height: 32),

              // Business Hours Section
              _buildSectionHeader('Business Hours'),
              _buildBusinessHoursSection(),

              const SizedBox(height: 16),

              // Working Days Section
              _buildWorkingDaysSection(),

              const SizedBox(height: 32),

              // Special Instructions Section
              _buildSectionHeader('Pickup Instructions (Optional)'),
              _buildInstructionsField(),

              const SizedBox(height: 40),

              // Save Button
              _buildSaveButton(),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  Widget _buildContactPersonField() {
    return TextFormField(
      controller: _contactPersonController,
      textInputAction: TextInputAction.next,
      textCapitalization: TextCapitalization.words,
      validator: (value) => Validators.name(value, fieldName: 'Contact Person'),
      decoration: const InputDecoration(
        labelText: 'Contact Person',
        hintText: 'Enter contact person name',
        prefixIcon: Icon(Icons.person),
      ),
    );
  }

  Widget _buildPhoneField() {
    return TextFormField(
      controller: _phoneController,
      keyboardType: TextInputType.phone,
      textInputAction: TextInputAction.next,
      validator: Validators.phone,
      decoration: const InputDecoration(
        labelText: 'Primary Phone',
        hintText: 'Enter primary phone number',
        prefixIcon: Icon(Icons.phone),
      ),
    );
  }

  Widget _buildAlternatePhoneField() {
    return TextFormField(
      controller: _alternatePhoneController,
      keyboardType: TextInputType.phone,
      textInputAction: TextInputAction.next,
      validator: (value) {
        if (value != null && value.isNotEmpty) {
          return Validators.phone(value);
        }
        return null;
      },
      decoration: const InputDecoration(
        labelText: 'Alternate Phone (Optional)',
        hintText: 'Enter alternate phone number',
        prefixIcon: Icon(Icons.phone_android),
      ),
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      validator: Validators.email,
      decoration: const InputDecoration(
        labelText: 'Email Address',
        hintText: 'Enter email address',
        prefixIcon: Icon(Icons.email),
      ),
    );
  }

  Widget _buildStreetField() {
    return TextFormField(
      controller: _streetController,
      textInputAction: TextInputAction.next,
      textCapitalization: TextCapitalization.words,
      validator: (value) => Validators.required(value, fieldName: 'Street Address'),
      maxLines: 2,
      decoration: const InputDecoration(
        labelText: 'Street Address',
        hintText: 'Enter complete street address',
        prefixIcon: Icon(Icons.location_on),
      ),
    );
  }

  Widget _buildLandmarkField() {
    return TextFormField(
      controller: _landmarkController,
      textInputAction: TextInputAction.next,
      textCapitalization: TextCapitalization.words,
      validator: (value) => Validators.required(value, fieldName: 'Landmark'),
      decoration: const InputDecoration(
        labelText: 'Landmark',
        hintText: 'Enter nearby landmark',
        prefixIcon: Icon(Icons.landscape),
      ),
    );
  }

  Widget _buildCityField() {
    return TextFormField(
      controller: _cityController,
      textInputAction: TextInputAction.next,
      textCapitalization: TextCapitalization.words,
      validator: (value) => Validators.required(value, fieldName: 'City'),
      decoration: InputDecoration(
        labelText: 'City',
        hintText: 'Enter city name',
        prefixIcon: const Icon(Icons.location_city),
        suffixText: _validationSuggestions['city'] != null ? 'Suggested' : null,
        helperText: _validationSuggestions['city'],
      ),
      onChanged: _onCityChanged,
    );
  }

  Widget _buildStateField() {
    return TextFormField(
      controller: _stateController,
      textInputAction: TextInputAction.next,
      textCapitalization: TextCapitalization.words,
      validator: (value) => Validators.required(value, fieldName: 'State'),
      decoration: InputDecoration(
        labelText: 'State',
        hintText: 'Enter state name',
        prefixIcon: const Icon(Icons.map),
        suffixText: _validationSuggestions['state'] != null ? 'Suggested' : null,
        helperText: _validationSuggestions['state'],
      ),
      onChanged: _onStateChanged,
    );
  }

  Widget _buildPincodeField() {
    return TextFormField(
      controller: _pincodeController,
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.next,
      validator: Validators.pincode,
      decoration: const InputDecoration(
        labelText: 'Pincode',
        hintText: 'Enter 6-digit pincode',
        prefixIcon: Icon(Icons.markunread_mailbox),
      ),
      onChanged: _onPincodeChanged,
    );
  }

  Widget _buildCountryField() {
    return DropdownButtonFormField<String>(
      value: _selectedCountry,
      decoration: const InputDecoration(
        labelText: 'Country',
        prefixIcon: Icon(Icons.public),
      ),
      items: ['India', 'USA', 'UK', 'Canada', 'Australia']
          .map((country) => DropdownMenuItem(
                value: country,
                child: Text(country),
              ))
          .toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _selectedCountry = value;
          });
        }
      },
      validator: (value) => value == null ? 'Please select a country' : null,
    );
  }

  Widget _buildLocationSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.my_location, color: Colors.green),
                const SizedBox(width: 12),
                Text(
                  'Location Coordinates',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (_isLocating)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  TextButton.icon(
                    onPressed: _getCurrentLocation,
                    icon: const Icon(Icons.gps_fixed, size: 16),
                    label: const Text('Get Location'),
                  ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            if (_latitude != null && _longitude != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Location Set',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Lat: ${_latitude!.toStringAsFixed(6)}, Lng: ${_longitude!.toStringAsFixed(6)}',
                            style: const TextStyle(
                              color: Colors.green,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Location coordinates help customers find your shop easily',
                        style: TextStyle(color: Colors.orange),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessHoursSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Opening Time',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () => _selectTime(true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.access_time, size: 20),
                              const SizedBox(width: 12),
                              Text(
                                _openingTime.format(context),
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Closing Time',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () => _selectTime(false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.access_time_filled, size: 20),
                              const SizedBox(width: 12),
                              Text(
                                _closingTime.format(context),
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkingDaysSection() {
    const weekdays = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Working Days',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: weekdays.map((day) {
                final isSelected = _selectedWorkingDays.contains(day);
                return FilterChip(
                  label: Text(day.substring(0, 3)),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedWorkingDays.add(day);
                      } else {
                        _selectedWorkingDays.remove(day);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedWorkingDays = List.from(weekdays);
                    });
                  },
                  child: const Text('Select All'),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedWorkingDays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
                    });
                  },
                  child: const Text('Mon-Sat'),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedWorkingDays.clear();
                    });
                  },
                  child: const Text('Clear All'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionsField() {
    return TextFormField(
      controller: _instructionsController,
      textInputAction: TextInputAction.done,
      textCapitalization: TextCapitalization.sentences,
      maxLines: 3,
      decoration: const InputDecoration(
        labelText: 'Special Instructions',
        hintText: 'Any special instructions for customers during pickup (e.g., parking, entrance, timing)',
        prefixIcon: Icon(Icons.info_outline),
      ),
    );
  }

  Widget _buildSaveButton() {
    return Consumer<AddressProvider>(
      builder: (context, provider, child) {
        return SizedBox(
          width: double.infinity,
          child: CustomButton(
            onPressed: provider.isUpdating ? null : _saveAddress,
            child: provider.isUpdating
                ? const LoadingIndicator(size: 20)
                : Text(isEditing ? 'Update Address' : 'Save Address'),
          ),
        );
      },
    );
  }

  // Event handlers
  Future<void> _selectTime(bool isOpeningTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isOpeningTime ? _openingTime : _closingTime,
    );

    if (picked != null) {
      setState(() {
        if (isOpeningTime) {
          _openingTime = picked;
        } else {
          _closingTime = picked;
        }
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLocating = true;
    });

    try {
      final provider = context.read<AddressProvider>();
      final success = await provider.getCurrentLocation();
      
      if (success && provider.currentPosition != null) {
        setState(() {
          _latitude = provider.currentPosition!.latitude;
          _longitude = provider.currentPosition!.longitude;
        });

        // Try to get address from coordinates
        final locationData = await provider.getLocationFromCoordinates(
          _latitude!,
          _longitude!,
        );

        if (locationData != null) {
          _autoFillFromLocation(locationData);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location coordinates set successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage ?? 'Failed to get current location'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLocating = false;
      });
    }
  }

  void _autoFillFromLocation(Map<String, dynamic> locationData) {
    if (locationData['street'] != null && _streetController.text.isEmpty) {
      _streetController.text = locationData['street'];
    }
    if (locationData['city'] != null && _cityController.text.isEmpty) {
      _cityController.text = locationData['city'];
    }
    if (locationData['state'] != null && _stateController.text.isEmpty) {
      _stateController.text = locationData['state'];
    }
    if (locationData['pincode'] != null && _pincodeController.text.isEmpty) {
      _pincodeController.text = locationData['pincode'];
    }
  }

  void _onPincodeChanged(String value) async {
    if (value.length == 6) {
      final provider = context.read<AddressProvider>();
      final validation = await provider.validatePincode(value);
      
      if (validation != null && validation['isValid'] == true) {
        setState(() {
          _validationSuggestions = Map<String, String?>.from(validation['suggestions'] ?? {});
        });
        
        // Auto-fill city and state if available
        if (validation['suggestions']?['city'] != null && _cityController.text.isEmpty) {
          _cityController.text = validation['suggestions']['city'];
        }
        if (validation['suggestions']?['state'] != null && _stateController.text.isEmpty) {
          _stateController.text = validation['suggestions']['state'];
        }
      }
    }
  }

  void _onCityChanged(String value) {
    // Clear city suggestion when user types
    if (_validationSuggestions['city'] != null) {
      setState(() {
        _validationSuggestions['city'] = null;
      });
    }
  }

  void _onStateChanged(String value) {
    // Clear state suggestion when user types
    if (_validationSuggestions['state'] != null) {
      setState(() {
        _validationSuggestions['state'] = null;
      });
    }
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) {
      _scrollToFirstError();
      return;
    }

    if (_selectedWorkingDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one working day'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final provider = context.read<AddressProvider>();
    bool success;

    if (isEditing) {
      final request = UpdateShopAddressRequest(
        contactPerson: _contactPersonController.text.trim(),
        phone: _phoneController.text.trim(),
        alternatePhone: _alternatePhoneController.text.trim(),
        email: _emailController.text.trim(),
        street: _streetController.text.trim(),
        landmark: _landmarkController.text.trim(),
        city: _cityController.text.trim(),
        state: _stateController.text.trim(),
        country: _selectedCountry,
        pincode: _pincodeController.text.trim(),
        latitude: _latitude,
        longitude: _longitude,
        openingHours: _formatTimeOfDay(_openingTime),
        closingHours: _formatTimeOfDay(_closingTime),
        workingDays: _selectedWorkingDays,
        instructions: _instructionsController.text.trim().isEmpty 
            ? null 
            : _instructionsController.text.trim(),
      );
      success = await provider.updateMyShopAddress(request);
    } else {
      final request = CreateShopAddressRequest(
        contactPerson: _contactPersonController.text.trim(),
        phone: _phoneController.text.trim(),
        alternatePhone: _alternatePhoneController.text.trim(),
        email: _emailController.text.trim(),
        street: _streetController.text.trim(),
        landmark: _landmarkController.text.trim(),
        city: _cityController.text.trim(),
        state: _stateController.text.trim(),
        country: _selectedCountry,
        pincode: _pincodeController.text.trim(),
        latitude: _latitude ?? 0.0,
        longitude: _longitude ?? 0.0,
        openingHours: _formatTimeOfDay(_openingTime),
        closingHours: _formatTimeOfDay(_closingTime),
        workingDays: _selectedWorkingDays,
        instructions: _instructionsController.text.trim().isEmpty 
            ? null 
            : _instructionsController.text.trim(),
      );
      success = await provider.saveMyShopAddress(request);
    }

    if (success && mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEditing 
              ? 'Shop address updated successfully' 
              : 'Shop address saved successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Failed to save address'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _scrollToFirstError() {
    // Scroll to first field with error
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  // Helper methods
  TimeOfDay _parseTimeString(String timeString) {
    final parts = timeString.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

  String _formatTimeOfDay(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
