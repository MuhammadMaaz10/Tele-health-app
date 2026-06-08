import 'package:flutter/material.dart';
import 'package:telehealth_app/core/theme/app_colors.dart';
import 'package:telehealth_app/features/profile/model/profile_model.dart';
import 'custom_text.dart';

class SearchableUserDropdown extends StatefulWidget {
  final String label;
  final String hintText;
  final List<User> users;
  final bool isLoading;
  final User? selectedUser;
  final Function(User?) onUserSelected;
  final bool enabled;
  final Widget? prefixIcon;

  const SearchableUserDropdown({
    super.key,
    required this.label,
    required this.hintText,
    required this.users,
    required this.isLoading,
    this.selectedUser,
    required this.onUserSelected,
    this.enabled = true,
    this.prefixIcon,
  });

  @override
  State<SearchableUserDropdown> createState() => _SearchableUserDropdownState();
}

class _SearchableUserDropdownState extends State<SearchableUserDropdown> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isExpanded = false;
  List<User> _filteredUsers = [];

  @override
  void initState() {
    super.initState();
    _filteredUsers = widget.users;
    if (widget.selectedUser != null) {
      _searchController.text = widget.selectedUser!.directoryListTitle;
    }
    _searchController.addListener(_filterUsers);
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(SearchableUserDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.users != widget.users) {
      _filterUsers();
    }
    if (oldWidget.selectedUser != widget.selectedUser) {
      if (widget.selectedUser != null) {
        _searchController.text = widget.selectedUser!.directoryListTitle;
      } else {
        _searchController.clear();
      }
    }
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus && widget.selectedUser == null) {
      _searchController.clear();
    }
  }

  void _filterUsers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredUsers = widget.users;
      } else {
        _filteredUsers = widget.users.where((user) {
          return user.email.toLowerCase().contains(query) ||
              (user.username != null && user.username!.toLowerCase().contains(query));
        }).toList();
      }
    });
  }

  void _toggleDropdown() {
    if (!widget.enabled) return;
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _focusNode.requestFocus();
      } else {
        _focusNode.unfocus();
      }
    });
  }

  void _selectUser(User user) {
    _searchController.text = user.directoryListTitle;
    widget.onUserSelected(user);
    setState(() {
      _isExpanded = false;
    });
    _focusNode.unfocus();
  }

  void _clearSelection() {
    _searchController.clear();
    widget.onUserSelected(null);
    setState(() {
      _isExpanded = false;
    });
    _focusNode.unfocus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            GestureDetector(
              onTap: _toggleDropdown,
              child: AbsorbPointer(
                absorbing: !_isExpanded,
                child: TextField(
                  controller: _searchController,
                  focusNode: _focusNode,
                  enabled: widget.enabled,
                  decoration: InputDecoration(
                    labelText: widget.label,
                    hintText: widget.hintText,
                    prefixIcon: widget.prefixIcon,
                    suffixIcon: widget.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: Padding(
                              padding: EdgeInsets.all(12.0),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (widget.selectedUser != null)
                                IconButton(
                                  icon: const Icon(Icons.clear, size: 20),
                                  onPressed: widget.enabled ? _clearSelection : null,
                                  color: AppColors.hintColor,
                                ),
                              Icon(
                                _isExpanded
                                    ? Icons.keyboard_arrow_up
                                    : Icons.keyboard_arrow_down,
                                color: AppColors.hintColor,
                              ),
                            ],
                          ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppColors.lightBorderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppColors.lightBorderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppColors.primary, width: 2),
                    ),
                    disabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: AppColors.lightBorderColor.withOpacity(0.5),
                      ),
                    ),
                  ),
                  style: TextStyle(
                    color: widget.enabled
                        ? AppColors.textColor
                        : AppColors.hintColor.withOpacity(0.5),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (_isExpanded && widget.enabled)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.lightBorderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            constraints: const BoxConstraints(maxHeight: 200),
            child: widget.isLoading
                ? const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  )
                : _filteredUsers.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: CustomText(
                          text: 'No users found',
                          color: AppColors.hintColor,
                          fontSize: 14,
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: _filteredUsers.length,
                        itemBuilder: (context, index) {
                          final user = _filteredUsers[index];
                          final isSelected = widget.selectedUser?.email == user.email;
                          return InkWell(
                            onTap: () => _selectUser(user),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary.withOpacity(0.1)
                                    : Colors.transparent,
                                border: Border(
                                  bottom: BorderSide(
                                    color: AppColors.lightBorderColor.withOpacity(0.5),
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        CustomText(
                                          text: user.directoryListTitle,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.textColor,
                                        ),
                                        if (user.email.isNotEmpty &&
                                            user.directoryListTitle != user.email)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 4),
                                            child: CustomText(
                                              text: user.email,
                                              fontSize: 12,
                                              color: AppColors.hintColor,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  if (isSelected)
                                    Icon(
                                      Icons.check_circle,
                                      color: AppColors.primary,
                                      size: 20,
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
      ],
    );
  }
}

