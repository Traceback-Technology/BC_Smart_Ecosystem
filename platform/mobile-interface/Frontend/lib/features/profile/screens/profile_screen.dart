import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../shared/widgets/campus_logo.dart';
import '../../auth/models/app_session.dart';
import '../../bc_ways/constants/colors.dart';
import '../../bc_ways/widgets/bc_bottom_navigation_bar.dart';
import '../services/profile_local_store.dart';
import '../../bc_eats/widgets/notification_bell.dart';

class ProfileScreen extends StatefulWidget {
  final AppSession session;
  final VoidCallback onLogout;
  final ValueChanged<int>? onNavigate;

  const ProfileScreen({
    super.key,
    required this.session,
    required this.onLogout,
    this.onNavigate,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ImagePicker _imagePicker = ImagePicker();

  late final ProfileLocalStore _localStore;

  String? _phone;
  Uint8List? _profileImage;

  @override
  void initState() {
    super.initState();

    final accountKey = [
      widget.session.email ?? '',
      widget.session.fullName ?? '',
      widget.session.role.name,
    ].join('|');

    _localStore = ProfileLocalStore(accountKey);

    _loadProfileDetails();
  }

  Future<void> _loadProfileDetails() async {
    final phone = await _localStore.loadPhone();
    final photo = await _localStore.loadPhoto();

    if (!mounted) {
      return;
    }

    setState(() {
      _phone = phone;
      _profileImage = photo;
    });
  }

  Future<void> _pickProfilePhoto() async {
    try {
      final selected = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 78,
      );

      if (selected == null) {
        return;
      }

      final bytes = await selected.readAsBytes();

      await _localStore.savePhoto(bytes);

      if (!mounted) {
        return;
      }

      setState(() {
        _profileImage = bytes;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile picture updated.')));
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not select that image. Please try again.'),
        ),
      );
    }
  }

  Future<void> _editPhoneNumber() async {
    final formKey = GlobalKey<FormState>();
    var enteredPhone = _phone ?? '';

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            _phone == null ? 'Add Cellphone Number' : 'Update Cellphone Number',
          ),
          content: Form(
            key: formKey,
            child: TextFormField(
              initialValue: enteredPhone,
              autofocus: true,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s()\-]')),
              ],
              decoration: const InputDecoration(
                labelText: 'Cellphone number',
                hintText: '+27 82 123 4567',
                prefixIcon: Icon(Icons.phone_outlined),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                enteredPhone = value;
              },
              validator: (value) {
                final entered = value?.trim() ?? '';
                final digits = entered.replaceAll(RegExp(r'\D'), '');

                if (entered.isEmpty) {
                  return 'Please enter your cellphone number.';
                }

                if (digits.length < 7 || digits.length > 15) {
                  return 'Please enter a valid cellphone number.';
                }

                return null;
              },
              onFieldSubmitted: (value) {
                enteredPhone = value;

                if (formKey.currentState!.validate()) {
                  Navigator.of(dialogContext).pop(enteredPhone.trim());
                }
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.of(dialogContext).pop(enteredPhone.trim());
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (!mounted || result == null || result.isEmpty) {
      return;
    }

    await _localStore.savePhone(result);

    if (!mounted) {
      return;
    }

    setState(() {
      _phone = result;
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Cellphone number updated.')));
  }

  void _onBottomNavigationTap(int index) {
    if (index == 4) {
      return;
    }

    final onNavigate = widget.onNavigate;

    if (onNavigate != null) {
      onNavigate(index);
      return;
    }

    if (index == 0) {
      Navigator.of(context).maybePop();
      return;
    }

    const labels = ['Home', 'Map', 'Eats', 'Orders', 'Profile'];

    if (index >= 0 && index < labels.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${labels[index]} is not connected from this screen.'),
        ),
      );
    }
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Log Out'),
          content: const Text(
            'Are you sure you want to log out of BC Ways & Eats?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(dialogContext).colorScheme.error,
                foregroundColor: Theme.of(dialogContext).colorScheme.onError,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Log Out'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    final navigator = Navigator.of(context);

    widget.onLogout();

    navigator.popUntil((route) => route.isFirst);
  }

  void _showSupportItem(String title) {
    String message;

    switch (title) {
      case 'Help Centre':
        message = 'FAQs and campus help resources will be connected here.';
        break;

      case 'Contact Support':
        message = 'Support contact options will be connected here.';
        break;

      case 'Privacy Policy':
        message = 'The BC Ways & Eats privacy policy will be displayed here.';
        break;

      case 'Terms & Conditions':
        message =
            'The BC Ways & Eats terms and conditions will be displayed here.';
        break;

      case 'About BC Ways & Eats':
        message = 'BC Ways & Eats\nVersion 1.0.0\nBelgium Campus iTversity';
        break;

      default:
        message = title;
    }

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      bottomNavigationBar: BcBottomNavigationBar(
        selectedIndex: 4,
        onTap: _onBottomNavigationTap,
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const _ProfileTopBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Profile / Settings',
                          style: TextStyle(
                            color: context.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 14),

                        _buildProfileCard(context),

                        const SizedBox(height: 16),

                        _sectionTitle(context, 'Contact Details'),
                        const SizedBox(height: 8),

                        _buildContactCard(context),

                        const SizedBox(height: 16),

                        _sectionTitle(context, 'Support'),
                        const SizedBox(height: 8),

                        _buildSupportCard(context),

                        const SizedBox(height: 14),

                        _buildLogoutButton(context),

                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final avatarSize = constraints.maxWidth < 360 ? 66.0 : 76.0;

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: context.subtleBorder),
          ),
          child: Row(
            children: [
              _ProfileAvatar(
                size: avatarSize,
                image: _profileImage,
                onTap: _pickProfilePhoto,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.session.displayName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: context.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      widget.session.roleLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: context.textSecondary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      widget.session.displayEmail,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: context.textSecondary,
                        fontSize: 11.5,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContactCard(BuildContext context) {
    final hasPhone = _phone != null && _phone!.trim().isNotEmpty;

    return Material(
      color: context.cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: context.subtleBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _editPhoneNumber,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
          child: Row(
            children: [
              const Icon(Icons.phone_outlined, size: 27),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cellphone Number',
                      style: TextStyle(
                        color: context.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hasPhone ? _phone! : 'Add your cellphone number',
                      style: TextStyle(
                        color: context.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                hasPhone ? 'Edit' : 'Add',
                style: TextStyle(
                  color: context.readableAccent(BcColors.primary),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, color: context.textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSupportCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.subtleBorder),
      ),
      child: Column(
        children: [
          _SupportTile(
            icon: Icons.help_outline,
            title: 'Help Centre',
            subtitle: 'FAQs and help articles',
            onTap: () => _showSupportItem('Help Centre'),
          ),
          _supportDivider(context),
          _SupportTile(
            icon: Icons.support_agent_outlined,
            title: 'Contact Support',
            subtitle: 'Get help from our support team',
            onTap: () => _showSupportItem('Contact Support'),
          ),
          _supportDivider(context),
          _SupportTile(
            icon: Icons.shield_outlined,
            title: 'Privacy Policy',
            subtitle: 'Read our privacy policy',
            onTap: () => _showSupportItem('Privacy Policy'),
          ),
          _supportDivider(context),
          _SupportTile(
            icon: Icons.description_outlined,
            title: 'Terms & Conditions',
            subtitle: 'Read our terms and conditions',
            onTap: () => _showSupportItem('Terms & Conditions'),
          ),
          _supportDivider(context),
          _SupportTile(
            icon: Icons.info_outline,
            title: 'About BC Ways & Eats',
            subtitle: 'Version 1.0.0',
            onTap: () => _showSupportItem('About BC Ways & Eats'),
          ),
        ],
      ),
    );
  }

  Widget _supportDivider(BuildContext context) {
    return Divider(
      height: 1,
      indent: 18,
      endIndent: 18,
      color: context.subtleBorder,
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    final red = context.bcColors.error;

    return Material(
      color: context.cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(17),
        side: BorderSide(color: context.subtleBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _confirmLogout,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Row(
            children: [
              Icon(Icons.logout, color: red, size: 27),
              const SizedBox(width: 16),
              Text(
                'Log Out',
                style: TextStyle(
                  color: red,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: TextStyle(
        color: context.textPrimary,
        fontSize: 16.5,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  final double size;
  final Uint8List? image;
  final VoidCallback onTap;

  const _ProfileAvatar({
    required this.size,
    required this.image,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size + 8,
      height: size + 8,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            child: InkWell(
              onTap: onTap,
              customBorder: const CircleBorder(),
              child: Container(
                width: size,
                height: size,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: context.readableAccent(BcColors.primary),
                    width: 2,
                  ),
                ),
                child: ClipOval(
                  child: image == null
                      ? Container(
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.person,
                            size: size * .58,
                            color: context.textSecondary,
                          ),
                        )
                      : Image.memory(
                          image!,
                          width: size,
                          height: size,
                          fit: BoxFit.cover,
                          gaplessPlayback: true,
                        ),
                ),
              ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Material(
              color: context.cardBg,
              shape: const CircleBorder(),
              elevation: 2,
              child: InkWell(
                onTap: onTap,
                customBorder: const CircleBorder(),
                child: Padding(
                  padding: const EdgeInsets.all(7),
                  child: Icon(
                    Icons.camera_alt,
                    size: 19,
                    color: context.textPrimary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SupportTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SupportTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 27, color: context.textPrimary),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: context.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: context.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: context.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileTopBar extends StatelessWidget {
  const _ProfileTopBar();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 18, 6),
      child: Row(
        children: [
          IconButton(
            onPressed: () async {
              final popped = await Navigator.of(context).maybePop();

              if (!popped && context.mounted) {
                Navigator.of(context, rootNavigator: true).maybePop();
              }
            },
            icon: const Icon(Icons.arrow_back, size: 28),
          ),
          const CampusLogo(width: 30, height: 30),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 20,
                        height: 1,
                        fontWeight: FontWeight.w900,
                      ),
                      children: [
                        TextSpan(
                          text: 'BC WAYS ',
                          style: TextStyle(color: context.textPrimary),
                        ),
                        TextSpan(
                          text: '& ',
                          style: TextStyle(color: context.bcColors.error),
                        ),
                        TextSpan(
                          text: 'EATS',
                          style: TextStyle(
                            color: context.readableAccent(BcColors.primary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  'Belgium Campus iTversity',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1,
                    color: context.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const NotificationBell(),
        ],
      ),
    );
  }
}
